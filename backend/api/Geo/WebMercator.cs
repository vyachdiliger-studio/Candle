namespace CandleBackend.Geo;

/// <summary>
/// Web Mercator (EPSG:3857) tile arithmetic, matching the XYZ scheme the client
/// already uses for its OpenStreetMap raster tiles: at zoom z the world is a
/// 2^z by 2^z grid, x grows east from -180 degrees and y grows south from the
/// top of the projection.
/// </summary>
public static class WebMercator
{
    /// <summary>Width of the projected world in metres.</summary>
    public const double WorldSize = 40075016.685578488;

    /// <summary>Half the world, i.e. the coordinate of the antimeridian.</summary>
    public const double Origin = WorldSize / 2;

    /// <summary>
    /// The projection is undefined at the poles and every client clamps to this
    /// latitude, so a tile never covers anything beyond it.
    /// </summary>
    public const double MaxLatitude = 85.0511287798066;

    public static double TileSize(int z) => WorldSize / (1 << z);

    /// <summary>
    /// Size of one grid cell in metres: a tile split into
    /// <paramref name="cellsPerTile"/> cells per axis. Cell boundaries are
    /// multiples of the cell size across the whole world, so the grid lines up
    /// with tile boundaries and a cluster never straddles two tiles.
    /// </summary>
    public static double CellSize(int z, int cellsPerTile) => TileSize(z) / cellsPerTile;

    /// <summary>
    /// Geographic bounds of a tile. Mercator is cylindrical, so a rectangle in
    /// projected space is also a rectangle in longitude/latitude and this
    /// conversion loses nothing.
    /// </summary>
    public static (double MinLon, double MinLat, double MaxLon, double MaxLat) TileBounds(int z, int x, int y)
    {
        var n = 1 << z;

        var minLon = x / (double)n * 360.0 - 180.0;
        var maxLon = (x + 1) / (double)n * 360.0 - 180.0;

        // y counts southwards, so y is the northern edge and y + 1 the southern one.
        var maxLat = LatitudeAtTileRow(y, n);
        var minLat = LatitudeAtTileRow(y + 1, n);

        return (minLon, minLat, maxLon, maxLat);
    }

    private static double LatitudeAtTileRow(int row, int n)
    {
        var t = Math.PI * (1.0 - 2.0 * row / n);

        return Math.Atan(Math.Sinh(t)) * 180.0 / Math.PI;
    }

    /// <summary>Whether the tile address exists at this zoom.</summary>
    public static bool IsValidTile(int z, int x, int y)
    {
        if (z < 0 || z > 22) return false;

        var n = 1 << z;

        return x >= 0 && x < n && y >= 0 && y < n;
    }
}
