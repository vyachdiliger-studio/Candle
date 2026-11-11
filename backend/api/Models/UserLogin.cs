using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace CandleBackend.Models;

[Index(nameof(UserId))]
[Index(nameof(UserId), nameof(Provider), IsUnique = true)]
[Index(nameof(Provider), nameof(ProviderId), IsUnique = true)]
public class UserLogin
{
    public long Id { get; set; }
    public long UserId { get; set; }
    public string? ProviderId { get; set; }

    [ConcurrencyCheck]
    public string? PasswordHash { get; set; }

    [Column(TypeName = "jsonb")]
    public required string ProviderData { get; set; } = "{}";
    public AuthProviderType Provider { get; set; }
    public User User { get; set; } = null!;
}
