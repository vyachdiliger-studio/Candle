using CandleBackend.Data;
using CandleBackend.Services;
using CandleBackend.Storage;
using Microsoft.EntityFrameworkCore;

namespace CandleBackend.BackgroundJobs;

public sealed class ResourcePreviewBackfillWorker(
    IServiceScopeFactory scopes,
    ILogger<ResourcePreviewBackfillWorker> logger) : BackgroundService
{
    private const int BatchSize = 20;
    private static readonly TimeSpan Interval = TimeSpan.FromMinutes(1);

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(Interval);

        try
        {
            do
            {
                try
                {
                    await ProcessBatch(stoppingToken);
                }
                catch (Exception error) when (error is not OperationCanceledException)
                {
                    logger.LogError(error, "Could not backfill resource previews; will retry next batch");
                }
            } while (await timer.WaitForNextTickAsync(stoppingToken));
        }
        catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
        {
        }
    }

    private async Task ProcessBatch(CancellationToken cancellationToken)
    {
        using var scope = scopes.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var storage = scope.ServiceProvider.GetRequiredService<IMediaStorage>();
        var renderer = scope.ServiceProvider.GetRequiredService<CandlePreviewRenderer>();
        var ids = await db.MediaResources.AsNoTracking()
            .Where(resource => resource.ReadyAt != null && resource.PreviewKey == null)
            .OrderBy(resource => resource.CreatedAt)
            .Select(resource => resource.Id)
            .Take(BatchSize)
            .ToListAsync(cancellationToken);

        foreach (var id in ids)
        {
            try
            {
                await CreatePreview(db, storage, renderer, id, cancellationToken);
            }
            catch (Exception error) when (error is not OperationCanceledException)
            {
                logger.LogError(error, "Could not create preview for resource {ResourceId}", id);
            }
            finally
            {
                db.ChangeTracker.Clear();
            }
        }
    }

    private static async Task CreatePreview(
        AppDbContext db,
        IMediaStorage storage,
        CandlePreviewRenderer renderer,
        Guid id,
        CancellationToken cancellationToken)
    {
        await using var transaction = await db.Database.BeginTransactionAsync(cancellationToken);
        var resource = await db.MediaResources
            .FromSqlInterpolated($"SELECT * FROM \"MediaResources\" WHERE \"Id\" = {id} FOR UPDATE SKIP LOCKED")
            .SingleOrDefaultAsync(cancellationToken);

        if (resource?.ReadyAt == null || resource.PreviewKey != null) return;

        var background = await storage.Read(resource.StorageKey, cancellationToken);
        var preview = renderer.Render(background);
        var key = $"resources/{id}/preview.jpg";
        await storage.Write(key, preview, "image/jpeg", cancellationToken);
        resource.PreviewKey = key;
        await db.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);
    }
}
