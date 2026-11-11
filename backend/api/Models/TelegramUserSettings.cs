using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CandleBackend.Models;

public sealed class TelegramUserSettings
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.None)]
    public long TelegramUserId { get; set; }

    [MaxLength(2)]
    public required string PreferredLanguage { get; set; }
}
