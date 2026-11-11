namespace CandleBackend.Dtos;

/// <summary>
/// A comment as clients see it. Deleted comments are not returned (their branch is
/// deleted with them). A comment whose author deleted their account is returned as a
/// placeholder while live replies remain: <see cref="IsDeleted"/> is true and author
/// and text are null. <see cref="RepliesCount"/> counts the live comments below this
/// one, at any depth.
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
