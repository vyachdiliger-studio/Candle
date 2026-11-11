using CandleBot.Localization;
using CandleBot.Preferences;
using CandleBot.Presentation;
using Telegram.Bot;
using Telegram.Bot.Exceptions;
using Telegram.Bot.Types;
using Telegram.Bot.Types.Enums;

namespace CandleBot;

public sealed class BotUpdateHandler(
    ITelegramBotClient client,
    IBotPreferences preferences,
    BotKeyboards keyboards)
{
    public async Task Handle(Update update, CancellationToken cancellationToken)
    {
        if (update.CallbackQuery is { Message.Chat.Type: ChatType.Private } callback)
        {
            if (callback.From.IsBot || callback.From.Id != callback.Message.Chat.Id) return;
            await HandleCallback(callback, cancellationToken);
            return;
        }

        if (update.Message is not { Chat.Type: ChatType.Private, From: { IsBot: false } sender } message)
            return;

        var language = await Language(sender, cancellationToken);
        var command = message.Text?.Split(' ', 2)[0].Split('@', 2)[0].ToLowerInvariant();
        var page = command switch
        {
            "/start" => "Welcome",
            "/help" => "Help",
            "/language" or "/settings" => "Language",
            _ => "Unknown"
        };

        await Show(message.Chat.Id, null, page, language, cancellationToken);
        if (command == "/start") await UpdateMenu(message.Chat.Id, language, cancellationToken);
    }

    private async Task HandleCallback(CallbackQuery callback, CancellationToken cancellationToken)
    {
        var language = await Language(callback.From, cancellationToken);
        var selected = callback.Data?.StartsWith("language:", StringComparison.Ordinal) == true
            ? callback.Data["language:".Length..]
            : null;

        if (BotLanguage.IsSupported(selected))
        {
            await preferences.SetLanguage(callback.From.Id, selected!, cancellationToken);
            language = selected!;
        }

        try
        {
            await client.AnswerCallbackQuery(callback.Id,
                text: BotLanguage.IsSupported(selected) ? BotText.Get("Saved", language) : null,
                cancellationToken: cancellationToken);
        }
        catch (ApiRequestException error) when (error.ErrorCode == 400 &&
            error.Message.Contains("query is too old", StringComparison.OrdinalIgnoreCase))
        {
        }

        var page = callback.Data switch
        {
            "help" => "Help",
            "language" => "Language",
            _ => "Welcome"
        };

        await Show(callback.Message!.Chat.Id, callback.Message.Id, page, language, cancellationToken);
        if (BotLanguage.IsSupported(selected))
            await UpdateMenu(callback.Message.Chat.Id, language, cancellationToken);
    }

    private async Task<string> Language(User user, CancellationToken cancellationToken) =>
        BotLanguage.Resolve(await preferences.GetLanguage(user.Id, cancellationToken), user.LanguageCode);

    private async Task Show(long chatId, int? messageId, string page, string language,
        CancellationToken cancellationToken)
    {
        var text = BotText.Get(page, language);
        var keyboard = page == "Language" ? keyboards.Languages(language) : keyboards.Home(language);

        if (messageId is { } id)
        {
            try
            {
                await client.EditMessageText(chatId, id, text, parseMode: ParseMode.Html,
                    replyMarkup: keyboard, cancellationToken: cancellationToken);
                return;
            }
            catch (ApiRequestException error) when (error.ErrorCode == 400 &&
                error.Message.Contains("message is not modified", StringComparison.OrdinalIgnoreCase))
            {
                return;
            }
            catch (ApiRequestException error) when (error.ErrorCode == 400 &&
                (error.Message.Contains("message to edit not found", StringComparison.OrdinalIgnoreCase) ||
                 error.Message.Contains("message can't be edited", StringComparison.OrdinalIgnoreCase)))
            {
            }
        }

        await client.SendMessage(chatId, text, parseMode: ParseMode.Html,
            replyMarkup: keyboard, cancellationToken: cancellationToken);
    }

    private async Task UpdateMenu(long chatId, string language, CancellationToken cancellationToken)
    {
        await client.SetChatMenuButton(chatId, keyboards.Menu(language), cancellationToken);
        await client.SetMyCommands(BotKeyboards.Commands(language),
            scope: new BotCommandScopeChat { ChatId = chatId }, cancellationToken: cancellationToken);
    }
}
