using System.Globalization;
using CandleBackend.Models;

namespace CandleBackend.Services;

public static class CommentRules
{
    /// <summary>
    /// Trims <paramref name="value"/> and returns it when it fits the limits, null otherwise.
    /// The length counts user-perceived characters (grapheme clusters), as the app's
    /// counter does, so an emoji made of several code points counts once. The raw
    /// size is capped separately.
    /// </summary>
    public static string? CleanText(string? value)
    {
        var text = value?.Trim();
        if (string.IsNullOrEmpty(text) || text.Length > CandleComment.TextMaxStorageLength) return null;
        return new StringInfo(text).LengthInTextElements <= CandleComment.TextMaxLength ? text : null;
    }
}
