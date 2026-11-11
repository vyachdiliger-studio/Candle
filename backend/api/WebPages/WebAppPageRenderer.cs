using System.Text.Encodings.Web;
using CandleBackend.Services;
using Microsoft.Extensions.Options;

namespace CandleBackend.WebPages;

public sealed class WebAppPageRenderer(IOptions<WebAppOptions> options, IHttpClientFactory httpClientFactory)
{
    private const string StartMarker = "<!-- candle:metadata:start -->";
    private const string EndMarker = "<!-- candle:metadata:end -->";
    private static readonly TimeSpan TemplateLifetime = TimeSpan.FromMinutes(1);

    private (string Html, DateTimeOffset LoadedAt)? cachedTemplate;

    public async Task<string> Render(PageMetadata metadata, CancellationToken cancellationToken)
    {
        var template = await LoadTemplate(cancellationToken);
        var start = template.IndexOf(StartMarker, StringComparison.Ordinal);
        var end = template.IndexOf(EndMarker, StringComparison.Ordinal);
        if (start < 0 || end < start || template.Contains("$FLUTTER_BASE_HREF", StringComparison.Ordinal))
            throw new InvalidDataException("WebApp:EntryPointUrl must serve a current Flutter web build.");

        var encoder = HtmlEncoder.Default;
        var title = encoder.Encode(metadata.Title);
        var description = encoder.Encode(metadata.Description);
        var url = encoder.Encode(metadata.Url);
        var imageUrl = encoder.Encode(metadata.ImageUrl);
        var tags = $"""
            <title>{title}</title>
            <meta name="description" content="{description}">
            <link rel="canonical" href="{url}">
            <meta property="og:type" content="website">
            <meta property="og:site_name" content="Candle">
            <meta property="og:title" content="{title}">
            <meta property="og:description" content="{description}">
            <meta property="og:url" content="{url}">
            <meta property="og:image" content="{imageUrl}">
            <meta property="og:image:type" content="image/jpeg">
            <meta property="og:image:width" content="{CandlePreviewRenderer.Width}">
            <meta property="og:image:height" content="{CandlePreviewRenderer.Height}">
            <meta property="og:image:alt" content="A lit candle">
            <meta name="twitter:card" content="summary_large_image">
            <meta name="twitter:title" content="{title}">
            <meta name="twitter:description" content="{description}">
            <meta name="twitter:image" content="{imageUrl}">
            """;

        return string.Concat(template.AsSpan(0, start), tags, template.AsSpan(end + EndMarker.Length));
    }

    private async Task<string> LoadTemplate(CancellationToken cancellationToken)
    {
        if (cachedTemplate is { } cached && DateTimeOffset.UtcNow - cached.LoadedAt < TemplateLifetime)
            return cached.Html;

        using var client = httpClientFactory.CreateClient(nameof(WebAppPageRenderer));
        var html = await client.GetStringAsync(options.Value.EntryPointUrl, cancellationToken);
        cachedTemplate = (html, DateTimeOffset.UtcNow);
        return html;
    }
}
