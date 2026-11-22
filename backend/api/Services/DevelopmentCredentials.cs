namespace CandleBackend.Services;

/// <summary>
/// Credentials that ship in the public repository (<c>.env.example</c>,
/// <c>appsettings.Development.json</c>). Anyone can read them, so outside
/// Development they must never be accepted.
/// </summary>
public static class DevelopmentCredentials
{
    private static readonly string[] StorageKeys = ["candle-local", "candle-local-secret"];
    private const string DatabasePassword = "candle-dev";

    public static bool IsExampleStorageKey(string? value) =>
        !string.IsNullOrWhiteSpace(value) && StorageKeys.Contains(value.Trim(), StringComparer.Ordinal);

    public static bool HasExampleDatabasePassword(string? connectionString)
    {
        if (string.IsNullOrWhiteSpace(connectionString)) return false;

        foreach (var part in connectionString.Split(';'))
        {
            var pair = part.Split('=', 2);
            if (pair.Length == 2
                && pair[0].Trim().Equals("Password", StringComparison.OrdinalIgnoreCase)
                && pair[1].Trim() == DatabasePassword)
                return true;
        }

        return false;
    }
}
