using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using CandleBot;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using Telegram.Bot;
using Telegram.Bot.Types;

namespace CandleBackend.Controllers;

[ApiController]
[AllowAnonymous]
[Route("telegram/webhook")]
[ApiExplorerSettings(IgnoreApi = true)]
public sealed class TelegramWebhookController(IOptions<BotOptions> options) : ControllerBase
{
    [HttpPost]
    public async Task<IActionResult> Receive(CancellationToken cancellationToken)
    {
        var settings = options.Value;
        if (!settings.Enabled) return NotFound();

        var supplied = Request.Headers["X-Telegram-Bot-Api-Secret-Token"].ToString();
        if (!CryptographicOperations.FixedTimeEquals(
                Encoding.UTF8.GetBytes(supplied), Encoding.UTF8.GetBytes(settings.WebhookSecret)))
            return Unauthorized();

        Update? update;
        try
        {
            update = await JsonSerializer.DeserializeAsync<Update>(Request.Body, JsonBotAPI.Options, cancellationToken);
        }
        catch (JsonException)
        {
            return BadRequest();
        }

        if (update == null) return BadRequest();
        var handler = HttpContext.RequestServices.GetRequiredService<BotUpdateHandler>();
        await handler.Handle(update, cancellationToken);
        return Ok();
    }
}
