using Amazon;
using Amazon.Runtime;
using Amazon.S3;
using Amazon.S3.Model;
using Microsoft.Extensions.Options;

namespace CandleBackend.Storage;

public sealed class S3MediaStorage : IMediaStorage, IDisposable
{
    private const int MaxImageBytes = 20 * 1024 * 1024;
    private readonly AmazonS3Client client;
    private readonly AmazonS3Client publicClient;
    private readonly string bucket;

    public S3MediaStorage(IOptions<S3StorageOptions> options)
    {
        var settings = options.Value;
        bucket = settings.Bucket;
        client = CreateClient(settings.Endpoint, settings);
        publicClient = CreateClient(settings.PublicEndpoint ?? settings.Endpoint, settings);
    }

    private static AmazonS3Client CreateClient(string? endpoint, S3StorageOptions settings)
    {
        var config = new AmazonS3Config
        {
            ForcePathStyle = settings.ForcePathStyle,
            AuthenticationRegion = settings.Region,
            RegionEndpoint = RegionEndpoint.GetBySystemName(settings.Region)
        };
        if (!string.IsNullOrWhiteSpace(endpoint))
        {
            config.ServiceURL = endpoint;
            config.UseHttp = new Uri(endpoint).Scheme == "http";
        }
        return string.IsNullOrWhiteSpace(settings.AccessKey)
            ? new AmazonS3Client(config)
            : new AmazonS3Client(new BasicAWSCredentials(settings.AccessKey, settings.SecretKey), config);
    }

    public Task<string> CreateUploadUrl(string key, DateTime expiresAt) => publicClient.GetPreSignedURLAsync(
        new GetPreSignedUrlRequest
        {
            BucketName = bucket,
            Key = key,
            Verb = HttpVerb.PUT,
            Expires = expiresAt,
            Protocol = publicClient.Config.UseHttp ? Protocol.HTTP : Protocol.HTTPS
        });

    public async Task<byte[]> Read(string key, CancellationToken cancellationToken)
    {
        using var response = await client.GetObjectAsync(bucket, key, cancellationToken);
        if (response.ContentLength > MaxImageBytes) throw new InvalidDataException("image_too_large");
        using var bytes = new MemoryStream();
        var buffer = new byte[81920];
        int read;
        while ((read = await response.ResponseStream.ReadAsync(buffer, cancellationToken)) > 0)
        {
            if (bytes.Length + read > MaxImageBytes) throw new InvalidDataException("image_too_large");
            bytes.Write(buffer, 0, read);
        }
        return bytes.ToArray();
    }

    public async Task Write(string key, byte[] bytes, string contentType, CancellationToken cancellationToken)
    {
        using var stream = new MemoryStream(bytes);
        await client.PutObjectAsync(new PutObjectRequest
        {
            BucketName = bucket,
            Key = key,
            InputStream = stream,
            ContentType = contentType,
            UseChunkEncoding = false
        }, cancellationToken);
    }

    public async Task Delete(string key, CancellationToken cancellationToken) =>
        await client.DeleteObjectAsync(bucket, key, cancellationToken);

    public void Dispose()
    {
        client.Dispose();
        publicClient.Dispose();
    }
}
