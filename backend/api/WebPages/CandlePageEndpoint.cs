using CandleBackend.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace CandleBackend.WebPages;

public static class CandlePageEndpoint
{
    public static void MapCandlePages(this IEndpointRouteBuilder endpoints)
    {
        endpoints.MapMethods("/candles/{id:long}", ["GET", "HEAD"], GetPage).AllowAnonymous().ExcludeFromDescription();
    }

    private static async Task<IResult> GetPage(long id, AppDbContext db, WebAppPageRenderer renderer,
        IOptions<WebAppOptions> options, HttpContext context, ILogger<WebAppPageRenderer> logger,
        CancellationToken cancellationToken)
    {
        context.Response.Headers.CacheControl = "no-store";
        var candle = await db.Candles.AsNoTracking()
            .Where(c => c.Id == id && !c.User.IsDeleted)
            .Select(c => new
            {
                c.Message,
                c.User.Username,
                BackgroundId = c.BackgroundResource != null
                    && c.BackgroundResource.ReadyAt != null
                    && c.BackgroundResource.PreviewKey != null
                    ? (Guid?)c.BackgroundResource.Id : null
            })
            .SingleOrDefaultAsync(cancellationToken);

        var origin = new Uri(options.Value.PublicUrl, UriKind.Absolute);
        var metadata = candle is null
            ? new PageMetadata("Candle not found", "This candle is no longer available.",
                new Uri(origin, $"/candles/{id}").AbsoluteUri,
                new Uri(origin, "/api/previews/candles/v1/default.jpg").AbsoluteUri)
            : new PageMetadata($"A candle by @{candle.Username}",
                string.IsNullOrWhiteSpace(candle.Message)
                    ? "Take a moment for this candle. Open Candle to keep its light going."
                    : candle.Message,
                new Uri(origin, $"/candles/{id}").AbsoluteUri,
                new Uri(origin, candle.BackgroundId is { } resourceId
                    ? $"/api/resources/{resourceId}/candle-preview.jpg"
                    : "/api/previews/candles/v1/default.jpg").AbsoluteUri);

        try
        {
            var html = await renderer.Render(metadata, cancellationToken);
            if (candle is null) context.Response.Headers["X-Robots-Tag"] = "noindex";
            return Results.Content(html, "text/html; charset=utf-8",
                statusCode: candle is null ? StatusCodes.Status404NotFound : StatusCodes.Status200OK);
        }
        catch (Exception error) when (error is HttpRequestException or InvalidDataException)
        {
            logger.LogError(error, "Could not load the Flutter web entry point");
            return Results.Text("The application is temporarily unavailable.",
                statusCode: StatusCodes.Status503ServiceUnavailable);
        }
    }
}
