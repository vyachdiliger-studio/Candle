import "package:candle_frontend/core/errors/app_failure.dart";
import "dart:typed_data";

import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:image_picker/image_picker.dart";

part "image_selection.g.dart";

@riverpod
ImageSelection imageSelection(Ref ref) => ImageSelection(ImagePicker());

class ImageSelection {
  ImageSelection(this.picker);

  /// The server downsizes backgrounds to this, so larger originals only slow
  /// the upload down.
  static const _maxSide = 2560.0;

  final ImagePicker picker;

  Future<Uint8List?> pick() async {
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: _maxSide,
      maxHeight: _maxSide,
      imageQuality: 85,
    );
    if (file == null) return null;
    if (await file.length() > 20 * 1024 * 1024) {
      throw AppFailure.imageTooLarge;
    }
    final bytes = await file.readAsBytes();
    final jpeg = bytes.length >= 3 && bytes[0] == 255 && bytes[1] == 216 && bytes[2] == 255;
    final png =
        bytes.length >= 8 && bytes[0] == 137 && String.fromCharCodes(bytes.sublist(1, 4)) == "PNG";
    final webp =
        bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == "RIFF" &&
        String.fromCharCodes(bytes.sublist(8, 12)) == "WEBP";
    if (!jpeg && !png && !webp) throw AppFailure.unsupportedImage;
    return bytes;
  }
}
