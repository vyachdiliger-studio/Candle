using System.ComponentModel.DataAnnotations;

namespace CandleBackend.Dtos;

public class RefreshRequest
{
    [Required]
    public required string RefreshToken { get; init; }
}
