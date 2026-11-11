using CandleBackend.Data;
using CandleBackend.Dtos;
using CandleBackend.Models;

namespace CandleBackend.Services;

public class SessionIssuer(AppDbContext db, IConfiguration cfg)
{
    public async Task<AuthResponse> Issue(long userId)
    {
        var refresh = JwtService.CreateRefresh();

        db.RefreshTokens.Add(new RefreshToken
        {
            UserId = userId,
            Token = refresh,
            CreatedAt = DateTime.UtcNow,
            ExpiresAt = DateTime.UtcNow.AddDays(30)
        });

        await db.SaveChangesAsync();

        return new AuthResponse
        {
            UserId = userId,
            Refresh = refresh,
            Access = JwtService.CreateAccess(
                userId,
                cfg["Jwt:Key"]!,
                cfg["Jwt:Issuer"]!,
                cfg["Jwt:Audience"]!,
                TimeSpan.FromMinutes(15)
            )
        };
    }
}
