import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:netdrop/config/constants.dart';
import 'package:netdrop/model/cross_file.dart';
import 'package:netdrop/network/upload_queue.dart';
import 'package:netdrop/util/file_category.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Converts a [PlatformFile] from the picker into a [CrossFile] ready to send.
Future<CrossFile?> crossFileFromPlatformFile({
  required PlatformFile picked,
  required String fallbackMime,
  required Uuid uuid,
}) async {
  var fileType = resolveMimeType(picked.name, picked.extension);
  if (fileType == 'application/octet-stream') {
    fileType = fallbackMime;
  }

  final path = picked.path;
  if (path != null && path.isNotEmpty) {
    final file = File(path);
    if (await file.exists()) {
      return CrossFile(
        id: uuid.v4(),
        fileName: picked.name,
        path: path,
        size: picked.size > 0 ? picked.size : await file.length(),
        fileType: fileType,
      );
    }
  }

  List<int>? bytes = picked.bytes;
  if (bytes == null && picked.readStream != null) {
    bytes = await picked.readStream!.fold<List<int>>([], (previous, chunk) {
      previous.addAll(chunk);
      return previous;
    });
  }

  if (bytes == null || bytes.isEmpty) {
    return null;
  }

  final dir = await getTemporaryDirectory();
  final safeName = picked.name.trim().isEmpty ? 'file' : picked.name.trim();
  final destPath = p.join(dir.path, '${uuid.v4()}_$safeName');
  await File(destPath).writeAsBytes(bytes, flush: true);

  return CrossFile(
    id: uuid.v4(),
    fileName: safeName,
    path: destPath,
    size: bytes.length,
    fileType: fileType,
  );
}

Future<List<CrossFile>> crossFilesFromPickerResult({
  required FilePickerResult result,
  required String fallbackMime,
}) async {
  const uuid = Uuid();
  final picked = result.files;
  if (picked.isEmpty) {
    return const [];
  }

  final slots = List<CrossFile?>.filled(picked.length, null);
  await runWithConcurrency<int>(
    items: List.generate(picked.length, (index) => index),
    maxConcurrent: filePrepConcurrency,
    worker: (index) async {
      slots[index] = await crossFileFromPlatformFile(
        picked: picked[index],
        fallbackMime: fallbackMime,
        uuid: uuid,
      );
    },
  );

  return [for (final file in slots) if (file != null) file];
}
