import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:netdrop/model/cross_file.dart';
import 'package:netdrop/provider/home_tab_provider.dart';
import 'package:netdrop/provider/network/nearby_devices_provider.dart';
import 'package:netdrop/util/file_category.dart';
import 'package:refena/refena.dart';
import 'package:uuid/uuid.dart';

const _shareChannel = MethodChannel('com.qayham.netdrop/share');

class SharedFilePayload {
  const SharedFilePayload({
    required this.path,
    required this.name,
    this.mimeType,
    this.size = 0,
  });

  final String path;
  final String name;
  final String? mimeType;
  final int size;

  factory SharedFilePayload.fromMap(Map<dynamic, dynamic> map) {
    return SharedFilePayload(
      path: map['path'] as String,
      name: map['name'] as String,
      mimeType: map['mimeType'] as String?,
      size: map['size'] as int? ?? 0,
    );
  }
}

class ShareIntentService {
  ShareIntentService(this._ref);

  final Ref _ref;
  var _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) {
      return;
    }
    _initialized = true;

    _shareChannel.setMethodCallHandler((call) async {
      if (call.method == 'onShare') {
        final raw = call.arguments;
        if (raw is List) {
          await handleSharedFiles(
            raw
                .whereType<Map>()
                .map((entry) => SharedFilePayload.fromMap(entry))
                .toList(),
          );
        }
      }
    });

    try {
      final initial = await _shareChannel.invokeMethod<List<dynamic>>('getInitialShare');
      if (initial != null && initial.isNotEmpty) {
        await handleSharedFiles(
          initial
              .whereType<Map>()
              .map((entry) => SharedFilePayload.fromMap(entry))
              .toList(),
        );
      }
    } catch (_) {
      // Platform not supported or no pending share.
    }
  }

  Future<void> handleSharedFiles(List<SharedFilePayload> payloads) async {
    if (payloads.isEmpty) {
      return;
    }

    const uuid = Uuid();
    final files = payloads.map((payload) {
      var fileType = resolveMimeType(payload.name, payload.mimeType);
      if (fileType == 'application/octet-stream' && payload.mimeType != null) {
        fileType = payload.mimeType!;
      }
      return CrossFile(
        id: uuid.v4(),
        fileName: payload.name,
        path: payload.path,
        size: payload.size,
        fileType: fileType,
      );
    }).toList();

    final existing = _ref.read(selectedFilesProvider);
    _ref.notifier(selectedFilesProvider).setFiles([...existing, ...files]);
    _ref.notifier(homeTabProvider).select(HomeTab.send);
  }
}

final shareIntentServiceProvider = Provider<ShareIntentService>((ref) {
  return ShareIntentService(ref);
});

Future<void> initializeShareIntent(Ref ref) async {
  await ref.read(shareIntentServiceProvider).initialize();
}
