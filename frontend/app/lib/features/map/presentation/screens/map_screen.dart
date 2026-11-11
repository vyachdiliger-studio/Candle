import "../show_location_failure.dart";
import "../../../../core/location/location_controller.dart";
import "../widgets/map_location_button.dart";
import "package:candle_frontend/core/constants/sizes.dart";
import "package:candle_frontend/features/candle/application/candle_gallery_controller.dart";
import "dart:async";

import "package:candle_frontend/core/config/package_name_provider.dart";
import "package:candle_frontend/core/geo/web_mercator.dart";
import "package:candle_frontend/core/models/location.dart";
import "package:candle_frontend/features/candle/presentation/share_candle.dart";
import "package:candle_frontend/features/candle/candle.dart";
import "package:candle_frontend/features/map/application/address_field_controller.dart";
import "package:candle_frontend/features/map/application/map_controller.dart";
import "package:candle_frontend/features/map/application/map_mutations.dart";
import "package:candle_frontend/features/map/application/map_selection_controller.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:flutter_riverpod/experimental/mutation.dart";
import "package:flutter_map/flutter_map.dart" as fm;
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:latlong2/latlong.dart";

import "../widgets/candle_location_editor.dart";
import "../widgets/map_compass_button.dart";
import "../widgets/candle_location_row.dart";
import "../widgets/candle_map_mark.dart";
import "../widgets/candle_preview_card.dart";

class MapScreen extends HookConsumerWidget {
  const MapScreen({super.key});

  static const _initialCenter = Location(
    latitude: 0,
    longitude: 0,
  );
  static const _initialZoom = 12.0;
  static const _minZoom = 1.0;
  static const _zoomStepOnClusterTap = 2.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeState = GoRouterState.of(context);
    final requestedCandleId = int.tryParse(
      routeState.uri.queryParameters["focus"] ?? "",
    );
    final userId = ref.watch(galleryUserIdProvider);
    final extra = routeState.extra;
    final requestedCandle = extra is Candle ? extra : null;

    final shouldLocateInitially = useMemoized(
      () =>
          requestedCandleId == null &&
          requestedCandle?.location == null &&
          ref.read(mapControllerProvider.notifier).lastCamera == null,
    );
    final userMovedCamera = useRef(false);
    final didRequestLocation = useRef(false);

    final initialCamera = useMemoized(() {
      final remembered =
          ref.read(mapControllerProvider.notifier).lastCamera ??
          (center: _initialCenter, zoom: requestedCandleId == null ? _minZoom : _initialZoom);

      final location = requestedCandle?.location;

      return location == null ? remembered : (center: location, zoom: remembered.zoom);
    });

    final mapUiController = useMemoized(() => fm.MapController());
    final draftLocation = useValueNotifier(initialCamera.center);
    final editing = useState<Candle?>(
      requestedCandle?.location == null && userId != null && requestedCandle?.author?.id == userId
          ? requestedCandle
          : null,
    );

    final tiles = ref.watch(mapControllerProvider);
    final packageName = ref.watch(packageNameProvider);
    final selected = ref.watch(mapSelectionProvider);

    final isSaving = ref.watch(saveCandleLocationMutation) is MutationPending;
    final isLoading = tiles.isLoading;

    Location cameraCenter() {
      final center = mapUiController.camera.center;

      return Location(latitude: center.latitude, longitude: center.longitude);
    }

    void onCameraIdle() {
      if (editing.value != null) return;

      final camera = mapUiController.camera;
      final bounds = camera.visibleBounds;

      ref
          .read(mapControllerProvider.notifier)
          .onViewportChanged(
            camera: (center: cameraCenter(), zoom: camera.zoom),
            viewport: (
              west: bounds.southWest.longitude,
              south: bounds.southWest.latitude,
              east: bounds.northEast.longitude,
              north: bounds.northEast.latitude,
            ),
          );
    }

    void onMapEvent(fm.MapEvent event) {
      if (event.source != fm.MapEventSource.mapController &&
          event is! fm.MapEventNonRotatedSizeChange) {
        userMovedCamera.value = true;
      }
      if (editing.value != null) {
        draftLocation.value = cameraCenter();

        if (event.source != fm.MapEventSource.mapController) {
          ref.read(addressFieldControllerProvider.notifier).markStale();
        }

        return;
      }

      final isIdle = switch (event) {
        fm.MapEventMoveEnd() ||
        fm.MapEventRotateEnd() ||
        fm.MapEventRotate(source: fm.MapEventSource.mapController) ||
        fm.MapEventFlingAnimationEnd() ||
        fm.MapEventDoubleTapZoomEnd() ||
        fm.MapEventScrollWheelZoom() ||
        fm.MapEventNonRotatedSizeChange() ||
        fm.MapEventMove(source: fm.MapEventSource.mapController) => true,
        _ => false,
      };

      if (isIdle) onCameraIdle();
    }

    Future<void> locate({bool automatic = false}) async {
      final location = await ref.read(locationControllerProvider.notifier).locate();
      if (!context.mounted) return;
      if (automatic && userMovedCamera.value) return;
      if (location == null) {
        if (!automatic) await showLocationFailure(context, ref);
        return;
      }
      mapUiController.move(LatLng(location.latitude, location.longitude), _initialZoom);
    }

    void onMapReady() {
      onCameraIdle();
      if (shouldLocateInitially && !didRequestLocation.value) {
        didRequestLocation.value = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) unawaited(locate(automatic: true));
        });
      }
    }

    // Deliberately keeps the current zoom: the candle is found by the cluster
    // holding it lighting up, not by diving in close enough to break it apart.
    void moveTo(Location? location) {
      final camera = mapUiController.camera;

      mapUiController.move(
        location == null ? camera.center : LatLng(location.latitude, location.longitude),
        camera.zoom,
      );
    }

    void startEditing(Candle candle) {
      moveTo(candle.location);

      draftLocation.value = cameraCenter();

      editing.value = candle;
    }

    void cancelEditing() {
      final candle = editing.value;

      editing.value = null;

      // A candle with no coordinates has no marker to fall back to, so
      // abandoning its placement leaves the map rather than baring a card that
      // points at nothing.
      if (candle?.location == null) {
        ref.read(mapSelectionProvider.notifier).clear();

        context.pop();

        return;
      }

      onCameraIdle();
    }

    Future<void> saveEditing() async {
      final candle = editing.value;

      if (candle == null) return;

      await saveCandleLocationMutation.run(ref, (_) async {
        final saved = await ref
            .read(mapControllerProvider.notifier)
            .saveLocation(
              id: candle.id,
              location: draftLocation.value,
              address: ref.read(addressFieldControllerProvider).label,
            );

        editing.value = null;

        ref.read(mapSelectionProvider.notifier).select(saved);
        ref.read(candleGalleryProvider.notifier).publish(saved);
        ref.invalidate(candleControllerProvider(candle.id));

        onCameraIdle();

        return saved;
      });
    }

    useEffect(() {
      if (requestedCandleId == null) return null;

      var isGone = false;

      unawaited(() async {
        final candle = await ref.read(mapSelectionProvider.notifier).selectById(requestedCandleId);

        if (isGone || candle == null || requestedCandle != null) return;

        // A link can name any candle, including someone else's, so placement is
        // only ever entered for one of ours.
        if (candle.location == null && candle.author?.id == userId && userId != null) {
          startEditing(candle);
        } else {
          moveTo(candle.location);
        }
      }());

      return () => isGone = true;
    }, [requestedCandleId]);

    final markers = _buildMarkers(mapUiController, ref, tiles.value, selected);

    // Cancelling the placement of a candle that is not on the map yet would
    // leave its card standing over a map with no marker behind it, so that one
    // case leaves the screen instead of unwinding into the details.
    final isPlacingUnplaced = editing.value?.location == null && editing.value != null;

    return PopScope(
      canPop: isPlacingUnplaced || (editing.value == null && selected == null),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          if (isPlacingUnplaced) ref.read(mapSelectionProvider.notifier).clear();

          return;
        }

        if (editing.value != null) {
          cancelEditing();

          return;
        }

        ref.read(mapSelectionProvider.notifier).clear();
      },
      child: Stack(
        children: [
          fm.FlutterMap(
            mapController: mapUiController,
            options: fm.MapOptions(
              initialCenter: LatLng(
                initialCamera.center.latitude,
                initialCamera.center.longitude,
              ),
              initialZoom: initialCamera.zoom < _minZoom ? _minZoom : initialCamera.zoom,
              minZoom: _minZoom,
              onMapEvent: onMapEvent,
              onMapReady: onMapReady,
            ),
            children: [
              fm.TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: packageName,
              ),
              if (editing.value == null) fm.MarkerLayer(markers: markers, rotate: true),
              const MapCompassButton(),
              MapLocationButton(onLocate: () => locate()),
            ],
          ),
          if (editing.value case final candle?)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: SizedBox.square(
                    dimension: CandleMapMarker.diameter,
                    child: CandleMapMarker(candle: candle, isSelected: true, hasOwnCandle: true),
                  ),
                ),
              ),
            ),
          if (isLoading)
            const Positioned(
              top: AppDimensions.avatarCompact,
              right: Sizes.medium,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(Sizes.small),
                  child: SizedBox(
                    width: Sizes.comfortable,
                    height: Sizes.comfortable,
                    child: CircularProgressIndicator(strokeWidth: AppStrokes.regular),
                  ),
                ),
              ),
            ),
          Positioned(
            left: Sizes.none,
            right: Sizes.none,
            bottom: Sizes.none,
            child: switch ((editing.value, selected)) {
              (final Candle candle, _) => CandlePreviewCard(
                candle: candle,
                details: CandleLocationEditor(
                  location: draftLocation,
                  initialAddress: candle.address,
                  isSaving: isSaving,
                  onCancel: cancelEditing,
                  onSave: saveEditing,
                  onMoveTo: moveTo,
                ),
              ),
              (_, final Candle candle) => CandlePreviewCard(
                candle: candle,
                onTap: () => context.goNamed(
                  "candle_by_id",
                  pathParameters: {"id": candle.id.toString()},
                ),
                details: Builder(
                  builder: (context) => CandleLocationRow(
                    location: candle.location,
                    address: candle.address,
                    onEdit: candle.author?.id == userId && userId != null
                        ? () => startEditing(candle)
                        : null,
                    onShare: () => shareCandle(candle, context: context),
                  ),
                ),
              ),
              _ => const SizedBox.shrink(),
            },
          ),
        ],
      ),
    );
  }

  List<fm.Marker> _buildMarkers(
    fm.MapController mapUiController,
    WidgetRef ref,
    MapClusters? tiles,
    Candle? selected,
  ) {
    final grid = tiles?.grid;
    final selectedCell = _cellOf(selected?.location, grid);

    final entries = (tiles?.clusters ?? const <CandleCluster>[])
        .map(
          (cluster) => (
            cluster: cluster,
            isSelected: cluster.isSingleCandle
                ? selected?.id == cluster.candleId
                : selectedCell != null && _cellOf(cluster.location, grid) == selectedCell,
          ),
        )
        .toList();

    fm.Marker toMarker(({CandleCluster cluster, bool isSelected}) entry) => _markerFor(
      cluster: entry.cluster,
      selected: selected,
      isSelected: entry.isSelected,
      onTap: () => _onClusterTap(mapUiController, ref, entry.cluster),
    );

    // The layer stacks markers in list order, so the selected one goes last to
    // keep its ring from being covered by whatever happens to sit near it.
    return [
      ...entries.where((it) => !it.isSelected).map(toMarker),
      ...entries.where((it) => it.isSelected).map(toMarker),
    ];
  }

  (int, int)? _cellOf(Location? location, Grid? grid) {
    if (location == null || grid == null) return null;

    return WebMercator.cellOf(
      latitude: location.latitude,
      longitude: location.longitude,
      z: grid.z,
      cellsPerTile: grid.cells,
    );
  }

  fm.Marker _markerFor({
    required CandleCluster cluster,
    required Candle? selected,
    required bool isSelected,
    required void Function() onTap,
  }) {
    final point = LatLng(cluster.location.latitude, cluster.location.longitude);

    // No key: flutter_map draws a marker once per visible copy of the world and
    // gives every copy the same key, so any key at all is a duplicate waiting
    // for the user to zoom out.
    return fm.Marker(
      point: point,
      width: CandleMapMarker.diameter,
      height: CandleMapMarker.diameter,
      child: CandleMapMarker(
        candle: isSelected ? selected : null,
        count: cluster.count,
        hasOwnCandle: cluster.hasOwnCandle,
        isSelected: isSelected,
        onTap: onTap,
      ),
    );
  }

  void _onClusterTap(
    fm.MapController mapUiController,
    WidgetRef ref,
    CandleCluster cluster,
  ) {
    final point = LatLng(cluster.location.latitude, cluster.location.longitude);

    if (cluster.isSingleCandle) {
      ref.read(mapSelectionProvider.notifier).selectById(cluster.candleId);

      return;
    }

    mapUiController.move(
      point,
      mapUiController.camera.zoom + _zoomStepOnClusterTap,
    );
  }
}
