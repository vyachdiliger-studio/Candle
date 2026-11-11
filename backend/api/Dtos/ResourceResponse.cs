namespace CandleBackend.Dtos;

public sealed record ResourceResponse(
    Guid Id,
    string Url,
    string ThumbnailUrl,
    string ContentType,
    long Size,
    int Width,
    int Height
);

public sealed record ResourceUploadResponse(Guid Id, string UploadUrl, DateTime ExpiresAt);
