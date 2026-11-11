using System.ComponentModel.DataAnnotations;

namespace CandleBackend.Dtos;

public sealed class SearchCandlesRequest
{
    public CandleFilter Filter { get; init; } = new();
    [Range(1, 100)] public int Limit { get; init; } = 30;
    [MaxLength(4096)] public string? Cursor { get; init; }
    public string Sort { get; init; } = "createdAtDesc";
}

public sealed class CandleFilter
{
    [Range(1, long.MaxValue)] public long? AuthorId { get; init; }
    public string? Status { get; init; }
    [MaxLength(100)] public long[]? Ids { get; init; }
}

public sealed record CandlePage(IReadOnlyList<CandleResponse> Items, string? NextCursor);
