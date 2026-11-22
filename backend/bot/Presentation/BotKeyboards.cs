using CandleBot.Localization;
using Microsoft.AspNetCore.WebUtilities;
using Microsoft.Extensions.Options;
using Telegram.Bot.Types;
using Telegram.Bot.Types.ReplyMarkups;

namespace CandleBot.Presentation;

public sealed class BotKeyboards(IOptions<BotOptions> options)
{
    public WebAppInfo App(string language) => new()
    {
        Url = QueryHelpers.AddQueryString(options.Value.MiniAppUrl, "lang", language)
    };

    public InlineKeyboardMarkup Home(string language) => new(new[]
    {
        new[] { InlineKeyboardButton.WithWebApp(BotText.Get("Open", language), App(language)) },
        new[]
        {
            InlineKeyboardButton.WithCallbackData(BotText.Get("HelpButton", language), "help"),
            InlineKeyboardButton.WithCallbackData(BotText.Get("LanguageButton", language), "language")
        }
    });

    public InlineKeyboardMarkup Languages(string language)
    {
        var buttons = BotLanguage.Supported
            .Select(code => InlineKeyboardButton.WithCallbackData(
                (code == language ? "✓ " : "") + BotLanguage.Name(code), "language:" + code));
        var rows = buttons.Chunk(2).Select(row => row.AsEnumerable()).ToList();
        rows.Add([InlineKeyboardButton.WithCallbackData(BotText.Get("Back", language), "home")]);
        return new InlineKeyboardMarkup(rows);
    }

    public MenuButtonWebApp Menu(string language) => new()
    {
        Text = BotText.Get("Open", language),
        WebApp = App(language)
    };

    public static BotCommand[] Commands(string language) =>
    [
        new() { Command = "start", Description = BotText.Get("StartCommand", language) },
        new() { Command = "help", Description = BotText.Get("HelpCommand", language) },
        new() { Command = "language", Description = BotText.Get("LanguageCommand", language) },
        new() { Command = "settings", Description = BotText.Get("SettingsCommand", language) }
    ];
}
