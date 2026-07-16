import 'dart:io';

import 'package:downloadsfolder/downloadsfolder.dart';
import 'package:flutter/services.dart';
import 'package:netdrop/util/file_category.dart';
import 'package:path_provider/path_provider.dart';
import 'package:refena/refena.dart';

const netDropFolderName = 'NetDrop';
const _androidReceiveChannel = MethodChannel('com.qayham.netdrop/receive');

class ReceiveSaveLocation {
  const ReceiveSaveLocation({required this.label, required this.path});

  final String label;
  final String path;
}

class FileSaver {
  Future<String> getReceiveDirectory() async {
    final baseDir = await _getBaseDownloadDirectory();
    final receiveDir = Directory(
      '${baseDir.path}${Platform.pathSeparator}$netDropFolderName',
    );
    if (!await receiveDir.exists()) {
      await receiveDir.create(recursive: true);
    }
    return receiveDir.path;
  }

  /// Human-readable save locations shown in Settings and Receive tab.
  Future<List<ReceiveSaveLocation>> getReceiveSaveLocations() async {
    if (Platform.isAndroid && await _androidSdkVersion >= 29) {
      return const [
        ReceiveSaveLocation(label: 'Photos & images', path: 'Pictures/NetDrop'),
        ReceiveSaveLocation(label: 'Videos', path: 'Movies/NetDrop'),
        ReceiveSaveLocation(label: 'Music & audio', path: 'Music/NetDrop'),
        ReceiveSaveLocation(
          label: 'Documents & other',
          path: 'Download/NetDrop',
        ),
      ];
    }

    final base = await getReceiveDirectory();
    return [ReceiveSaveLocation(label: 'All received files', path: base)];
  }

  Future<String> getCategoryDirectory(String fileName, String fileType) async {
    final category = netDropCategoryFor(fileName, fileType);
    final baseDir = await getReceiveDirectory();
    final categoryDir = Directory('$baseDir${Platform.pathSeparator}$category');
    if (!await categoryDir.exists()) {
      await categoryDir.create(recursive: true);
    }
    return categoryDir.path;
  }

  Future<String> saveStream({
    required Stream<List<int>> stream,
    required String fileName,
    String fileType = 'application/octet-stream',
    void Function(double progress)? onProgress,
    int? totalBytes,
  }) async {
    final safeName = _sanitizeFileName(fileName);
    final category = netDropCategoryFor(safeName, fileType);
    final mimeType = resolveMimeType(safeName, fileType);
    final uniqueName = await _resolveUniqueName(safeName, category);

    if (Platform.isAndroid && await _androidSdkVersion >= 29) {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}${Platform.pathSeparator}$uniqueName',
      );
      await _writeStream(
        stream: stream,
        file: tempFile,
        onProgress: onProgress,
        totalBytes: totalBytes,
      );

      try {
        final result = await _androidReceiveChannel
            .invokeMethod<dynamic>('saveToNetDrop', {
              'filePath': tempFile.path,
              'fileName': uniqueName,
              'subfolder': category,
              'mimeType': mimeType,
            });
        final savedUri = _readSavedLocation(result);
        if (savedUri != null && savedUri.isNotEmpty) {
          return savedUri;
        }
      } on PlatformException {
        // MediaStore may reject some paths; fall back to direct file write below.
      } finally {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }

      final directory = await getCategoryDirectory(safeName, fileType);
      return '$directory${Platform.pathSeparator}$uniqueName';
    }

    final directory = await getCategoryDirectory(safeName, fileType);
    final file = File('$directory${Platform.pathSeparator}$uniqueName');
    await _writeStream(
      stream: stream,
      file: file,
      onProgress: onProgress,
      totalBytes: totalBytes,
    );
    return file.path;
  }

  Future<Directory> _getBaseDownloadDirectory() async {
    if (Platform.isAndroid ||
        Platform.isWindows ||
        Platform.isMacOS ||
        Platform.isLinux) {
      return getDownloadDirectory();
    }
    return getApplicationDocumentsDirectory();
  }

  Future<int> get _androidSdkVersion async {
    if (!Platform.isAndroid) {
      return 0;
    }
    final version = await const MethodChannel(
      'downloadsfolder',
    ).invokeMethod<int>('getCurrentSdkVersion');
    return version ?? 0;
  }

  Future<String> _resolveUniqueName(String fileName, String category) async {
    final baseDir = await getReceiveDirectory();
    final directory = '$baseDir${Platform.pathSeparator}$category';
    var candidate = fileName;
    var copyNumber = 1;
    final extensionIndex = fileName.lastIndexOf('.');
    final hasExtension = extensionIndex > 0;
    final baseName = hasExtension
        ? fileName.substring(0, extensionIndex)
        : fileName;
    final extension = hasExtension ? fileName.substring(extensionIndex) : '';

    while (await File(
      '$directory${Platform.pathSeparator}$candidate',
    ).exists()) {
      candidate = hasExtension
          ? '${baseName}_($copyNumber)$extension'
          : '${baseName}_($copyNumber)';
      copyNumber++;
    }
    return candidate;
  }

  String _sanitizeFileName(String fileName) {
    final sanitized = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
    return sanitized.isEmpty ? 'received_file' : sanitized;
  }

  String? _readSavedLocation(dynamic result) {
    if (result is String && result.isNotEmpty) {
      return result;
    }
    if (result == true) {
      return null;
    }
    return null;
  }

  Future<void> _writeStream({
    required Stream<List<int>> stream,
    required File file,
    void Function(double progress)? onProgress,
    int? totalBytes,
  }) async {
    final sink = file.openWrite();
    var received = 0;

    await for (final chunk in stream) {
      sink.add(chunk);
      received += chunk.length;
      if (totalBytes != null && totalBytes > 0) {
        onProgress?.call(received / totalBytes);
      }
    }

    await sink.close();
  }
}

final fileSaverProvider = Provider<FileSaver>((ref) => FileSaver());
