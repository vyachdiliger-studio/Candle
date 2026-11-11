using CandleBackend.Data;
using CandleBackend.Storage;
using Microsoft.EntityFrameworkCore;

namespace CandleBackend.BackgroundJobs;

public sealed class ResourceCleanupWorker(IServiceScopeFactory scopes, ILogger<ResourceCleanupWorker> logger) : BackgroundService
{
    private static readonly TimeSpan Interval = TimeSpan.FromMinutes(10);
    private static readonly TimeSpan Retention = TimeSpan.FromHours(24);
    private const int BatchSize = 100;

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(Interval);

        try
        {
            while (await timer.WaitForNextTickAsync(stoppingToken))
            {
                try
                {
                    await Sweep(stoppingToken);
                }
                catch (Exception error) when (error is not OperationCanceledException)
                {
                    logger.LogError(error, "Resource cleanup failed; will retry next sweep");
                }
            }
        }
        catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
        {
        }
    }

    private async Task Sweep(CancellationToken cancellationToken)
    {
        using var scope = scopes.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var storage = scope.ServiceProvider.GetRequiredService<IMediaStorage>();
        var cutoff = DateTime.UtcNow - Retention;

        var candidates = await db.MediaResources
            .AsNoTracking()
            .Where(resource => (resource.ReadyAt ?? resource.CreatedAt) < cutoff)
            .Where(resource => !resource.UploadRemoved ||
                !db.Candles.Any(candle => candle.BackgroundResourceId == resource.Id))
            .OrderBy(resource => resource.CreatedAt)
            .Select(resource => resource.Id)
            .Take(BatchSize)
            .ToListAsync(cancellationToken);

        foreach (var id in candidates)
        {
            try
            {
                await RemoveExpiredFiles(db, storage, id, cutoff, cancellationToken);
            }
            catch (Exception error) when (error is not OperationCanceledException)
            {
                logger.LogError(error, "Failed to clean resource {ResourceId}", id);
            }
            finally
            {
                db.ChangeTracker.Clear();
            }
        }
    }

    private static async Task RemoveExpiredFiles(
        AppDbContext db,
        IMediaStorage storage,
        Guid id,
        DateTime cutoff,
        CancellationToken cancellationToken)
    {
        await using var transaction = await db.Database.BeginTransactionAsync(cancellationToken);

        var resource = await db.MediaResources
            .FromSqlInterpolated($"SELECT * FROM \"MediaResources\" WHERE \"Id\" = {id} FOR UPDATE SKIP LOCKED")
            .SingleOrDefaultAsync(cancellationToken);

        if (resource == null || (resource.ReadyAt ?? resource.CreatedAt) >= cutoff)
        {
            return;
        }

        var attached = await db.Candles.AnyAsync(
            candle => candle.BackgroundResourceId == id, cancellationToken);

        if (!resource.UploadRemoved)
        {
            await storage.Delete(resource.UploadKey, cancellationToken);
            resource.UploadRemoved = true;
        }

        if (!attached)
        {
            resource.ReadyAt = null;
        }

        await db.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);

        if (!attached)
        {
            await storage.Delete(resource.StorageKey, cancellationToken);
            await storage.Delete(resource.ThumbnailKey, cancellationToken);
            await storage.Delete(resource.PreviewKey ?? $"resources/{id}/preview.jpg", cancellationToken);
            db.MediaResources.Remove(resource);
            await db.SaveChangesAsync(cancellationToken);
        }
    }
}
