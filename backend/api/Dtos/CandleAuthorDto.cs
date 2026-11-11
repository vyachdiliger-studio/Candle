namespace CandleBackend.Dtos;

/// <summary>
/// Who lit a candle. Deliberately narrower than <see cref="UserResponse"/>:
/// a candle is visible to everyone on the map, so it carries only what the
/// preview card shows and nothing else about the account.
/// </summary>
public record CandleAuthorDto(long Id, string Username);
