import "package:candle_frontend/core/constants/sizes.dart";
import "package:candle_frontend/core/constants/app_colors.dart";
import "dart:typed_data";
import "package:flutter/material.dart";
import "/core/config/app_config.dart";
import "../../../../resources/domain/media_resource.dart";

class CandleBackdrop extends StatelessWidget {
  const CandleBackdrop({super.key, this.resource, this.preview, this.thumbnail = false});

  final MediaResource? resource;
  final Uint8List? preview;
  final bool thumbnail;

  @override
  Widget build(BuildContext context) {
    final path = thumbnail ? resource?.thumbnailUrl : resource?.url;
    final url = path == null ? null : Uri.parse(AppConfig.apiBaseUrl).resolve(path).toString();
    final image = preview != null
        ? Image.memory(
            preview!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          )
        : url == null
        ? null
        : Image.network(
            url,
            fit: BoxFit.cover,
            frameBuilder: (_, child, frame, synchronous) => AnimatedOpacity(
              opacity: synchronous || frame != null ? 1 : 0,
              duration: const Duration(milliseconds: 350),
              child: child,
            ),
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          );

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, AppEffects.backdropCenterY),
                radius: AppEffects.backdropRadius,
                colors: [AppColors.candleAmbient, AppColors.surface],
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: SizedBox.expand(key: ValueKey(preview ?? path), child: image),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: thumbnail
                    ? const [
                        AppColors.thumbnailScrimTop,
                        AppColors.thumbnailScrimCenter,
                        AppColors.thumbnailScrimBottom,
                      ]
                    : const [
                        AppColors.sceneScrimTop,
                        AppColors.sceneScrimCenter,
                        AppColors.sceneScrimLower,
                        AppColors.surface,
                      ],
                stops: thumbnail ? AppEffects.thumbnailStops : AppEffects.sceneStops,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
