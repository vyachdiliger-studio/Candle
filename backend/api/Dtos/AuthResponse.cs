namespace CandleBackend.Dtos;

public class AuthResponse
{
    public required string Access { get; init; }
    public required string Refresh { get; init; }
    public long UserId { get; init; }
}
