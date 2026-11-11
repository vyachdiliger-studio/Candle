using System.Globalization;
using CandleBackend.Data;
using CandleBackend.Models;
using CandleBot.Localization;
using CandleBot.Preferences;
using Microsoft.EntityFrameworkCore;
using Npgsql;

namespace CandleBackend.Services;

public sealed class BotPreferences(AppDbContext db) : IBotPreferences
{
    public async Task<string?> GetLanguage(long telegramUserId, CancellationToken cancellationToken)
    {
        var providerId = telegramUserId.ToString(CultureInfo.InvariantCulture);
        var accountLanguage = await db.UserLogins
            .Where(login => login.Provider == AuthProviderType.Telegram && login.ProviderId == providerId && !login.User.IsDeleted)
            .Select(login => login.User.PreferredLanguage)
            .SingleOrDefaultAsync(cancellationToken);

        return accountLanguage ?? await db.TelegramUserSettings
            .Where(settings => settings.TelegramUserId == telegramUserId)
            .Select(settings => settings.PreferredLanguage)
            .SingleOrDefaultAsync(cancellationToken);
    }

    public async Task SetLanguage(long telegramUserId, string language, CancellationToken cancellationToken)
    {
        if (!BotLanguage.IsSupported(language)) throw new ArgumentException("Unsupported language", nameof(language));

        for (var attempt = 0; attempt < 2; attempt++)
        {
            await using var transaction = await db.Database.BeginTransactionAsync(cancellationToken);
            try
            {
                var settings = await db.TelegramUserSettings.FindAsync([telegramUserId], cancellationToken);
                if (settings == null)
                {
                    db.TelegramUserSettings.Add(new TelegramUserSettings
                    {
                        TelegramUserId = telegramUserId,
                        PreferredLanguage = language
                    });
                }
                else
                {
                    settings.PreferredLanguage = language;
                }

                await db.SaveChangesAsync(cancellationToken);
                var providerId = telegramUserId.ToString(CultureInfo.InvariantCulture);
                await db.Users.Where(user => !user.IsDeleted && user.UserLogins.Any(login =>
                        login.Provider == AuthProviderType.Telegram && login.ProviderId == providerId))
                    .ExecuteUpdateAsync(setters => setters.SetProperty(user => user.PreferredLanguage, language), cancellationToken);
                await transaction.CommitAsync(cancellationToken);
                return;
            }
            catch (DbUpdateException error) when (attempt == 0 &&
                error.InnerException is PostgresException { SqlState: PostgresErrorCodes.UniqueViolation })
            {
                await transaction.RollbackAsync(cancellationToken);
                db.ChangeTracker.Clear();
            }
        }
    }

    public async Task ApplyToAccount(long telegramUserId, long userId, CancellationToken cancellationToken)
    {
        var language = await db.TelegramUserSettings
            .Where(settings => settings.TelegramUserId == telegramUserId)
            .Select(settings => settings.PreferredLanguage)
            .SingleOrDefaultAsync(cancellationToken);

        if (language == null) return;

        await db.Users.Where(user => user.Id == userId && user.PreferredLanguage == null)
            .ExecuteUpdateAsync(setters => setters.SetProperty(user => user.PreferredLanguage, language), cancellationToken);
    }
}
