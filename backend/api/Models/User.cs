using System.ComponentModel.DataAnnotations;
using Microsoft.EntityFrameworkCore;

namespace CandleBackend.Models;

[Index(nameof(Username), IsUnique = true)]
public class User
{
    public long Id { get; set; }
    public DateTime CreatedAt { get; set; }
    [Required]
    public string Username { get; set; } = null!;
    [MaxLength(2)]
    public string? PreferredLanguage { get; set; }

    public bool IsDeleted { get; set; }
    public IEnumerable<Candle> Candles { get; set; } = new List<Candle>();
    public IEnumerable<UserLogin> UserLogins { get; set; } = new List<UserLogin>();
}
