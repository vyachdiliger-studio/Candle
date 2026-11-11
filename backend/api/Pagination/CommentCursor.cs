using System.Security.Cryptography;
using System.Text.Json;
using Microsoft.AspNetCore.DataProtection;

namespace CandleBackend.Pagination;

// A continuation token is bound to one list (a candle's comments or one comment's replies).
public sealed class CommentCursor(IDataProtectionProvider provider)
{
    private readonly IDataProtector protector = provider.CreateProtector("candles.comments.v1");
    public sealed record Position(DateTime CreatedAt, long Id, string Scope);

    public string Encode(DateTime createdAt, long id, string scope) =>
        protector.Protect(JsonSerializer.Serialize(new Position(createdAt, id, scope)));

    public Position? Decode(string token, string scope)
    {
        try
        {
            var position = JsonSerializer.Deserialize<Position>(protector.Unprotect(token));
            return position is { Id: > 0 } && position.Scope == scope
                && position.CreatedAt.Kind == DateTimeKind.Utc ? position : null;
        }
        catch (Exception e) when (e is CryptographicException or JsonException or FormatException)
        {
            return null;
        }
    }
}
