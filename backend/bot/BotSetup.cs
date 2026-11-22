using CandleBot.Localization;
using CandleBot.Presentation;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Telegram.Bot;
using Telegram.Bot.Types.Enums;

namespace CandleBot;

public sealed class BotSetup(
    ITelegramBotClient client,
    IOptions<BotOptions> options,
    BotKeyboards keyboards,
    ILogger<BotSetup> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                // "" is the default profile for every Telegram language without its own texts.
                foreach (var language in BotLanguage.Supported.Prepend(""))
                {
                    var texts = language == "" ? "en" : language;
                    await client.SetMyName("Candle", languageCode: language, cancellationToken: stoppingToken);
                    await client.SetMyDescription(BotText.Get("Description", texts),
                        languageCode: language, cancellationToken: stoppingToken);
                    await client.SetMyShortDescription(BotText.Get("ShortDescription", texts),
                        languageCode: language, cancellationToken: stoppingToken);
                    await client.SetMyCommands(BotKeyboards.Commands(texts),
                        languageCode: language, cancellationToken: stoppingToken);
                }

                await client.SetChatMenuButton(menuButton: keyboards.Menu("en"), cancellationToken: stoppingToken);
                await client.SetWebhook(options.Value.WebhookUrl,
                    allowedUpdates: [UpdateType.Message, UpdateType.CallbackQuery],
                    maxConnections: 1,
                    secretToken: options.Value.WebhookSecret,
                    cancellationToken: stoppingToken);
                logger.LogInformation("Candle bot profile and webhook configured");
                return;
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                return;
            }
            catch (Exception error)
            {
                logger.LogError(error, "Could not configure Candle bot; retrying in one minute");
            }

            await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
        }
    }
}
