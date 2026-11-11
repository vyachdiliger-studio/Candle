using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.WebUtilities;

namespace CandleBackend.Services;

public static class TelegramInitData
{
    public sealed record Payload(long Id, string? Username);

    // Only used to exchange fresh launch credentials for our own refreshable session.
    public static Payload? Validate(string? data, string botToken, DateTimeOffset now)
    {
        if (string.IsNullOrWhiteSpace(data) || data.Length > 16384) return null;
        try
        {
            var fields = QueryHelpers.ParseQuery(data);
            if (fields.Any(x => x.Value.Count != 1) ||
                !fields.TryGetValue("hash", out var hash) || hash.ToString().Length != 64)
                return null;
            var supplied = Convert.FromHexString(hash.ToString());
            var check = string.Join("\n", fields.Where(x => x.Key != "hash")
                .OrderBy(x => x.Key, StringComparer.Ordinal).Select(x => $"{x.Key}={x.Value}"));
            var secret = HMACSHA256.HashData(Encoding.UTF8.GetBytes("WebAppData"), Encoding.UTF8.GetBytes(botToken));
            var expected = HMACSHA256.HashData(secret, Encoding.UTF8.GetBytes(check));
            if (!CryptographicOperations.FixedTimeEquals(supplied, expected)) return null;
            if (!fields.TryGetValue("auth_date", out var date) ||
                !long.TryParse(date.ToString(), NumberStyles.None, CultureInfo.InvariantCulture, out var seconds))
                return null;
            var age = now - DateTimeOffset.FromUnixTimeSeconds(seconds);
            if (age < TimeSpan.FromSeconds(-30) || age > TimeSpan.FromMinutes(10)) return null;
            if (!fields.TryGetValue("user", out var user)) return null;
            using var json = JsonDocument.Parse(user.ToString());
            if (json.RootElement.ValueKind != JsonValueKind.Object ||
                !json.RootElement.TryGetProperty("id", out var id) ||
                id.ValueKind != JsonValueKind.Number || !id.TryGetInt64(out var value) || value <= 0)
                return null;
            var username = json.RootElement.TryGetProperty("username", out var name)
                && name.ValueKind == JsonValueKind.String ? name.GetString() : null;
            return new Payload(value, username);
        }
        catch (Exception error) when (error is FormatException or JsonException or ArgumentException)
        {
            return null;
        }
    }
}
