namespace CandleBackend.Dtos;

public record UserResponse(
    long Id,
    DateTime CreatedAt,
    string Username,
    bool HasPassword,
    string? PreferredLanguage
);
