using System.ComponentModel.DataAnnotations;
using CandleBackend.Models;

namespace CandleBackend.Dtos;

public class CreateCandleRequest
{
    public Guid? BackgroundResourceId { get; set; }

    public string? Message { get; set; }

    public LocationDto? Location { get; set; }

    /// <summary>The address of <see cref="Location"/>; needs a location.</summary>
    [MaxLength(Candle.AddressMaxLength)]
    public string? Address { get; set; }
}
