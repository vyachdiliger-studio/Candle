namespace CandleBackend.WebPages;

public sealed class WebAppOptions
{
    public string PublicUrl { get; set; } = "";

    // index.html of the Flutter web build; in Docker it is served by the `web` service.
    public string EntryPointUrl { get; set; } = "";
}
