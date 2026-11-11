namespace CandleBot.Preferences;

public interface IBotPreferences
{
    Task<string?> GetLanguage(long telegramUserId, CancellationToken cancellationToken);
    Task SetLanguage(long telegramUserId, string language, CancellationToken cancellationToken);
}
