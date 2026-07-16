import 'package:file_picker/file_picker.dart';

import 'package:flutter/material.dart';

import 'package:netdrop/config/netdrop_theme_ext.dart';

import 'package:netdrop/model/cross_file.dart';

import 'package:netdrop/model/device.dart';

import 'package:netdrop/network/multicast_service.dart';

import 'package:netdrop/pages/progress_page.dart';

import 'package:netdrop/provider/local_ip_provider.dart';

import 'package:netdrop/provider/network/nearby_devices_provider.dart';

import 'package:netdrop/provider/settings_provider.dart';

import 'package:netdrop/util/media_picker.dart';
import 'package:netdrop/util/platform_file_mapper.dart';
import 'package:netdrop/provider/local_device_info_provider.dart';

import 'package:netdrop/widget/design/empty_state.dart';

import 'package:netdrop/widget/design/file_category_grid.dart';

import 'package:netdrop/widget/design/selected_files_panel.dart';

import 'package:netdrop/widget/design/server_status_banner.dart';
import 'package:netdrop/widget/design/section_header.dart';

import 'package:netdrop/widget/design/this_device_card.dart';

import 'package:netdrop/widget/device_list_tile.dart';

import 'package:netdrop/widget/dialogs/message_dialog.dart';

import 'package:netdrop/widget/responsive_builder.dart';

import 'package:refena_flutter/refena_flutter.dart';

import 'package:routerino/routerino.dart';

import 'package:uuid/uuid.dart';



class SendTab extends StatelessWidget {

  const SendTab({super.key});



  @override

  Widget build(BuildContext context) {

    final devices = context.watch(nearbyDevicesProvider);

    final settings = context.watch(settingsProvider);

    final localFingerprint = settings.fingerprint;

    final nearbyDevices = devices.deviceListExcluding(localFingerprint);

    final selectedFiles = context.watch(selectedFilesProvider);

    final deviceType = context.watch(deviceTypeProvider);

    final osLabel = context.watch(localDeviceInfoProvider).osLabel;



    return ResponsiveListView(

      children: [

        FutureBuilder<List<String>>(

          future: context.read(localIpProvider).getLocalIps(),

          builder: (context, snapshot) {

            return ThisDeviceCard(

              alias: settings.alias,

              deviceType: deviceType,

              osLabel: osLabel,

              ipAddress: snapshot.data?.firstOrNull,

            );

          },

        ),

        const SizedBox(height: 24),

        SectionHeader(

          title: 'Nearby devices',

          trailing: FilledButton.tonalIcon(

            onPressed: devices.scanning

                ? null

                : () => context.global.dispatchAsync(StartDiscoveryAction()),

            icon: devices.scanning

                ? const SizedBox(

                    width: 16,

                    height: 16,

                    child: CircularProgressIndicator(strokeWidth: 2),

                  )

                : const Icon(Icons.refresh, size: 18),

            label: Text(devices.scanning ? 'Scanning…' : 'Refresh'),

            style: FilledButton.styleFrom(

              backgroundColor: context.nd.surfaceMuted,

              foregroundColor: context.cs.primary,

              minimumSize: const Size(0, 40),

              padding: const EdgeInsets.symmetric(horizontal: 14),

              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

            ),

          ),

        ),

        const SizedBox(height: 12),

        if (nearbyDevices.isEmpty)

          EmptyState(

            icon: Icons.wifi_tethering,

            title: 'No devices found',

            subtitle: 'Make sure both devices are on the same Wi‑Fi network, then tap Refresh.',

            action: FilledButton.icon(

              onPressed: devices.scanning

                  ? null

                  : () => context.global.dispatchAsync(StartDiscoveryAction()),

              icon: const Icon(Icons.refresh),

              label: const Text('Refresh'),

            ),

          )

        else

          ...nearbyDevices.map(

            (device) => Padding(

              padding: const EdgeInsets.only(bottom: 10),

              child: DeviceListTile(

                device: device,

                onTap: () => _showSendSheet(context, device),

              ),

            ),

          ),

        const SizedBox(height: 24),

        SectionHeader(title: 'Quick send'),

        const SizedBox(height: 12),

        const ServerStatusBanner(),

        if (selectedFiles.isNotEmpty) ...[
          SelectedFilesPanel(
            files: selectedFiles,
            onRemove: (id) => context.notifier(selectedFilesProvider).removeFile(id),
            onClearAll: () => context.notifier(selectedFilesProvider).clear(),
          ),
          const SizedBox(height: 12),
        ],

        FileCategoryGrid(onCategoryTap: (category) => _pickFiles(context, category)),

        const SizedBox(height: 12),

        OutlinedButton.icon(

          onPressed: () => _addMessage(context),

          icon: const Icon(Icons.message_outlined),

          label: const Text('Add text message'),

        ),

      ],

    );

  }



  Future<void> _showSendSheet(BuildContext context, Device device) async {

    final files = context.read(selectedFilesProvider);

    if (files.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(content: Text('Select files or a message first')),

      );

      return;

    }



    await context.push(() => ProgressPage(device: device, files: files));

  }



  Future<void> _pickFiles(BuildContext context, FilePickCategory category) async {
    final List<CrossFile> files;

    if (category == FilePickCategory.images) {
      files = await pickMultipleImages();
    } else {
      final result = await FilePicker.pickFiles(
        type: category.pickerType,
        allowedExtensions: category.allowedExtensions,
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      files = await crossFilesFromPickerResult(
        result: result,
        fallbackMime: category.fallbackMime,
      );
    }

    if (!context.mounted) {
      return;
    }

    if (files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read the selected files. Try again.')),
      );
      return;
    }

    final existing = context.read(selectedFilesProvider);
    context.notifier(selectedFilesProvider).setFiles([...existing, ...files]);

    final addedLabel = files.length == 1 ? '1 file added' : '${files.length} files added';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(addedLabel)),
    );
  }



  Future<void> _addMessage(BuildContext context) async {

    final message = await showMessageDialog(context);

    if (message == null || !context.mounted) {

      return;

    }

    const uuid = Uuid();

    final existing = context.read(selectedFilesProvider);

    context.notifier(selectedFilesProvider).setFiles([

      ...existing,

      CrossFile.text(id: uuid.v4(), message: message),

    ]);

  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}


