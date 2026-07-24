import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:netdrop/config/constants.dart';
import 'package:netdrop/model/stored_security_context.dart';
import 'package:netdrop/network/device_connect.dart';
import 'package:netdrop/network/multicast_service.dart';
import 'package:netdrop/provider/network/server_provider.dart';
import 'package:netdrop/provider/local_device_info_provider.dart';
import 'package:netdrop/provider/persistence_provider.dart';
import 'package:netdrop/provider/settings_provider.dart';
import 'package:netdrop/provider/security_provider.dart';
import 'package:netdrop/util/security_helper.dart';
import 'package:netdrop/util/share_intent_service.dart';
import 'package:refena/refena.dart';

final _logger = Logger('Init');

Future<RefenaContainer> preInit() async {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('[${record.loggerName}] ${record.message}');
    if (record.error != null) {
      // ignore: avoid_print
      print('[${record.loggerName}] ${record.error}');
    }
  });

  final persistence = await PersistenceService.initialize();
  var security = persistence.loadSecurityContext();
  if (security == null) {
    security = SecurityHelper.generate();
    await persistence.saveSecurityContext(security);
  }

  final securityService = _BootstrapSecurityService(security);

  return RefenaContainer(
    overrides: [
      persistenceProvider.overrideWithValue(persistence),
      securityProvider.overrideWithNotifier((_) => securityService),
    ],
  );
}

Future<void> postInit(Ref ref) async {
  if (kIsWeb) {
    _logger.info(
      '$appDisplayName started (web preview — LAN transfer unavailable)',
    );
    return;
  }

  final persistence = ref.read(persistenceProvider);
  final settings = ref.read(settingsProvider);
  await ref
      .notifier(localDeviceInfoProvider)
      .load(
        currentAlias: settings.alias,
        hasSavedAlias: persistence.hasSavedAlias,
      );

  final server = ref.notifier(serverProvider);
  await server.startServer(scanAlternatePorts: true);
  await reconnectManualDevices(ref);
  await initializeShareIntent(ref);
  await ref.global.dispatchAsync(StartDiscoveryAction());
  _logger.info('$appDisplayName started');
}

class _BootstrapSecurityService extends SecurityService {
  _BootstrapSecurityService(this._context);

  final StoredSecurityContext _context;

  @override
  StoredSecurityContext init() => _context;
}
