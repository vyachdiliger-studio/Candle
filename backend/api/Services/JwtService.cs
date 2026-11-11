using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using Microsoft.IdentityModel.Tokens;

namespace CandleBackend.Services;

public class JwtService
{
    public static string CreateAccess(long userId, string key, string issuer, string audience, TimeSpan life)
    {
        var credentials = new SigningCredentials(
            new SymmetricSecurityKey(System.Text.Encoding.UTF8.GetBytes(key)),
            SecurityAlgorithms.HmacSha256
        );
        var claims = new[] { new Claim("id", userId.ToString()) };
        var jwt = new JwtSecurityToken(
            issuer,
            audience,
            claims,
            expires: DateTime.UtcNow.Add(life),
            signingCredentials: credentials
        );

        return new JwtSecurityTokenHandler().WriteToken(jwt);
    }

    public static string CreateRefresh()
    {
        return Convert.ToBase64String(RandomNumberGenerator.GetBytes(64));
    }
}
