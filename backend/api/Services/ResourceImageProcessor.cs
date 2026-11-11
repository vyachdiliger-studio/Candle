using ImageMagick;

namespace CandleBackend.Services;

public sealed record ProcessedResource(byte[] Image, byte[] Thumbnail, byte[] Preview, int Width, int Height);

public sealed class ResourceImageProcessor(CandlePreviewRenderer previews)
{
    private const long MaxPixels = 40_000_000;
    private const uint ImageSize = 2560;
    private const uint ThumbnailSize = 320;

    public ProcessedResource Process(byte[] bytes, CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();

        var settings = new MagickReadSettings
        {
            Format = DetectFormat(bytes),
            FrameCount = 1
        };

        using var image = new MagickImage();
        image.Ping(bytes, settings);

        if (image.Width == 0 || image.Height == 0 || (long)image.Width * image.Height > MaxPixels)
        {
            throw new InvalidDataException("image_dimensions_too_large");
        }

        image.Read(bytes, settings);
        image.AutoOrient();
        image.Strip();

        var background = Encode(image, ImageSize, 85);
        var width = (int)image.Width;
        var height = (int)image.Height;

        cancellationToken.ThrowIfCancellationRequested();

        var thumbnail = Encode(image, ThumbnailSize, 75);
        var preview = previews.Render(background);
        return new ProcessedResource(background, thumbnail, preview, width, height);
    }

    private static byte[] Encode(MagickImage image, uint size, uint quality)
    {
        image.Resize(new MagickGeometry(size, size) { Greater = true });
        image.Quality = quality;

        return image.ToByteArray(MagickFormat.WebP);
    }

    private static MagickFormat DetectFormat(ReadOnlySpan<byte> bytes)
    {
        if (bytes.StartsWith(new byte[] { 0xff, 0xd8, 0xff }))
        {
            return MagickFormat.Jpeg;
        }

        if (bytes.StartsWith(new byte[] { 137, 80, 78, 71, 13, 10, 26, 10 }))
        {
            return MagickFormat.Png;
        }

        if (bytes.Length >= 12 && bytes[..4].SequenceEqual("RIFF"u8) && bytes[8..12].SequenceEqual("WEBP"u8))
        {
            return MagickFormat.WebP;
        }

        throw new InvalidDataException("unsupported_image_format");
    }
}
