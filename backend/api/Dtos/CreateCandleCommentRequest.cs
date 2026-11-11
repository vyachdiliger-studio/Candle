namespace CandleBackend.Dtos;

public sealed record CreateCandleCommentRequest(string? Text, long? ParentCommentId = null);
