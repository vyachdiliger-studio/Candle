namespace CandleBackend.Storage;

public interface IMediaStorage
{
    Task<string> CreateUploadUrl(string key, DateTime expiresAt);
    Task<byte[]> Read(string key, CancellationToken cancellationToken);
    Task Write(string key, byte[] bytes, string contentType, CancellationToken cancellationToken);
    Task Delete(string key, CancellationToken cancellationToken);
}
