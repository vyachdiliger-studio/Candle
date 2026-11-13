using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using CandleBackend.Services;
using Microsoft.IdentityModel.Tokens;

namespace CandleBackend.Tests;

public class JwtServiceTests
{
    private const string Key = "test-signing-key-that-is-long-enough-for-hmac-sha256";
    private const string Issuer = "candle.api";
    private const string Audience = "candle.app";

    [Fact]
    public void CreateAccess_ValidatesWithSameKey_AndCarriesUserId()
    {
        var token = JwtService.CreateAccess(42, Key, Issuer, Audience, TimeSpan.FromMinutes(5));

        var principal = Validate(token, Key);

        Assert.Equal("42", principal.FindFirst("id")?.Value);
    }

    [Fact]
    public void CreateAccess_FailsWithAnotherKey()
    {
        var token = JwtService.CreateAccess(42, Key, Issuer, Audience, TimeSpan.FromMinutes(5));

        Assert.ThrowsAny<SecurityTokenException>(() => Validate(token, Key + "-other"));
    }

    [Fact]
    public void CreateAccess_ExpiresAfterLifetime()
    {
        var before = DateTime.UtcNow;
        var token = JwtService.CreateAccess(1, Key, Issuer, Audience, TimeSpan.FromMinutes(15));
        var after = DateTime.UtcNow;

        var expires = new JwtSecurityTokenHandler().ReadJwtToken(token).ValidTo;

        Assert.InRange(expires, before.AddMinutes(15).AddSeconds(-1), after.AddMinutes(15).AddSeconds(1));
    }

    [Fact]
    public void CreateRefresh_Returns64RandomBytes()
    {
        var first = JwtService.CreateRefresh();
        var second = JwtService.CreateRefresh();

        Assert.Equal(64, Convert.FromBase64String(first).Length);
        Assert.NotEqual(first, second);
    }

    private static ClaimsPrincipal Validate(string token, string key)
    {
        var parameters = new TokenValidationParameters
        {
            ValidIssuer = Issuer,
            ValidAudience = Audience,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(key)),
        };
        return new JwtSecurityTokenHandler().ValidateToken(token, parameters, out _);
    }
}
