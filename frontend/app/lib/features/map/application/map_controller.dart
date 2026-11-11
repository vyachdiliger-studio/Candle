import "../../../core/security/session_epoch.dart";
import "../../candle/domain/remote_candle_repository.dart";
import "dart:async";

import "package:flutter/foundation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "package:candle_frontend/common/utils/iterable_extension.dart";
import "package:candle_frontend/core/geo/tile_id.dart";
import "package:candle_frontend/core/geo/web_mercator.dart";
import "package:candle_frontend/core/models/location.dart";
import "package:candle_frontend/features/candle/candle.dart";

part "map_controller.g.dart";

typedef Viewport = ({double west, double south, double east, double north});

typedef CameraPosition = ({Location center, double zoom});

typedef Grid = ({int z, int cells});

/// Clusters travel with the grid they were grouped by: read apart, the two can
/// disagree mid-zoom and every stale cluster collapses into one cell.
typedef MapClusters = ({Grid grid, List<CandleCluster> clusters});

typedef _CacheKey = (TileId tile, int cells);

@Riverpod(keepAlive: true)
class MapController extends _$MapController {
  RemoteCandleRepository get repository => ref.read(candleRepositoryProvider);

  final _tiles = <_CacheKey, List<CandleCluster>>{};
  final _inFlight = <_CacheKey>{};

  var _visible = const <_CacheKey>[];

  CameraPosition? lastCamera;

  var _grid = _emptyGrid;

  Viewport? _viewport;

  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 250);

  static const _maxConcurrentTileRequests = 6;

  static const _emptyGrid = (z: 0, cells: WebMercator.defaultCellsPerTile);

  /// How much of a ring beyond the viewport keeps its clusters, as a share
  /// of the viewport, so panning does not pop markers in at the edge.
  static const _viewportMargin = 0.5;

  @override
  Future<MapClusters> build() async {
    ref.watch(sessionEpochProvider);
    _tiles.clear();
    _inFlight.clear();
    _visible = const [];
    lastCamera = null;
    _viewport = null;
    _grid = _emptyGrid;
    ref.onDispose(() => _debounceTimer?.cancel());

    return (grid: _emptyGrid, clusters: const <CandleCluster>[]);
  }

  void onViewportChanged({
    required CameraPosition camera,
    required Viewport viewport,
  }) {
    lastCamera = camera;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      _debounceDuration,
      () => loadViewport(zoom: camera.zoom, viewport: viewport),
    );
  }

  Future<void> loadViewport({
    required double zoom,
    required Viewport viewport,
  }) async {
    final operationRef = ref;
    final cells = WebMercator.cellsPerTileFor(zoom);
    final z = WebMercator.dataZoomFor(zoom);

    _grid = (z: z, cells: cells);
    _viewport = _expanded(viewport);

    _visible = WebMercator.tilesCovering(
      z: z,
      west: viewport.west,
      south: viewport.south,
      east: viewport.east,
      north: viewport.north,
    ).map((tile) => (tile, cells)).toList();

    final missing = _visible
        .where((it) => !_tiles.containsKey(it) && !_inFlight.contains(it))
        .toList();

    if (missing.isEmpty) {
      state = AsyncValue.data(_visibleClusters());

      return;
    }

    state = const AsyncLoading<MapClusters>();

    final next = await AsyncValue.guard(() async {
      await _fetch(missing);

      return _visibleClusters();
    });
    if (operationRef.mounted) state = next;
  }

  Future<Candle> saveLocation({
    required int id,
    required Location location,
    String? address,
  }) async {
    final operationRef = ref;
    final result = await repository.updateLocation(id: id, location: location, address: address);

    if (!operationRef.mounted) throw const SessionChanged();
    return result.fold(
      (_) => throw Exception("failed to save the candle's location"),
      (saved) {
        _tiles.clear();

        return saved;
      },
    );
  }

  Future<void> _fetch(List<_CacheKey> missing) async {
    final operationRef = ref;
    _inFlight.addAll(missing);

    try {
      final outcomes = <bool>[];

      for (final batch in missing.chunked(_maxConcurrentTileRequests)) {
        if (!operationRef.mounted) return;
        outcomes.addAll(await Future.wait(batch.map(_loadTile)));
      }

      if (!outcomes.contains(true)) throw Exception("failed to load candles");
    } finally {
      if (operationRef.mounted) _inFlight.removeAll(missing);
    }
  }

  Future<bool> _loadTile(_CacheKey key) async {
    final operationRef = ref;
    final (tile, cells) = key;

    final result = await repository.getTile(
      z: tile.z,
      x: tile.x,
      y: tile.y,
      cellsPerTile: cells,
    );

    if (!operationRef.mounted) return false;
    return result.fold((_) => false, (clusters) {
      _tiles[key] = clusters;

      return true;
    });
  }

  MapClusters _visibleClusters() {
    final bounds = _viewport;

    // A data tile spans several screens, so publishing every cluster it holds
    // would hand the map thousands of markers it cannot show - and hand them
    // all to it at once the moment the user zooms out.
    bool isNearby(CandleCluster cluster) =>
        bounds == null ||
        WebMercator.isInside(
          latitude: cluster.location.latitude,
          longitude: cluster.location.longitude,
          west: bounds.west,
          south: bounds.south,
          east: bounds.east,
          north: bounds.north,
        );

    return (
      grid: _grid,
      clusters: _visible
          .expand((it) => _tiles[it] ?? const <CandleCluster>[])
          .where(isNearby)
          .toList(),
    );
  }

  Viewport _expanded(Viewport viewport) {
    final lonSpan = viewport.east >= viewport.west
        ? viewport.east - viewport.west
        : viewport.east + 360.0 - viewport.west;

    final latSpan = viewport.north - viewport.south;

    final south = (viewport.south - latSpan * _viewportMargin).clamp(
      -90.0,
      90.0,
    );
    final north = (viewport.north + latSpan * _viewportMargin).clamp(
      -90.0,
      90.0,
    );

    if (lonSpan * (1 + 2 * _viewportMargin) >= 360.0) {
      return (west: -180.0, south: south, east: 180.0, north: north);
    }

    return (
      west: WebMercator.wrapLongitude(
        viewport.west - lonSpan * _viewportMargin,
      ),
      south: south,
      east: WebMercator.wrapLongitude(
        viewport.east + lonSpan * _viewportMargin,
      ),
      north: north,
    );
  }

  @visibleForTesting
  int get cachedTileCount => _tiles.length;
}
