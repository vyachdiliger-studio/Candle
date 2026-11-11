using System.ComponentModel.DataAnnotations;
using Microsoft.EntityFrameworkCore;

namespace CandleBackend.Models;

[Index(nameof(ReviewedAt), nameof(CreatedAt))]
public sealed class ContentReport
{
    public long Id { get; set; }
    public long ReporterId { get; set; }
    public User Reporter { get; set; } = null!;
    public long ReportedUserId { get; set; }
    public User ReportedUser { get; set; } = null!;
    public long? CandleId { get; set; }
    public Candle? Candle { get; set; }
    public long? CommentId { get; set; }
    public CandleComment? Comment { get; set; }
    public ReportReason Reason { get; set; }
    [MaxLength(2000)]
    public string? Details { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? ReviewedAt { get; set; }
}
