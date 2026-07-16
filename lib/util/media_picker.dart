import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:netdrop/model/cross_file.dart';
import 'package:netdrop/util/file_category.dart';
import 'package:netdrop/util/platform_file_mapper.dart';
import 'package:uuid/uuid.dart';

const _imageExtensions = [
  'jpg',
  'jpeg',
  'png',
  'gif',
  'webp',
  'bmp',
  'heic',
  'heif',
];

final _imagePicker = ImagePicker();

/// Picks multiple images using the native photo gallery on mobile.
Future<List<CrossFile>> pickMultipleImages() async {
  if (defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS) {
    return _pickImagesWithImagePicker();
  }
  return _pickImagesWithFilePicker();
}

Future<List<CrossFile>> _pickImagesWithImagePicker() async {
  final picked = await _imagePicker.pickMultiImage(imageQuality: 100);
  if (picked.isEmpty) {
    return [];
  }

  const uuid = Uuid();
  final files = <CrossFile>[];

  for (final xFile in picked) {
    final path = xFile.path;
    if (path.isEmpty) {
      continue;
    }

    final file = File(path);
    if (!await file.exists()) {
      continue;
    }

    var fileType = resolveMimeType(xFile.name, xFile.mimeType);
    if (fileType == 'application/octet-stream') {
      fileType = 'image/jpeg';
    }

    files.add(
      CrossFile(
        id: uuid.v4(),
        fileName: xFile.name,
        path: path,
        size: await file.length(),
        fileType: fileType,
      ),
    );
  }

  return files;
}

Future<List<CrossFile>> _pickImagesWithFilePicker() async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: _imageExtensions,
    allowMultiple: true,
  );

  if (result == null || result.files.isEmpty) {
    return [];
  }

  return crossFilesFromPickerResult(
    result: result,
    fallbackMime: 'image/jpeg',
  );
}
