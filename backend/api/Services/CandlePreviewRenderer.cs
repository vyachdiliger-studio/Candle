using ImageMagick;
using ImageMagick.Drawing;

namespace CandleBackend.Services;

public sealed class CandlePreviewRenderer
{
    public const int Width = 1200;
    public const int Height = 630;

    private readonly byte[] overlay;

    public CandlePreviewRenderer()
    {
        using var stream = typeof(CandlePreviewRenderer).Assembly
            .GetManifestResourceStream("CandleBackend.Assets.Previews.candle.png")
            ?? throw new InvalidOperationException("Candle preview asset is missing.");
        using var buffer = new MemoryStream();
        stream.CopyTo(buffer);
        using var glow = new MagickImage(MagickColors.Transparent, Width, Height);
        new Drawables()
            .FillColor(new MagickColor("#FFC66B55"))
            .StrokeColor(MagickColors.Transparent)
            .Ellipse(Width / 2, 115, 75, 65, 0, 360)
            .Draw(glow);
        glow.Blur(0, 35);

        using var foreground = new MagickImage(buffer.ToArray());
        foreground.Resize(0, 530);
        glow.Composite(foreground, Gravity.Center, CompositeOperator.Over);
        overlay = glow.ToByteArray(MagickFormat.Png);
    }

    public byte[] Render(byte[]? background)
    {
        using var canvas = new MagickImage(new MagickColor("#12181E"), Width, Height);

        if (background is not null)
        {
            using var image = new MagickImage(background);
            var scale = Math.Min((double)image.Width / Width, (double)image.Height / Height);
            var cropWidth = (uint)Math.Max(1, Math.Floor(Width * scale));
            var cropHeight = (uint)Math.Max(1, Math.Floor(Height * scale));
            image.Crop(cropWidth, cropHeight, Gravity.Center);
            image.ResetPage();
            image.Resize(new MagickGeometry(Width, Height) { IgnoreAspectRatio = true });
            canvas.Composite(image, Gravity.Center, CompositeOperator.Over);

            using var shade = new MagickImage(new MagickColor("#0B111999"), Width, Height);
            canvas.Composite(shade, CompositeOperator.Over);
        }

        using var foreground = new MagickImage(overlay);
        canvas.Composite(foreground, CompositeOperator.Over);
        canvas.Strip();
        canvas.Quality = 88;
        return canvas.ToByteArray(MagickFormat.Jpeg);
    }
}
