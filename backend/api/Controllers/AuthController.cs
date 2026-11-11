using System.Globalization;
using System.Text.Json;
using CandleBackend.Data;
using CandleBackend.Dtos;
using CandleBackend.Extensions;
using CandleBackend.Models;
using CandleBackend.Services;
using Google.Apis.Auth;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

namespace CandleBackend.Controllers;

[ApiController]
[Route("auth")]
public class AuthController(AppDbContext db, IConfiguration cfg, SessionIssuer sessions, ILogger<AuthController> logger, BotPreferences botPreferences) : ControllerBase
{
    public record GoogleAuthRequest(string IdToken);
    public record TelegramAuthRequest(string? InitData = null, string? IdToken = null);

    [AllowAnonymous]
    [HttpPost("telegram")]
    public async Task<ActionResult<AuthResponse>> Telegram(TelegramAuthRequest request)
    {
        var hasInitData = !string.IsNullOrWhiteSpace(request.InitData);
        var hasIdToken = !string.IsNullOrWhiteSpace(request.IdToken);

        logger.LogInformation(
            "Telegram auth started. InitData={HasInitData}, IdToken={HasIdToken}",
            hasInitData,
            hasIdToken
        );

        if (hasInitData == hasIdToken)
        {
            logger.LogWarning("Telegram auth rejected: exactly one credential is required");
            return BadRequest("telegram_credential_required");
        }

        long telegramId;
        string? telegramUsername;

        if (hasInitData)
        {
            logger.LogInformation("Telegram auth using Mini App initData");

            var botToken = cfg["TelegramBot:Token"];

            if (string.IsNullOrWhiteSpace(botToken))
            {
                logger.LogError("Telegram auth failed: BotToken is not configured");
                return StatusCode(503, "telegram_not_configured");
            }

            var payload = TelegramInitData.Validate(
                request.InitData!,
                botToken,
                DateTimeOffset.UtcNow
            );

            if (payload == null)
            {
                logger.LogWarning("Telegram initData validation failed");
                return Unauthorized("invalid_telegram_data");
            }

            telegramId = payload.Id;
            telegramUsername = payload.Username;

            logger.LogInformation(
                "Telegram initData validated. TelegramId={TelegramId}",
                telegramId
            );
        }
        else
        {
            logger.LogInformation("Telegram auth using OIDC ID token");

            var clientId = cfg["TelegramBot:ClientId"];

            if (string.IsNullOrWhiteSpace(clientId))
            {
                logger.LogError("Telegram auth failed: ClientId is not configured");
                return StatusCode(503, "telegram_not_configured");
            }

            try
            {
                var payload = await TelegramJsonWebSignature.ValidateAsync(
                    request.IdToken!,
                    new TelegramJsonWebSignature.ValidationSettings
                    {
                        Audience = [clientId],
                    }
                );

                telegramId = payload.Id;
                telegramUsername = payload.Username;

                logger.LogInformation(
                    "Telegram ID token validated. TelegramId={TelegramId}",
                    telegramId
                );
            }
            catch (SecurityTokenException e)
            {
                logger.LogWarning(
                    e,
                    "Telegram ID token validation failed"
                );

                return Unauthorized("invalid_telegram_token");
            }
            catch (HttpRequestException e)
            {
                logger.LogError(
                    e,
                    "Telegram OIDC metadata/JWKS request failed"
                );

                return StatusCode(503, "telegram_unavailable");
            }
            catch (InvalidOperationException e)
            {
                logger.LogError(
                    e,
                    "Telegram OIDC configuration failed"
                );

                return StatusCode(503, "telegram_unavailable");
            }
            catch (OperationCanceledException) when (HttpContext.RequestAborted.IsCancellationRequested)
            {
                logger.LogInformation("Telegram auth request was aborted by the client");
                throw;
            }
        }

        var providerId = telegramId.ToString(CultureInfo.InvariantCulture);

        logger.LogDebug(
            "Looking up Telegram login. ProviderId={ProviderId}",
            providerId
        );

        var login = await db.UserLogins
            .Include(x => x.User)
            .SingleOrDefaultAsync(x =>
                x.Provider == AuthProviderType.Telegram &&
                x.ProviderId == providerId);

        var user = login?.User;

        if (user == null)
        {
            logger.LogInformation(
                "No Candle user exists for TelegramId={TelegramId}. Creating user",
                telegramId
            );

            var useTelegramUsername = LoginRules.ValidUsername(telegramUsername)
                && !await db.Users.AnyAsync(x => x.Username == telegramUsername);

            user = new User
            {
                Username = useTelegramUsername ? telegramUsername! : $"candle_{Guid.NewGuid():N}"
            };

            db.UserLogins.Add(new UserLogin
            {
                User = user,
                Provider = AuthProviderType.Telegram,
                ProviderId = providerId,
                ProviderData = "{}"
            });

            try
            {
                try
                {
                    await db.SaveChangesAsync();
                }
                catch (DbUpdateException e) when (useTelegramUsername &&
                    e.InnerException is Npgsql.PostgresException
                    {
                        SqlState: "23505", ConstraintName: "IX_Users_Username"
                    })
                {
                    user.Username = $"candle_{Guid.NewGuid():N}";
                    await db.SaveChangesAsync();
                }

                logger.LogInformation(
                    "Created Candle user. UserId={UserId}, TelegramId={TelegramId}",
                    user.Id,
                    telegramId
                );
            }
            catch (DbUpdateException e)
                when (e.InnerException is Npgsql.PostgresException { SqlState: "23505" })
            {
                logger.LogWarning(
                    "Concurrent Telegram registration detected. TelegramId={TelegramId}",
                    telegramId
                );

                db.ChangeTracker.Clear();

                login = await db.UserLogins
                    .Include(x => x.User)
                    .SingleOrDefaultAsync(x =>
                        x.Provider == AuthProviderType.Telegram &&
                        x.ProviderId == providerId);

                if (login == null)
                {
                    logger.LogError(
                        "Telegram registration conflict could not be resolved. TelegramId={TelegramId}",
                        telegramId
                    );

                    return Conflict("credentials_changed");
                }

                user = login.User;

                logger.LogInformation(
                    "Recovered existing user after concurrent registration. UserId={UserId}",
                    user.Id
                );
            }
        }
        else
        {
            logger.LogInformation(
                "Existing Telegram user found. UserId={UserId}, TelegramId={TelegramId}",
                user.Id,
                telegramId
            );
        }

        if (user.IsDeleted)
        {
            logger.LogWarning(
                "Telegram auth rejected because account is deleted. UserId={UserId}",
                user.Id
            );

            return Unauthorized("account_unavailable");
        }

        await botPreferences.ApplyToAccount(telegramId, user.Id, HttpContext.RequestAborted);

        logger.LogInformation(
            "Telegram auth successful. UserId={UserId}",
            user.Id
        );

        return Ok(await sessions.Issue(user.Id));
    }

    [AllowAnonymous]
    [HttpPost("google")]
    public async Task<ActionResult<AuthResponse>> Google([FromBody] GoogleAuthRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.IdToken)) return BadRequest("idToken required");

        var payload = await GoogleJsonWebSignature.ValidateAsync(
            request.IdToken,
            new GoogleJsonWebSignature.ValidationSettings { Audience = [cfg["Google:ClientId"]] }
        );

        var providerUserId = payload.Subject;
        var raw = JsonSerializer.Serialize(payload);

        var userLogin = await db.UserLogins
            .Include(x => x.User)
            .FirstOrDefaultAsync(x =>
                x.Provider == AuthProviderType.Google &&
                x.ProviderId == providerUserId
            );

        var user = userLogin?.User;
        if (user?.IsDeleted == true) return Unauthorized("account_unavailable");

        if (user is null)
        {
            user = new User { Username = $"candle_{Guid.NewGuid():N}" };

            db.UserLogins.Add(new UserLogin
            {
                User = user,
                Provider = AuthProviderType.Google,
                ProviderId = providerUserId,
                ProviderData = raw
            });

            await db.SaveChangesAsync();
        }

        return Ok(await sessions.Issue(user.Id));
    }

    [AllowAnonymous]
    [HttpPost("refresh")]
    public async Task<ActionResult<AuthResponse>> Refresh([FromBody] RefreshRequest body)
    {
        var refreshToken = await db.RefreshTokens.FirstOrDefaultAsync(x => x.Token == body.RefreshToken);

        if (refreshToken is not { RevokedAt: null } || refreshToken.ExpiresAt <= DateTime.UtcNow)
            return Unauthorized("Invalid or expired refresh token");
        if (!await db.Users.AnyAsync(x => x.Id == refreshToken.UserId && !x.IsDeleted))
            return Unauthorized("account_unavailable");

        refreshToken.RevokedAt = DateTime.UtcNow;

        var newRefresh = JwtService.CreateRefresh();

        db.RefreshTokens.Add(new RefreshToken
        {
            UserId = refreshToken.UserId,
            Token = newRefresh,
            ExpiresAt = DateTime.UtcNow.AddDays(30),
            CreatedAt = DateTime.UtcNow
        });

        var access = JwtService.CreateAccess(
            refreshToken.UserId,
            cfg["Jwt:Key"]!,
            cfg["Jwt:Issuer"]!,
            cfg["Jwt:Audience"]!,
            TimeSpan.FromMinutes(15)
        );

        await db.SaveChangesAsync();

        return Ok(new AuthResponse
        {
            Access = access,
            Refresh = newRefresh,
            UserId = refreshToken.UserId
        });
    }

    [Authorize]
    [HttpPost("logout")]
    public async Task<IActionResult> Logout([FromBody] LogoutRequest body)
    {
        var userId = User.GetId();

        var refreshToken = await db.RefreshTokens.FirstOrDefaultAsync(x => x.Token == body.Refresh);

        if (refreshToken is null || refreshToken.UserId != userId) return NotFound("refresh_not_found");

        if (refreshToken.RevokedAt is not null) return Ok();

        refreshToken.RevokedAt = DateTime.UtcNow;

        await db.SaveChangesAsync();

        return Ok();
    }

    [Authorize]
    [HttpPost("logout-all")]
    public async Task<IActionResult> LogoutAll()
    {
        var userId = User.GetId();

        var tokens = await db.RefreshTokens.Where(x => x.UserId == userId && x.RevokedAt == null).ToListAsync();

        tokens.ForEach(x => x.RevokedAt = DateTime.UtcNow);

        await db.SaveChangesAsync();

        return Ok();
    }
}
