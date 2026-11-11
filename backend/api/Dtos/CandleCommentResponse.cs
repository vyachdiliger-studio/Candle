namespace CandleBackend.Dtos;

/// <summary>
/// A comment as clients see it. A deleted comment that still has live replies is
/// returned as a placeholder: <see cref="IsDeleted"/> is true and author and text are null.
/// <see cref="RepliesCount"/> counts the live (not deleted) comments below this one,
/// at any depth.
/// </summary>
public sealed record CandleCommentResponse(
    long Id,
    long CandleId,
    long? ParentCommentId,
    long? RootCommentId,
    int Depth,
    CandleAuthorDto? Author,
    string? Text,
    bool IsDeleted,
    DateTime CreatedAt,
    int RepliesCount
);

public sealed record CandleCommentPage(IReadOnlyList<CandleCommentResponse> Items, string? NextCursor);
