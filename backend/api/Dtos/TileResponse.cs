namespace CandleBackend.Dtos;

/// <summary>
/// One grid cell of a tile. A cell holding a single candle is that candle:
/// <see cref="Count"/> is 1 and <see cref="CandleId"/> identifies it, so the
/// same endpoint serves both zoomed-out bubbles and individual pins.
/// </summary>
/// <param name="Count">How many candles the cell holds. Never truncated.</param>
/// <param name="Location">Centre of mass of the cell's candles, not the centre of the cell.</param>
/// <param name="CandleId">A representative candle, and the only one when <see cref="Count"/> is 1.</param>
public record ClusterResponse(
    int Count,
    LocationDto Location,
    long CandleId,
    bool HasOwnCandle
);

/// <param name="CellsPerTile">Grid subdivision used, so the client knows the density it asked for.</param>
public record TileResponse(
    int Z,
    int X,
    int Y,
    int CellsPerTile,
    IReadOnlyList<ClusterResponse> Clusters
);
