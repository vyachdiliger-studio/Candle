namespace CandleBackend.Storage;

public sealed class S3StorageOptions
{
    public string? Endpoint { get; set; }
    public string? PublicEndpoint { get; set; }
    public string Region { get; set; } = "us-east-1";
    public string Bucket { get; set; } = "candle-media";
    public string? AccessKey { get; set; }
    public string? SecretKey { get; set; }
    public bool ForcePathStyle { get; set; } = true;
}
