using System.Globalization;
using System.Net;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Protocols;
using Microsoft.IdentityModel.Protocols.OpenIdConnect;
using Microsoft.IdentityModel.Tokens;

namespace CandleBackend.Services;

public static class TelegramJsonWebSignature
{
    private const string Issuer = "https://oauth.telegram.org";
    private const string MetadataAddress = Issuer + "/.well-known/openid-configuration";

    private static readonly HttpClient TelegramHttpClient = new(
        new HttpClientHandler
        {
            AutomaticDecompression =
                DecompressionMethods.GZip |
                DecompressionMethods.Deflate |
                DecompressionMethods.Brotli
        }
    );

    private static readonly ConfigurationManager<OpenIdConnectConfiguration> Configuration = new(
        MetadataAddress,
        new OpenIdConnectConfigurationRetriever(),
        new HttpDocumentRetriever(TelegramHttpClient)
        {
            RequireHttps = true
        }
    );

    public sealed class ValidationSettings
    {
        public required IEnumerable<string> Audience { get; init; }
    }

    public sealed record Payload(long Id, string? Username);

    public static async Task<Payload> ValidateAsync(
        string jwt,
        ValidationSettings settings,
        CancellationToken cancellationToken = default
    )
    {
        if (string.IsNullOrWhiteSpace(jwt) || jwt.Length > 16_384)
            throw new SecurityTokenMalformedException("Invalid Telegram ID token.");

        var audiences = settings.Audience
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .ToArray();

        if (audiences.Length == 0)
            throw new ArgumentException("At least one audience is required.", nameof(settings));

        var handler = new JsonWebTokenHandler
        {
            MapInboundClaims = false,
        };

        var configuration = await Configuration.GetConfigurationAsync(cancellationToken);

        var result = await ValidateAsync(
            handler,
            jwt,
            audiences,
            configuration.SigningKeys
        );

        if (result is { IsValid: false, Exception: SecurityTokenSignatureKeyNotFoundException })
        {
            Configuration.RequestRefresh();

            configuration = await Configuration.GetConfigurationAsync(cancellationToken);

            result = await ValidateAsync(
                handler,
                jwt,
                audiences,
                configuration.SigningKeys
            );
        }

        if (!result.IsValid) throw result.Exception ?? new SecurityTokenValidationException(
            "Invalid Telegram ID token."
        );

        var id = result.ClaimsIdentity.FindFirst("id")?.Value;

        if (!long.TryParse(
            id,
            NumberStyles.None,
            CultureInfo.InvariantCulture,
            out var telegramId
        ) || telegramId <= 0)
        {
            throw new SecurityTokenValidationException(
                "Telegram ID token does not contain a valid profile id."
            );
        }

        return new Payload(telegramId, result.ClaimsIdentity.FindFirst("preferred_username")?.Value);
    }

    private static Task<TokenValidationResult> ValidateAsync(
        JsonWebTokenHandler handler,
        string jwt,
        IEnumerable<string> audiences,
        ICollection<SecurityKey> signingKeys
    )
    {
        return handler.ValidateTokenAsync(
            jwt,
            new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidIssuer = Issuer,

                ValidateAudience = true,
                ValidAudiences = audiences,

                ValidateIssuerSigningKey = true,
                IssuerSigningKeys = signingKeys,
                RequireSignedTokens = true,

                ValidateLifetime = true,
                RequireExpirationTime = true,
                ClockSkew = TimeSpan.FromSeconds(30),

                ValidAlgorithms =
                [
                    SecurityAlgorithms.RsaSha256,
                    SecurityAlgorithms.EcdsaSha256,
                ],
            }
        );
    }
}
