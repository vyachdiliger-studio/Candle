namespace CandleBot;

public sealed class BotOptions
{
    public const string SectionName = "TelegramBot";
    public bool Enabled { get; set; }
    public string Token { get; set; } = "";
    public string WebhookUrl { get; set; } = "";
    public string WebhookSecret { get; set; } = "";
    public string MiniAppUrl { get; set; } = "";
    public string ClientId { get; set; } = "";
}
