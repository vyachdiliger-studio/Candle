namespace CandleBot.Localization;

public static class BotLanguage
{
    public static bool IsSupported(string? language) => language is "ru" or "en";

    public static string Resolve(string? selected, string? telegramLanguage)
    {
        if (IsSupported(selected)) return selected!;
        return telegramLanguage?.Split('-')[0].Equals("ru", StringComparison.OrdinalIgnoreCase) == true
            ? "ru"
            : "en";
    }
}
