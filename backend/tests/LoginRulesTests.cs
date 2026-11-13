using CandleBackend.Services;

namespace CandleBackend.Tests;

public class LoginRulesTests
{
    [Theory]
    [InlineData("a")]
    [InlineData("alice")]
    [InlineData("Alice.Smith_42")]
    public void ValidUsername_AcceptsTrimmedNames(string value)
    {
        Assert.True(LoginRules.ValidUsername(value));
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData(" alice")]
    [InlineData("alice ")]
    [InlineData("al\tice")]
    [InlineData("al\nice")]
    public void ValidUsername_RejectsEmptyPaddedOrControlCharacters(string? value)
    {
        Assert.False(LoginRules.ValidUsername(value));
    }

    [Fact]
    public void ValidUsername_LimitsLengthTo128()
    {
        Assert.True(LoginRules.ValidUsername(new string('a', 128)));
        Assert.False(LoginRules.ValidUsername(new string('a', 129)));
    }

    [Theory]
    [InlineData(null, false)]
    [InlineData("", false)]
    [InlineData("12345", false)]
    [InlineData("123456", true)]
    public void ValidPassword_RequiresAtLeastSixCharacters(string? value, bool expected)
    {
        Assert.Equal(expected, LoginRules.ValidPassword(value));
    }
}
