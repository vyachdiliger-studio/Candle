using CandleBackend.Services;

namespace CandleBackend.Tests;

public class CommentRulesTests
{
    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("   ")]
    [InlineData("\n\t")]
    public void CleanText_RejectsEmptyText(string? value)
    {
        Assert.Null(CommentRules.CleanText(value));
    }

    [Fact]
    public void CleanText_Trims()
    {
        Assert.Equal("Light and peace", CommentRules.CleanText("  Light and peace \n"));
    }

    [Fact]
    public void CleanText_LimitsTo1000Characters()
    {
        Assert.NotNull(CommentRules.CleanText(new string('a', 1000)));
        Assert.Null(CommentRules.CleanText(new string('a', 1001)));
    }

    [Fact]
    public void CleanText_CountsEmojiAsOneCharacterLikeTheApp()
    {
        // A family emoji is 11 UTF-16 code units but one user-perceived character.
        const string family = "\U0001F468\u200D\U0001F469\u200D\U0001F467\u200D\U0001F466";
        Assert.Equal(11, family.Length);
        Assert.NotNull(CommentRules.CleanText(string.Concat(Enumerable.Repeat("\U0001F56F\uFE0F", 1000))));
        Assert.NotNull(CommentRules.CleanText(string.Concat(Enumerable.Repeat(family, 300))));
        Assert.Null(CommentRules.CleanText(string.Concat(Enumerable.Repeat("\U0001F56F\uFE0F", 1001))));
    }

    [Fact]
    public void CleanText_CapsTheRawSize()
    {
        const string family = "\U0001F468\u200D\U0001F469\u200D\U0001F467\u200D\U0001F466";
        // 400 characters, but 4400 code units.
        Assert.Null(CommentRules.CleanText(string.Concat(Enumerable.Repeat(family, 400))));
    }
}
