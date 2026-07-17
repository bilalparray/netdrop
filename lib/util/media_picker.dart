import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:netdrop/config/constants.dart';
import 'package:netdrop/model/cross_file.dart';
import 'package:netdrop/network/upload_queue.dart';
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

bool get _usesNativeGallery =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

bool get usesNativeImageGallery => _usesNativeGallery;

/// Opens the system photo gallery on mobile (returns before file prep).
Future<List<XFile>> pickImagesFromGallery() async {
  if (!_usesNativeGallery) {
    return const [];
  }
  return _imagePicker.pickMultiImage(imageQuality: 100);
}

/// Opens the file picker for images on desktop.
Future<FilePickerResult?> pickImagesFromFilePicker() {
  return FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: _imageExtensions,
    allowMultiple: true,
  );
}

/// Converts gallery [XFile] picks into send-ready [CrossFile]s.
Future<List<CrossFile>> crossFilesFromImagePicks(List<XFile> picked) async {
  if (picked.isEmpty) {
    return const [];
  }

  const uuid = Uuid();
  final slots = List<CrossFile?>.filled(picked.length, null);

  await runWithConcurrency<int>(
    items: List.generate(picked.length, (index) => index),
    maxConcurrent: filePrepConcurrency,
    worker: (index) async {
      slots[index] = await _crossFileFromXFile(picked[index], uuid);
    },
  );

  return [for (final file in slots) if (file != null) file];
}

Future<CrossFile?> _crossFileFromXFile(XFile xFile, Uuid uuid) async {
  final path = xFile.path;
  if (path.isEmpty) {
    return null;
  }

  final file = File(path);
  if (!await file.exists()) {
    return null;
  }

  var fileType = resolveMimeType(xFile.name, xFile.mimeType);
  if (fileType == 'application/octet-stream') {
    fileType = 'image/jpeg';
  }

  return CrossFile(
    id: uuid.v4(),
    fileName: xFile.name,
    path: path,
    size: await file.length(),
    fileType: fileType,
  );
}

/// Picks multiple images using the native photo gallery on mobile.
Future<List<CrossFile>> pickMultipleImages() async {
  if (_usesNativeGallery) {
    final picked = await pickImagesFromGallery();
    return crossFilesFromImagePicks(picked);
  }

  final result = await pickImagesFromFilePicker();
  if (result == null || result.files.isEmpty) {
    return const [];
  }

  return crossFilesFromPickerResult(
    result: result,
    fallbackMime: 'image/jpeg',
  );
}
