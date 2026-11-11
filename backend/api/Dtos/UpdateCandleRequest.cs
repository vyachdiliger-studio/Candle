using CandleBackend.Json;

namespace CandleBackend.Dtos;

/// <summary>
/// A partial update: an omitted field is left alone, an explicit null clears it.
/// </summary>
public class UpdateCandleRequest
{
    public Optional<Guid?> BackgroundResourceId { get; set; }

    public Optional<string> Message { get; set; }

    public Optional<LocationDto> Location { get; set; }

    /// <summary>
    /// Moving the location without sending an address clears the old one, since
    /// it described the previous spot.
    /// </summary>
    public Optional<string> Address { get; set; }
}
