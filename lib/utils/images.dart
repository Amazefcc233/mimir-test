import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:path/path.dart' as path;

Future<void> copyCompressedImageToTarget({
  required File source,
  required String target,
  bool compressGif = false,
}) async {
  if (source.path == target) return;
  final supportCompress = UniversalPlatform.isAndroid || UniversalPlatform.isIOS || UniversalPlatform.isMacOS;
  if (!supportCompress) {
    await source.copy(target);
    return;
  }
  final isGif = path.extension(source.path).toLowerCase() == ".gif";
  if (!isGif || compressGif) {
    FlutterImageCompress.validator.ignoreCheckExtName = true;
    await FlutterImageCompress.compressAndGetFile(
      source.path,
      target,
      format: UniversalPlatform.isIOS ? CompressFormat.heic : CompressFormat.jpeg,
    );
    return;
  } else {
    await source.copy(target);
  }
}
