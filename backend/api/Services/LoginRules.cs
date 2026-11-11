namespace CandleBackend.Services;

public static class LoginRules
{
    // Usernames are literal, case-sensitive identifiers, not email addresses.
    public static bool ValidUsername(string? value) => value is { Length: >= 1 and <= 128 }
        && value == value.Trim() && !value.Any(char.IsControl);
    public static bool ValidPassword(string? value) => value is { Length: >= 6 };
}
