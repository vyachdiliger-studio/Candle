using CandleBackend.Json;

namespace CandleBackend.Dtos;

/// <inheritdoc cref="UpdateCandleRequest"/>
public class UpdateUserRequest
{
    public Optional<string> Username { get; set; }
}
