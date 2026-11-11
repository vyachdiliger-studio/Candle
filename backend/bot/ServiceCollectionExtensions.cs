using CandleBot.Presentation;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using Telegram.Bot;

namespace CandleBot;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddCandleBot(this IServiceCollection services, IConfiguration configuration)
    {
        var section = configuration.GetSection(BotOptions.SectionName);
        services.AddOptions<BotOptions>().Bind(section)
            .Validate(o => !o.Enabled || !string.IsNullOrWhiteSpace(o.Token), "TelegramBot:Token is required")
            .Validate(o => !o.Enabled || IsHttps(o.MiniAppUrl), "TelegramBot:MiniAppUrl must be HTTPS")
            .Validate(o => !o.Enabled || IsHttps(o.WebhookUrl), "TelegramBot:WebhookUrl must be HTTPS")
            .Validate(o => !o.Enabled || o.WebhookSecret.Length is >= 1 and <= 256 &&
                o.WebhookSecret.All(c => char.IsAsciiLetterOrDigit(c) || c is '_' or '-'),
                "TelegramBot:WebhookSecret must contain 1–256 letters, digits, underscores or hyphens")
            .ValidateOnStart();

        if (!section.GetValue<bool>(nameof(BotOptions.Enabled))) return services;

        services.AddSingleton<ITelegramBotClient>(provider =>
            new TelegramBotClient(provider.GetRequiredService<IOptions<BotOptions>>().Value.Token));
        services.AddSingleton<BotKeyboards>();
        services.AddScoped<BotUpdateHandler>();
        services.AddHostedService<BotSetup>();
        return services;
    }

    private static bool IsHttps(string value) =>
        Uri.TryCreate(value, UriKind.Absolute, out var uri) && uri.Scheme == Uri.UriSchemeHttps;
}
