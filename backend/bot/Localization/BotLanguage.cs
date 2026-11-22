namespace CandleBot.Localization;

public static class BotLanguage
{
    /// <summary>Languages the bot speaks, in the order of the language keyboard.</summary>
    public static readonly IReadOnlyList<string> Supported = ["en", "uk", "ru", "th"];

    public static bool IsSupported(string? language) => language != null && Supported.Contains(language);

    /// <summary>The saved choice, else the Telegram app language, else English.</summary>
    public static string Resolve(string? selected, string? telegramLanguage)
    {
        if (IsSupported(selected)) return selected!;
        var fromTelegram = telegramLanguage?.Split('-')[0].ToLowerInvariant();
        return IsSupported(fromTelegram) ? fromTelegram! : "en";
    }

    /// <summary>The language's own name, as shown on the language keyboard.</summary>
    public static string Name(string language) => language switch
    {
        "uk" => "Українська",
        "ru" => "Русский",
        "th" => "ไทย",
        _ => "English"
    };
}
