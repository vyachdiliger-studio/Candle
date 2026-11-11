using Microsoft.EntityFrameworkCore;

namespace CandleBackend.Models;

[Index(nameof(Token), IsUnique = true)]
public class RefreshToken
{
    public long Id { get; set; }
    public long UserId { get; set; }
    public required string Token { get; set; }
    public DateTime ExpiresAt { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? RevokedAt { get; set; }
}
