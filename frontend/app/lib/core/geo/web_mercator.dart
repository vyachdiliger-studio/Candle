import "dart:math" as math;

import "tile_id.dart";

class WebMercator {
  static const maxLatitude = 85.0511287798066;
  static const dataZoomOffset = 2;
  static const defaultCellsPerTile = 16;
  static int dataZoomFor(double mapZoom) => (mapZoom.floor() - dataZoomOffset).clamp(0, 22);

  static int cellsPerTileFor(double mapZoom) {
    final desired = mapZoom.floor() - dataZoomOffset;
    final shortfall = desired < 0 ? -desired : 0;

    return (defaultCellsPerTile >> shortfall).clamp(1, defaultCellsPerTile);
  }

  static const worldSize = 40075016.685578488;

  static const _earthRadius = worldSize / (2 * math.pi);

  static double mercatorX(double longitude) => longitude * worldSize / 360.0;

  static double mercatorY(double latitude) {
    final r = latitude.clamp(-maxLatitude, maxLatitude) * math.pi / 180.0;

    return _earthRadius * math.log(math.tan(r) + 1 / math.cos(r));
  }

  static double cellSize(int z, int cellsPerTile) => worldSize / (1 << z) / cellsPerTile;

  /// Which cell of the server's world-wide grid a point falls into. The server
  /// groups candles by exactly this, so a cluster and any candle inside it
  /// resolve to the same pair - which is how the client knows where a selected
  /// candle is hiding without the tile response naming it.
  static (int column, int row) cellOf({
    required double latitude,
    required double longitude,
    required int z,
    required int cellsPerTile,
  }) {
    final size = cellSize(z, cellsPerTile);

    return (
      (mercatorX(longitude) / size).floor(),
      (mercatorY(latitude) / size).floor(),
    );
  }

  static int tileX(double longitude, int z) {
    final n = 1 << z;
    final x = ((longitude + 180.0) / 360.0 * n).floor();

    return x.clamp(0, n - 1);
  }

  static int tileY(double latitude, int z) {
    final n = 1 << z;
    final lat = latitude.clamp(-maxLatitude, maxLatitude);
    final r = lat * math.pi / 180.0;
    final y = ((1.0 - math.log(math.tan(r) + 1 / math.cos(r)) / math.pi) / 2.0 * n).floor();

    return y.clamp(0, n - 1);
  }

  static double wrapLongitude(double longitude) {
    final shifted = (longitude + 180.0) % 360.0;

    return (shifted < 0 ? shifted + 360.0 : shifted) - 180.0;
  }

  static bool isInside({
    required double latitude,
    required double longitude,
    required double west,
    required double south,
    required double east,
    required double north,
  }) {
    if (latitude < south || latitude > north) return false;

    // east below west means the box crosses the antimeridian, so the longitudes
    // it covers are the two ends of the range rather than the middle.
    return east >= west
        ? longitude >= west && longitude <= east
        : longitude >= west || longitude <= east;
  }

  static List<TileId> tilesCovering({
    required int z,
    required double west,
    required double south,
    required double east,
    required double north,
  }) {
    final n = 1 << z;

    final yTop = tileY(north, z);
    final yBottom = tileY(south, z);

    final xStart = tileX(west, z);
    final xEnd = tileX(east, z);

    final columns = <int>[];

    if (east >= west) {
      for (var x = xStart; x <= xEnd; x++) {
        columns.add(x);
      }
    } else {
      for (var x = xStart; x < n; x++) {
        columns.add(x);
      }
      for (var x = 0; x <= xEnd; x++) {
        columns.add(x);
      }
    }

    return [
      for (final x in columns)
        for (var y = yTop; y <= yBottom; y++) TileId(z, x, y),
    ];
  }
}
