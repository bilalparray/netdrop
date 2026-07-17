import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:netdrop/config/constants.dart';
import 'package:netdrop/model/cross_file.dart';
import 'package:netdrop/model/device.dart';
import 'package:netdrop/model/dto/register_dto.dart';
import 'package:netdrop/network/transfer_client.dart';
import 'package:netdrop/network/upload_queue.dart';
import 'package:netdrop/util/simple_server.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('file transfer flow', () {
    late HttpServer server;
    late int port;
    const sessionId = 'test-session';
    final tokens = <String, String>{};
    final uploadedBytes = <String, List<int>>{};

    setUp(() async {
      tokens.clear();
      uploadedBytes.clear();

      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      port = server.port;

      server.listen((request) async {
        final path = request.uri.path;
        if (request.method == 'POST' && path == '$apiBasePath/prepare-upload') {
          final body = jsonDecode(await SimpleServer.readBody(request)) as Map<String, dynamic>;
          final files = body['files'] as Map<String, dynamic>;
          const uuid = Uuid();
          final responseTokens = {
            for (final id in files.keys) id: uuid.v4(),
          };
          tokens.addAll(responseTokens);
          await SimpleServer.writeJson(request, HttpStatus.ok, {
            'sessionId': sessionId,
            'files': responseTokens,
          });
          return;
        }

        if (request.method == 'POST' && path == '$apiBasePath/upload') {
          final token = request.uri.queryParameters['token'];
          final fileId = request.uri.queryParameters['fileId'];
          if (token == null || fileId == null || tokens[fileId] != token) {
            await SimpleServer.writeJson(request, HttpStatus.forbidden, {'message': 'Invalid token'});
            return;
          }

          final bytes = await request.fold<List<int>>(<int>[], (prev, chunk) => prev..addAll(chunk));
          uploadedBytes[fileId] = bytes;
          await SimpleServer.writeEmpty(request, HttpStatus.ok);
          return;
        }

        await SimpleServer.writeJson(request, HttpStatus.notFound, {'message': 'Not found'});
      });
    });

    tearDown(() async {
      await server.close(force: true);
    });

    test('openUploadSession then upload sends file bytes', () async {
      const fileId = 'file-1';
      const payload = 'hello netdrop transfer test';
      final file = CrossFile.text(id: fileId, message: payload);

      final client = TransferClient(() => null);
      final target = Device(
        ip: InternetAddress.loopbackIPv4.address,
        port: port,
        fingerprint: 'receiver-fp',
        alias: 'Receiver',
        version: protocolVersion,
        https: false,
      );
      const sender = RegisterDto(
        alias: 'Sender',
        version: protocolVersion,
        fingerprint: 'sender-fp',
        port: 53317,
        protocol: 'http',
        deviceType: DeviceType.mobile,
        deviceModel: 'Test Phone',
      );

      final session = await client.openUploadSession(
        target: target,
        sender: sender,
        files: [file],
      );

      expect(session.sessionId, sessionId);
      expect(session.files[fileId], isNotNull);

      var progressCalls = 0;
      await session.uploadFile(
        file: file,
        token: session.files[fileId]!,
        onProgress: (_) => progressCalls++,
      );
      await session.close();

      expect(uploadedBytes[fileId], utf8.encode(payload));
      expect(progressCalls, greaterThan(0));
    });

    test('upload session reuses connection for concurrent uploads', () async {
      final files = List.generate(
        4,
        (index) => CrossFile.text(
          id: 'file-$index',
          message: 'payload-$index',
        ),
      );

      final client = TransferClient(() => null);
      final target = Device(
        ip: InternetAddress.loopbackIPv4.address,
        port: port,
        fingerprint: 'receiver-fp',
        alias: 'Receiver',
        version: protocolVersion,
        https: false,
      );
      const sender = RegisterDto(
        alias: 'Sender',
        version: protocolVersion,
        fingerprint: 'sender-fp',
        port: 53317,
        protocol: 'http',
        deviceType: DeviceType.mobile,
        deviceModel: 'Test Phone',
      );

      final session = await client.openUploadSession(
        target: target,
        sender: sender,
        files: files,
      );

      try {
        await runWithConcurrency<CrossFile>(
          items: files,
          maxConcurrent: uploadConcurrency,
          worker: (file) async {
            final token = session.files[file.id];
            expect(token, isNotNull);
            await session.uploadFile(file: file, token: token!);
          },
        );
      } finally {
        await session.close();
      }

      for (final file in files) {
        expect(uploadedBytes[file.id], utf8.encode('payload-${file.id.split('-').last}'));
      }
    });
  });
}
