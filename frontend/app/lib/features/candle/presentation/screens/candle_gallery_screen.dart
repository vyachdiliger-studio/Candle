import "package:candle_frontend/l10n/localization.dart";
import "../widgets/candle_thumbnail.dart";
import "package:candle_frontend/core/constants/sizes.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:go_router/go_router.dart";
import "../../application/candle_gallery_controller.dart";
import "candle_screen.dart";

class CandleGalleryScreen extends ConsumerStatefulWidget {
  final int? candleId;
  const CandleGalleryScreen({super.key, this.candleId});
  @override
  ConsumerState<CandleGalleryScreen> createState() => _CandleGalleryScreenState();
}

class _CandleGalleryScreenState extends ConsumerState<CandleGalleryScreen> {
  final _pages = PageController();
  final _strip = ScrollController();
  bool _unavailable = false;
  bool _opening = false;
  int _request = 0;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    if (widget.candleId != null) Future.microtask(_open);
  }

  @override
  void didUpdateWidget(CandleGalleryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.candleId != widget.candleId &&
        widget.candleId != null &&
        ref.read(candleGalleryProvider).value?.selectedId != widget.candleId) {
      Future.microtask(_open);
    }
  }

  Future<void> _open() async {
    final id = widget.candleId;
    if (id == null || !mounted) return;
    final request = ++_request;
    setState(() {
      _opening = true;
      _unavailable = false;
    });
    try {
      await ref.read(candleGalleryProvider.notifier).open(id);
    } catch (_) {
      if (mounted && request == _request) setState(() => _unavailable = true);
    } finally {
      if (mounted && request == _request) setState(() => _opening = false);
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    _strip.dispose();
    super.dispose();
  }

  void _select(int? id) {
    ++_request;
    if (_opening || _unavailable) {
      setState(() {
        _opening = false;
        _unavailable = false;
      });
    }
    ref.read(candleGalleryProvider.notifier).select(id);
    // replace avoids filling browser history with every swipe.
    context.replace(id == null ? "/" : "/candles/$id");
  }

  void _closeRecent(int id) {
    final previous = ref.read(candleGalleryProvider).value?.selectedId;
    ref.read(candleGalleryProvider.notifier).closeRecent(id);
    final selected = ref.read(candleGalleryProvider).value?.selectedId;
    if (previous != selected) {
      context.replace(selected == null ? "/" : "/candles/$selected");
    }
  }

  @override
  Widget build(BuildContext context) {
    final gallery = ref.watch(candleGalleryProvider);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: Sizes.medium),
      child: SafeArea(
        child: gallery.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.l10n.candlesLoadFailed),
                TextButton(
                  onPressed: () {
                    ref.invalidate(candleGalleryProvider);
                    if (widget.candleId != null) _open();
                  },
                  child: Text(context.l10n.retry),
                ),
              ],
            ),
          ),
          data: (data) {
            final candles = data.candles;
            final selectedIndex = data.selectedId == null
                ? 0
                : candles.indexWhere((c) => c.id == data.selectedId) + 1;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              if (_pages.hasClients && (_pages.page?.round() ?? 0) != selectedIndex) {
                _syncing = true;
                _pages.jumpToPage(selectedIndex);
                _syncing = false;
              }
              if (_strip.hasClients) {
                final offset =
                    (selectedIndex * AppDimensions.thumbnailStride -
                            _strip.position.viewportDimension / 2 +
                            AppDimensions.thumbnailStride / 2)
                        .clamp(0.0, _strip.position.maxScrollExtent);
                if ((_strip.offset - offset).abs() > AppDimensions.scrollTolerance) {
                  _strip.animateTo(
                    offset,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                  );
                }
              }
            });
            return Column(
              children: [
                if (_opening) const LinearProgressIndicator(),
                if (_unavailable)
                  MaterialBanner(
                    content: Text(context.l10n.candleUnavailable),
                    actions: [
                      TextButton(onPressed: _open, child: Text(context.l10n.retry)),
                      TextButton(
                        onPressed: () {
                          setState(() => _unavailable = false);
                          _select(data.selectedId);
                        },
                        child: Text(context.l10n.dismiss),
                      ),
                    ],
                  ),
                if (data.warning != null) Text(context.l10n.failure(data.warning!)),
                Expanded(
                  child: PageView.builder(
                    controller: _pages,
                    itemCount: candles.length + 1,
                    onPageChanged: (index) {
                      if (!_syncing && index != selectedIndex) {
                        _select(index == 0 ? null : candles[index - 1].id);
                      }
                    },
                    itemBuilder: (_, index) => CandleScreen(
                      key: ValueKey(index == 0 ? "draft" : candles[index - 1].id),
                      candleId: index == 0 ? null : candles[index - 1].id,
                    ),
                  ),
                ),
                const SizedBox(height: Sizes.small),
                SizedBox(
                  height: AppDimensions.candleGallery,
                  child: Center(
                    child: ListView.builder(
                      shrinkWrap: true,
                      controller: _strip,
                      scrollDirection: Axis.horizontal,
                      itemCount: candles.length + 1,
                      itemBuilder: (_, index) {
                        final candle = index == 0 ? null : candles[index - 1];
                        final group = index == 0
                            ? context.l10n.newGroup
                            : index <= data.mine.length
                            ? context.l10n.mineGroup
                            : context.l10n.recentGroup;
                        return CandleThumbnail(
                          candle: candle,
                          group: group,
                          selected: index == selectedIndex,
                          onTap: () => _select(candle?.id),
                          onClose: candle != null && index > data.mine.length
                              ? () => _closeRecent(candle.id)
                              : null,
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
