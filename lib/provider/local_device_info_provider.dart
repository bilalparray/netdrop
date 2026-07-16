import 'package:netdrop/provider/settings_provider.dart';
import 'package:netdrop/util/device_name.dart';
import 'package:refena/refena.dart';

class LocalDeviceInfo {
  const LocalDeviceInfo({
    required this.modelName,
    required this.osLabel,
  });

  final String modelName;
  final String osLabel;
}

class LocalDeviceInfoService extends Notifier<LocalDeviceInfo> {
  @override
  LocalDeviceInfo init() => const LocalDeviceInfo(
        modelName: 'Unknown',
        osLabel: 'Unknown',
      );

  Future<void> load({required String currentAlias, required bool hasSavedAlias}) async {
    final modelName = await DeviceNameHelper.resolveModelName();
    final osLabel = DeviceNameHelper.resolveOsLabel();

    state = LocalDeviceInfo(
      modelName: modelName,
      osLabel: osLabel,
    );

    if (DeviceNameHelper.shouldAutoSetAlias(currentAlias, hasSavedAlias)) {
      final alias = modelName.isNotEmpty && !DeviceNameHelper.isPlaceholderAlias(modelName)
          ? modelName
          : currentAlias;
      if (alias.isNotEmpty && !DeviceNameHelper.isPlaceholderAlias(alias)) {
        await ref.notifier(settingsProvider).setAlias(alias);
      }
    }
  }
}

final localDeviceInfoProvider = NotifierProvider<LocalDeviceInfoService, LocalDeviceInfo>(
  (ref) => LocalDeviceInfoService(),
);
