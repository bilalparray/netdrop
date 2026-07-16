import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:netdrop/config/constants.dart';
import 'package:netdrop/model/cross_file.dart';
import 'package:netdrop/model/device.dart';
import 'package:netdrop/model/dto/file_dto.dart';
import 'package:netdrop/model/dto/register_dto.dart';
import 'package:netdrop/model/stored_security_context.dart';
import 'package:netdrop/provider/security_provider.dart';
import 'package:netdrop/util/http_client_factory.dart';
import 'package:refena/refena.dart';
import 'package:uuid/uuid.dart';

class SessionCancelledException implements Exception {
  @override
  String toString() => 'Transfer cancelled';
}

class TransferClient {
  TransferClient(this._securityContext);

  final StoredSecurityContext? Function() _securityContext;
  HttpClient? _activePrepareClient;

  void abortPrepareUpload() {
    _activePrepareClient?.close(force: true);
    _activePrepareClient = null;
  }

  Future<PrepareUploadResponseDto> prepareUpload({
    required Device target,
    required RegisterDto sender,
    required List<CrossFile> files,
  }) async {
    final client = _createClient(target.https);
    _activePrepareClient = client;
    client.connectionTimeout = const Duration(seconds: 30);
    final uri = Uri.parse('${target.baseUrl}$apiBasePath/prepare-upload');
    try {
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;

      final fileMap = {
        for (final file in files)
          file.id: FileDto(
            id: file.id,
            fileName: file.fileName,
            size: file.size,
            fileType: file.fileType,
          ),
      };

      final body = {
        'info': sender.toJson(),
        'files': fileMap.map((key, value) => MapEntry(key, value.toJson())),
      };
      request.write(jsonEncode(body));
      final response = await request.close();
      final responseBody = await response.transform(const Utf8Decoder()).join();

      if (response.statusCode != 200) {
        client.close(force: true);
        throw HttpException(
          'Prepare upload failed (${response.statusCode}): $responseBody',
          uri: uri,
        );
      }

      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      client.close(force: true);
      return PrepareUploadResponseDto(
        sessionId: json['sessionId'] as String,
        files: Map<String, String>.from(json['files'] as Map),
      );
    } on SessionCancelledException {
      rethrow;
    } catch (error) {
      client.close(force: true);
      if (_activePrepareClient == null) {
        throw SessionCancelledException();
      }
      rethrow;
    } finally {
      if (identical(_activePrepareClient, client)) {
        _activePrepareClient = null;
      }
    }
  }

  Future<void> uploadFile({
    required Device target,
    required String sessionId,
    required CrossFile file,
    required String token,
    void Function(double progress)? onProgress,
    bool Function()? shouldCancel,
  }) async {
    final client = _createClient(target.https);
    final uri = Uri.parse(
      '${target.baseUrl}$apiBasePath/upload?sessionId=$sessionId&fileId=${file.id}&token=$token',
    );
    final request = await client.postUrl(uri);
    request.headers.contentType = ContentType('application', 'octet-stream');
    request.contentLength = file.size;

    final source = _openStream(file);
    var sent = 0;
    await for (final chunk in source) {
      if (shouldCancel?.call() ?? false) {
        client.close(force: true);
        throw SessionCancelledException();
      }
      request.add(chunk);
      sent += chunk.length;
      if (file.size > 0) {
        onProgress?.call(sent / file.size);
      }
    }

    final response = await request.close();
    if (response.statusCode != 200) {
      final body = await response.transform(const Utf8Decoder()).join();
      client.close(force: true);
      throw HttpException(
        'Upload failed (${response.statusCode}): $body',
        uri: uri,
      );
    }
    client.close(force: true);
  }

  Future<void> cancelSession({
    required Device target,
    String? sessionId,
    String? senderFingerprint,
  }) async {
    if (sessionId == null && senderFingerprint == null) {
      return;
    }

    final query = sessionId != null
        ? 'sessionId=${Uri.encodeComponent(sessionId)}'
        : 'fingerprint=${Uri.encodeComponent(senderFingerprint!)}';
    final client = _createClient(target.https);
    final uri = Uri.parse('${target.baseUrl}$apiBasePath/cancel?$query');
    final request = await client.postUrl(uri);
    await request.close();
    client.close(force: true);
  }

  HttpClient _createClient(bool useTls) {
    if (useTls && _securityContext() == null) {
      throw StateError('HTTPS is enabled but no security context is available');
    }
    return createHttpClient(https: useTls, security: _securityContext());
  }

  Stream<List<int>> _openStream(CrossFile file) {
    if (file.bytes != null) {
      return _chunkBytes(Uint8List.fromList(file.bytes!));
    }
    if (file.path == null) {
      throw StateError('File has no path or bytes: ${file.fileName}');
    }
    return File(file.path!).openRead();
  }

  Stream<List<int>> _chunkBytes(
    Uint8List bytes, {
    int chunkSize = 64 * 1024,
  }) async* {
    for (var offset = 0; offset < bytes.length; offset += chunkSize) {
      final end = (offset + chunkSize > bytes.length)
          ? bytes.length
          : offset + chunkSize;
      yield bytes.sublist(offset, end);
    }
  }
}

final transferClientProvider = Provider<TransferClient>((ref) {
  return TransferClient(() => ref.read(securityProvider));
});

Map<String, String> createFileTokens(Map<String, FileDto> files) {
  const uuid = Uuid();
  return {for (final entry in files.entries) entry.key: uuid.v4()};
}
