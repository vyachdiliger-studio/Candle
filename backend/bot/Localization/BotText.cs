using System.Globalization;
using System.Resources;

namespace CandleBot.Localization;

public static class BotText
{
    private static readonly ResourceManager Resources = new("CandleBot.Localization.Messages", typeof(BotText).Assembly);

    public static string Get(string key, string language) =>
        Resources.GetString(key, CultureInfo.GetCultureInfo(language))
        ?? throw new InvalidOperationException($"Missing bot text: {key}");
}
