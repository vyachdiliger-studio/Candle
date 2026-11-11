using Microsoft.EntityFrameworkCore;

namespace CandleBackend.Models;

[Index(nameof(CandleId), nameof(UserId), IsUnique = true)]
public sealed class CandleSupport
{
    public long Id { get; set; }
    public long CandleId { get; set; }
    public Candle Candle { get; set; } = null!;
    public long UserId { get; set; }
    public User User { get; set; } = null!;
    public DateTime CreatedAt { get; set; }
}
