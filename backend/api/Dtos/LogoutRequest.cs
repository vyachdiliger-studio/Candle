using System.ComponentModel.DataAnnotations;

namespace CandleBackend.Dtos;

public class LogoutRequest
{
    [Required]
    public required string Refresh { get; init; }
}
