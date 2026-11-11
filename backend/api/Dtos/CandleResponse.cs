namespace CandleBackend.Dtos;

public record CandleResponse(
    long Id,
    DateTime CreatedAt,
    DateTime IgnitedAt,
    DateTime ExtinguishedAt,
    string? Message,
    LocationDto? Location,
    string? Address,
    CandleAuthorDto? Author,
    ResourceResponse? Background,
    int SupportersCount,
    int CommentsCount = 0
);
