import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:netdrop/util/file_category.dart';
import 'package:netdrop/util/user_messages.dart';
import 'package:open_filex/open_filex.dart';

const _androidReceiveChannel = MethodChannel('com.qayham.netdrop/receive');

class OpenFileResult {
  const OpenFileResult({required this.success, this.message});

  final bool success;
  final String? message;
}

Future<OpenFileResult> openReceivedFile({
  required String? location,
  required String fileName,
  required String fileType,
}) async {
  if (location == null || location.isEmpty) {
    return const OpenFileResult(
      success: false,
      message: 'File location is not available',
    );
  }

  if (kIsWeb) {
    return const OpenFileResult(
      success: false,
      message: 'Opening files is not supported in the browser yet',
    );
  }

  if (Platform.isAndroid && location.startsWith('content://')) {
    try {
      await _androidReceiveChannel.invokeMethod<void>('openFile', {
        'uri': location,
        'mimeType': resolveMimeType(fileName, fileType),
      });
      return const OpenFileResult(success: true);
    } on PlatformException catch (error) {
      return OpenFileResult(
        success: false,
        message: friendlyOpenFileMessage(error),
      );
    }
  }

  if (!File(location).existsSync()) {
    return const OpenFileResult(
      success: false,
      message: 'This file is no longer available on your device.',
    );
  }

  final result = await OpenFilex.open(
    location,
    type: _openTypeForMime(resolveMimeType(fileName, fileType)),
  );

  return OpenFileResult(
    success: result.type == ResultType.done,
    message: result.type == ResultType.done
        ? null
        : friendlyOpenFileMessage(result.message),
  );
}

String _openTypeForMime(String mimeType) {
  if (mimeType.startsWith('image/')) {
    return 'image';
  }
  if (mimeType.startsWith('video/')) {
    return 'video';
  }
  if (mimeType.startsWith('audio/')) {
    return 'audio';
  }
  return 'file';
}

bool canOpenReceivedFile(String? location) {
  return location != null && location.isNotEmpty;
}
