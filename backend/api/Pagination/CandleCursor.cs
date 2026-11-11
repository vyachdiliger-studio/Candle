using System.Security.Cryptography;
using System.Text.Json;
using CandleBackend.Dtos;
using Microsoft.AspNetCore.DataProtection;

namespace CandleBackend.Pagination;

// A continuation token is bound to the query, but never grants access.
public sealed class CandleCursor(IDataProtectionProvider provider)
{
    private readonly IDataProtector protector = provider.CreateProtector("candles.search.v1");
    public sealed record Position(DateTime CreatedAt, long Id, string Query);

    public static string QueryKey(SearchCandlesRequest request) => Convert.ToHexString(
        SHA256.HashData(JsonSerializer.SerializeToUtf8Bytes(new
        {
            request.Filter.AuthorId,
            request.Filter.Status,
            Ids = request.Filter.Ids?.Distinct().Order().ToArray(),
            request.Sort
        })));

    public string Encode(DateTime createdAt, long id, string query) =>
        protector.Protect(JsonSerializer.Serialize(new Position(createdAt, id, query)));

    public Position? Decode(string token, string query)
    {
        try
        {
            var position = JsonSerializer.Deserialize<Position>(protector.Unprotect(token));
            return position is { Id: > 0 } && position.Query == query
                && position.CreatedAt.Kind == DateTimeKind.Utc ? position : null;
        }
        catch (Exception e) when (e is CryptographicException or JsonException or FormatException)
        {
            return null;
        }
    }
}
