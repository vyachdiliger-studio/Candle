using System.Collections;
using System.Globalization;
using System.Resources;
using CandleBot.Localization;

namespace CandleBackend.Tests;

public class BotLocalizationTests
{
    private static readonly ResourceManager Resources =
        new("CandleBot.Localization.Messages", typeof(BotText).Assembly);

    private static HashSet<string> Keys(CultureInfo culture) =>
        Resources.GetResourceSet(culture, createIfNotExists: true, tryParents: false)!
            .Cast<DictionaryEntry>()
            .Where(entry => !string.IsNullOrWhiteSpace(entry.Value as string))
            .Select(entry => (string)entry.Key)
            .ToHashSet();

    [Theory]
    [InlineData("uk")]
    [InlineData("ru")]
    [InlineData("th")]
    public void Every_language_translates_every_text(string language)
    {
        var english = Keys(CultureInfo.InvariantCulture);
        Assert.Equal(english.Order(), Keys(CultureInfo.GetCultureInfo(language)).Order());
    }

    [Theory]
    [InlineData("en")]
    [InlineData("uk")]
    [InlineData("ru")]
    [InlineData("th")]
    public void Profile_texts_fit_telegram_limits(string language)
    {
        Assert.InRange(BotText.Get("ShortDescription", language).Length, 1, 120);
        Assert.InRange(BotText.Get("Description", language).Length, 1, 512);
    }

    [Theory]
    [InlineData(null, "uk", "uk")]
    [InlineData(null, "th", "th")]
    [InlineData(null, "ru-RU", "ru")]
    [InlineData(null, "de", "en")]
    [InlineData(null, null, "en")]
    [InlineData("th", "ru", "th")]
    [InlineData("xx", "uk", "uk")]
    public void Resolve_prefers_the_saved_choice_then_the_telegram_language(
        string? saved, string? telegram, string expected) =>
        Assert.Equal(expected, BotLanguage.Resolve(saved, telegram));
}
