import "package:candle_frontend/core/errors/app_failure.dart";
import "dart:typed_data";
import "package:flutter_test/flutter_test.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:image_picker/image_picker.dart";
import "package:candle_frontend/features/candle/application/background_editor_controller.dart";
import "package:candle_frontend/features/candle/application/candle_controller.dart";
import "package:candle_frontend/features/candle/application/candle_state.dart";
import "package:candle_frontend/features/resources/data/image_selection.dart";
import "package:candle_frontend/features/resources/data/dio_resource_repository.dart";
import "package:candle_frontend/features/resources/domain/resource_repository.dart";
import "package:candle_frontend/features/resources/domain/media_resource.dart";
import "package:candle_frontend/features/resources/domain/upload_cancellation.dart";

const resource = MediaResource(id: "r", url: "/r", thumbnailUrl: "/t", width: 100, height: 100);

class Selection extends ImageSelection {
  Selection() : super(ImagePicker());
  @override
  Future<Uint8List?> pick() async => Uint8List.fromList([1, 2, 3]);
}

class Uploads implements ResourceRepository {
  int count = 0;
  @override
  Future<MediaResource> uploadImage(
    Uint8List bytes, {
    required void Function(double) onProgress,
    required UploadCancellation cancellation,
  }) async {
    count++;
    onProgress(1);
    return resource;
  }
}

class Draft extends CandleController {
  bool fail = true;
  MediaResource? saved;
  @override
  Future<CandleState> build(int? candleId) async => const CandleState(candle: null);
  @override
  Future<void> setBackground(MediaResource? resource) async {
    if (fail) throw AppFailure.backgroundSaveFailed;
    saved = resource;
    state = AsyncData(CandleState(candle: null, draftBackground: resource));
  }
}

void main() {
  test("retrying attachment reuses uploaded resource; removal saves null", () async {
    final draft = Draft();
    final uploads = Uploads();
    final container = ProviderContainer(
      overrides: [
        candleControllerProvider(null).overrideWith(() => draft),
        resourceRepositoryProvider.overrideWithValue(uploads),
        imageSelectionProvider.overrideWithValue(Selection()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(candleControllerProvider(null).future);
    final provider = backgroundEditorControllerProvider(null);
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    final controller = container.read(provider.notifier);
    await controller.pick();
    expect(container.read(provider).preview, isNotNull);
    await controller.save();
    expect(container.read(provider).error, AppFailure.backgroundSaveFailed);
    draft.fail = false;
    await controller.save();
    expect(uploads.count, 1);
    expect(draft.saved, resource);
    controller.remove();
    await controller.save();
    expect(draft.saved, isNull);
    expect(uploads.count, 1);
  });
}
