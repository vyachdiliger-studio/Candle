using Microsoft.EntityFrameworkCore;

namespace CandleBackend.Models;

[PrimaryKey(nameof(UserId), nameof(BlockedUserId))]
public sealed class UserBlock
{
    public long UserId { get; set; }
    public User User { get; set; } = null!;
    public long BlockedUserId { get; set; }
    public User BlockedUser { get; set; } = null!;
    public DateTime CreatedAt { get; set; }
}
