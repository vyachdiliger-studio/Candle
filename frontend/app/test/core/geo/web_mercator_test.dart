import "dart:math" as math;

import "package:candle_frontend/core/geo/tile_id.dart";
import "package:candle_frontend/core/geo/web_mercator.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("tile addressing", () {
    test("matches the server for a known point", () {
      expect(WebMercator.tileX(76.889709, 10), 730);
      expect(WebMercator.tileY(43.238949, 10), 375);
    });

    test("puts the antimeridian at the edge columns", () {
      expect(WebMercator.tileX(177.508330, 3), 7);
      expect(WebMercator.tileX(-165.406387, 3), 0);
    });

    test("clamps beyond the projection limit instead of overflowing", () {
      final n = 1 << 5;

      expect(WebMercator.tileY(89.9, 5), 0);
      expect(WebMercator.tileY(-89.9, 5), n - 1);
      expect(WebMercator.tileX(180.0, 5), n - 1);
    });
  });

  group("tilesCovering", () {
    test("covers a plain viewport", () {
      final tiles = WebMercator.tilesCovering(
        z: 10,
        west: 76.8,
        south: 43.1,
        east: 77.0,
        north: 43.3,
      );

      expect(tiles, contains(const TileId(10, 730, 375)));
      expect(tiles.toSet().length, tiles.length, reason: "no duplicates");
    });

    test("wraps around when the viewport crosses the antimeridian", () {
      final tiles = WebMercator.tilesCovering(
        z: 3,
        west: 170.0,
        south: 60.0,
        east: -170.0,
        north: 70.0,
      );

      final columns = tiles.map((t) => t.x).toSet();

      expect(columns, contains(7), reason: "eastern side of the seam");
      expect(columns, contains(0), reason: "western side of the seam");
      expect(tiles, isNotEmpty);
    });

    test("stays within the grid at every zoom", () {
      for (final z in [0, 1, 5, 12]) {
        final n = 1 << z;
        final tiles = WebMercator.tilesCovering(
          z: z,
          west: -180.0,
          south: -85.0,
          east: 180.0,
          north: 85.0,
        );

        for (final t in tiles) {
          expect(t.x, inInclusiveRange(0, n - 1));
          expect(t.y, inInclusiveRange(0, n - 1));
        }
      }
    });
  });

  group("cell sizing", () {
    test("keeps a cell between 64 and 128 logical pixels at every zoom", () {
      for (var mapZoom = 0.0; mapZoom <= 20.0; mapZoom += 0.1) {
        final z = WebMercator.dataZoomFor(mapZoom);
        final cells = WebMercator.cellsPerTileFor(mapZoom);

        final tilePx = 256.0 * math.pow(2, mapZoom - z);
        final cellPx = tilePx / cells;

        expect(
          cellPx,
          inInclusiveRange(64.0 - 0.001, 128.0),
          reason: "map zoom $mapZoom gave z=$z, cells=$cells, cell=${cellPx}px",
        );
      }
    });

    test("only drops below the full grid at the bottom of the pyramid", () {
      expect(WebMercator.cellsPerTileFor(0.0), 4);
      expect(WebMercator.cellsPerTileFor(1.0), 8);
      expect(WebMercator.cellsPerTileFor(2.0), WebMercator.defaultCellsPerTile);
      expect(
        WebMercator.cellsPerTileFor(14.0),
        WebMercator.defaultCellsPerTile,
      );
    });
  });

  test("data zoom stays coarser than the map and never goes negative", () {
    expect(WebMercator.dataZoomFor(12.4), 10);
    expect(WebMercator.dataZoomFor(1.0), 0);
    expect(WebMercator.dataZoomFor(0.0), 0);
  });

  group("cell indexing", () {
    test(
      "a cluster's average position lands in the same cell as its members",
      () {
        const z = 10;
        const cells = 16;

        final size = WebMercator.cellSize(z, cells);

        // Two points deliberately placed inside one cell, plus the average the
        // server would report for them.
        const west = 76.889709;
        const south = 43.238949;

        final east = west + (size / 4) * 360.0 / WebMercator.worldSize;
        const north = 43.239949;

        final cell = WebMercator.cellOf(
          latitude: south,
          longitude: west,
          z: z,
          cellsPerTile: cells,
        );

        expect(
          WebMercator.cellOf(
            latitude: north,
            longitude: east,
            z: z,
            cellsPerTile: cells,
          ),
          cell,
        );

        expect(
          WebMercator.cellOf(
            latitude: (south + north) / 2,
            longitude: (west + east) / 2,
            z: z,
            cellsPerTile: cells,
          ),
          cell,
        );
      },
    );

    test("neighbouring cells get different indices", () {
      const z = 10;
      const cells = 16;

      final size = WebMercator.cellSize(z, cells);
      final step = size * 360.0 / WebMercator.worldSize;

      final here = WebMercator.cellOf(
        latitude: 43.238949,
        longitude: 76.889709,
        z: z,
        cellsPerTile: cells,
      );

      final next = WebMercator.cellOf(
        latitude: 43.238949,
        longitude: 76.889709 + step,
        z: z,
        cellsPerTile: cells,
      );

      expect(next.$1, here.$1 + 1);
      expect(next.$2, here.$2);
    });

    test("a coarser zoom puts more points in one cell", () {
      const cells = 16;

      final fine = WebMercator.cellOf(
        latitude: 43.3,
        longitude: 76.9,
        z: 14,
        cellsPerTile: cells,
      );

      final coarse = WebMercator.cellOf(
        latitude: 43.3,
        longitude: 76.9,
        z: 10,
        cellsPerTile: cells,
      );

      expect(fine, isNot(coarse));
      expect(
        WebMercator.cellSize(10, cells) > WebMercator.cellSize(14, cells),
        isTrue,
      );
    });
  });

  group("viewport containment", () {
    test("a plain box keeps what is inside and drops what is outside", () {
      bool inside(double lat, double lon) => WebMercator.isInside(
        latitude: lat,
        longitude: lon,
        west: 76.0,
        south: 43.0,
        east: 77.0,
        north: 44.0,
      );

      expect(inside(43.5, 76.5), isTrue);
      expect(inside(43.5, 78.0), isFalse);
      expect(inside(42.0, 76.5), isFalse);
    });

    test("a box crossing the antimeridian covers the ends, not the middle", () {
      bool inside(double lon) => WebMercator.isInside(
        latitude: 0,
        longitude: lon,
        west: 170.0,
        south: -10.0,
        east: -170.0,
        north: 10.0,
      );

      expect(inside(175.0), isTrue);
      expect(inside(-175.0), isTrue);
      expect(inside(0.0), isFalse);
    });

    test("wrapping longitude keeps it within a single world", () {
      expect(WebMercator.wrapLongitude(190.0), closeTo(-170.0, 1e-9));
      expect(WebMercator.wrapLongitude(-190.0), closeTo(170.0, 1e-9));
      expect(WebMercator.wrapLongitude(76.5), closeTo(76.5, 1e-9));
    });
  });
}
