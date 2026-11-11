using Microsoft.EntityFrameworkCore;

namespace CandleBackend.Models;

[Index(nameof(CreatedAt))]
public sealed class MediaResource
{
    public Guid Id { get; set; }
    public long OwnerId { get; set; }

    [DeleteBehavior(DeleteBehavior.Restrict)]
    public User Owner { get; set; } = null!;

    public DateTime CreatedAt { get; set; }
    public bool UploadRemoved { get; set; }
    public DateTime? ReadyAt { get; set; }

    public string? ContentType { get; set; }
    public long Size { get; set; }
    public int Width { get; set; }
    public int Height { get; set; }

    public string UploadKey { get; set; } = "";
    public string StorageKey { get; set; } = "";
    public string? PreviewKey { get; set; }
    public string ThumbnailKey { get; set; } = "";
}
