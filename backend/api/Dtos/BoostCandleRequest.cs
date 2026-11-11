using System.ComponentModel.DataAnnotations;

namespace CandleBackend.Dtos;

public class BoostCandleRequest
{
    [Range(1, int.MaxValue)]
    public int Taps { get; set; }
}
