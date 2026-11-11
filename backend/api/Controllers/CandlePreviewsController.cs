using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CandleBackend.Controllers;

[ApiController]
[AllowAnonymous]
[Route("previews/candles/v1")]
public sealed class CandlePreviewsController : ControllerBase
{
    [HttpGet("default.jpg")]
    public IActionResult Default()
    {
        var stream = typeof(CandlePreviewsController).Assembly
            .GetManifestResourceStream("CandleBackend.Assets.Previews.default.jpg")
            ?? throw new InvalidOperationException("Default candle preview is missing.");

        Response.Headers.CacheControl = "public,max-age=31536000,immutable";
        return File(stream, "image/jpeg");
    }
}
