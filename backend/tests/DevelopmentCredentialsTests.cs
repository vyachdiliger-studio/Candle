using CandleBackend.Services;

namespace CandleBackend.Tests;

public class DevelopmentCredentialsTests
{
    [Theory]
    [InlineData("candle-local")]
    [InlineData("candle-local-secret")]
    [InlineData(" candle-local ")]
    public void IsExampleStorageKey_DetectsExampleValues(string value)
    {
        Assert.True(DevelopmentCredentials.IsExampleStorageKey(value));
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("k8Qz1v7Xr2mLp9")]
    [InlineData("candle-local-secret-2")]
    public void IsExampleStorageKey_AcceptsOtherValues(string? value)
    {
        Assert.False(DevelopmentCredentials.IsExampleStorageKey(value));
    }

    [Theory]
    [InlineData("Host=db;Port=5432;Database=candle;Username=candle;Password=candle-dev")]
    [InlineData("Host=db; password = candle-dev ;Database=candle")]
    public void HasExampleDatabasePassword_DetectsExamplePassword(string connectionString)
    {
        Assert.True(DevelopmentCredentials.HasExampleDatabasePassword(connectionString));
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("Host=db;Database=candle;Username=candle;Password=Zx81-real-password")]
    [InlineData("Host=db;Database=candle-dev;Username=candle;Password=other")]
    public void HasExampleDatabasePassword_AcceptsOtherPasswords(string? connectionString)
    {
        Assert.False(DevelopmentCredentials.HasExampleDatabasePassword(connectionString));
    }
}
