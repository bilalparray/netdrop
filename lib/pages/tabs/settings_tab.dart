import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:netdrop/config/app_colors.dart';
import 'package:netdrop/config/constants.dart';
import 'package:netdrop/widget/design/netdrop_logo.dart';

import 'package:netdrop/config/netdrop_theme_ext.dart';

import 'package:netdrop/config/theme.dart';

import 'package:netdrop/pages/privacy_policy_page.dart';
import 'package:netdrop/provider/device_preferences_provider.dart';
import 'package:netdrop/provider/network/nearby_devices_provider.dart';
import 'package:netdrop/provider/network/server_provider.dart';

import 'package:netdrop/provider/settings_provider.dart';

import 'package:netdrop/util/file_saver.dart';
import 'package:netdrop/util/store_launcher.dart';

import 'package:netdrop/widget/design/netdrop_card.dart';

import 'package:netdrop/widget/design/section_header.dart';

import 'package:netdrop/widget/responsive_builder.dart';

import 'package:refena_flutter/refena_flutter.dart';



class SettingsTab extends StatefulWidget {

  const SettingsTab({super.key});



  @override

  State<SettingsTab> createState() => _SettingsTabState();

}



class _SettingsTabState extends State<SettingsTab> with Refena {

  final _aliasController = TextEditingController();

  final _portController = TextEditingController();

  var _initialized = false;



  @override

  void dispose() {

    _aliasController.dispose();

    _portController.dispose();

    super.dispose();

  }



  @override

  Widget build(BuildContext context) {

    final settings = context.watch(settingsProvider);



    if (!_initialized) {

      _aliasController.text = settings.alias;

      _portController.text = '${settings.port}';

      _initialized = true;

    }



    return ResponsiveListView(

      children: [

        const SectionHeader(title: 'Settings'),

        const SizedBox(height: 12),

        NetDropCard(

          child: Column(

            children: [

              _SettingsTile(

                icon: Icons.badge_outlined,

                iconColor: NetDropColors.primary,

                title: 'Device name',

                child: TextField(

                  controller: _aliasController,

                  decoration: const InputDecoration(

                    hintText: 'My phone',

                    border: InputBorder.none,

                    filled: false,

                    contentPadding: EdgeInsets.zero,

                  ),

                  onSubmitted: (value) => context.notifier(settingsProvider).setAlias(value),

                ),

              ),

              const Divider(height: 24),

              _SettingsTile(

                icon: Icons.settings_ethernet_outlined,

                iconColor: NetDropColors.iconVideos,

                title: 'Port',

                child: TextField(

                  controller: _portController,

                  keyboardType: TextInputType.number,

                  decoration: const InputDecoration(

                    border: InputBorder.none,

                    filled: false,

                    contentPadding: EdgeInsets.zero,

                  ),

                  onSubmitted: (value) {

                    final port = int.tryParse(value);

                    if (port != null) {

                      context.notifier(settingsProvider).setPort(port);

                    }

                  },

                ),

              ),

              const Divider(height: 24),

              _SettingsTile(

                icon: Icons.lock_outline,

                iconColor: NetDropColors.iconDocuments,

                title: 'Encrypt traffic (HTTPS)',

                subtitle: 'Self-signed TLS certificate on port 53317',

                trailing: Switch(

                  value: settings.https,

                  onChanged: (value) async {

                    final settingsNotifier = context.notifier(settingsProvider);

                    final serverNotifier = context.notifier(serverProvider);

                    await settingsNotifier.setHttps(value);

                    await serverNotifier.stopServer();

                    await serverNotifier.startServer();

                  },

                ),

              ),

            ],

          ),

        ),

        const SizedBox(height: 16),

        const SectionHeader(title: 'Save location'),

        const SizedBox(height: 12),

        const _SaveLocationsCard(),

        const SizedBox(height: 24),

        FilledButton(

          onPressed: () async {

            final settingsNotifier = context.notifier(settingsProvider);

            final serverNotifier = context.notifier(serverProvider);

            await settingsNotifier.setAlias(_aliasController.text);

            final port = int.tryParse(_portController.text);

            if (port != null) {

              await settingsNotifier.setPort(port);

              await serverNotifier.stopServer();

              await serverNotifier.startServer();

            }

            if (!context.mounted) {

              return;

            }

            ScaffoldMessenger.of(context).showSnackBar(

              const SnackBar(content: Text('Settings saved')),

            );

          },

          child: const Text('Save settings'),

        ),

        const SizedBox(height: 32),

        const SectionHeader(title: 'About'),

        const SizedBox(height: 12),

        NetDropCard(
          child: Column(
            children: [
              const NetDropLogo(size: 88),
              const SizedBox(height: 12),
              Text(
                appDisplayName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Fast file sharing over your local network',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.nd.textSecondary,
                    ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 8),
              if (defaultTargetPlatform == TargetPlatform.android) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.system_update_outlined, color: context.cs.primary),
                  title: const Text('Check for updates'),
                  subtitle: Text(
                    'Opens NetDrop on Google Play',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.nd.textSecondary,
                        ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openPlayStore(context),
                ),
                const Divider(height: 1),
                const SizedBox(height: 8),
              ],
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.privacy_tip_outlined, color: context.cs.primary),
                title: const Text('Privacy Policy'),
                subtitle: Text(
                  'How NetDrop handles your data',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.nd.textSecondary,
                      ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PrivacyPolicyPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        const SectionHeader(title: 'Trusted devices'),
        const SizedBox(height: 12),
        _TrustedDevicesCard(),

        const SizedBox(height: 32),

        const SectionHeader(title: 'Danger zone'),

        const SizedBox(height: 12),

        OutlinedButton.icon(

          onPressed: () => _confirmReset(context),

          style: netDropDangerOutlinedButtonStyle(context),

          icon: const Icon(Icons.restart_alt),

          label: const Text('Reset app'),

        ),

      ],

    );

  }

  Future<void> _openPlayStore(BuildContext context) async {
    final opened = await openPlayStoreListing();
    if (!context.mounted) {
      return;
    }

    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open Google Play ($playStoreListingUrl)')),
      );
    }
  }

  Future<void> _confirmReset(BuildContext context) async {

    final confirmed = await showDialog<bool>(

      context: context,

      builder: (context) => AlertDialog(

        title: const Text('Reset app?'),

        content: const Text(

          'This clears your device name, settings, transfer history, and security identity. '

          'Other devices will see this phone as a new device.\n\n'

          'Files already saved in your NetDrop folders will not be deleted.',

        ),

        actions: [

          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),

          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset')),

        ],

      ),

    );



    if (confirmed != true || !context.mounted) {

      return;

    }



    await context.notifier(settingsProvider).resetApp();

    if (!context.mounted) {

      return;

    }



    final settings = context.read(settingsProvider);

    setState(() {

      _aliasController.text = settings.alias;

      _portController.text = '${settings.port}';

    });



    ScaffoldMessenger.of(context).showSnackBar(

      const SnackBar(content: Text('App reset to defaults')),

    );

  }

}



class _SettingsTile extends StatelessWidget {

  const _SettingsTile({

    required this.icon,

    required this.iconColor,

    required this.title,

    this.subtitle,

    this.child,

    this.trailing,

  });



  final IconData icon;

  final Color iconColor;

  final String title;

  final String? subtitle;

  final Widget? child;

  final Widget? trailing;



  @override

  Widget build(BuildContext context) {

    return Row(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Container(

          width: 44,

          height: 44,

          decoration: BoxDecoration(

            color: iconColor.withValues(alpha: 0.12),

            borderRadius: BorderRadius.circular(12),

          ),

          child: Icon(icon, color: iconColor, size: 22),

        ),

        const SizedBox(width: 14),

        Expanded(

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Text(

                title,

                style: Theme.of(context).textTheme.titleSmall?.copyWith(

                      fontWeight: FontWeight.w600,

                    ),

              ),

              if (subtitle != null) ...[

                const SizedBox(height: 2),

                Text(

                  subtitle!,

                  style: Theme.of(context).textTheme.bodySmall?.copyWith(

                        color: context.nd.textSecondary,

                      ),

                ),

              ],

              if (child != null) ...[

                const SizedBox(height: 8),

                child!,

              ],

            ],

          ),

        ),

        if (trailing != null) trailing!,

      ],

    );

  }

}



class _SaveLocationsCard extends StatelessWidget {

  const _SaveLocationsCard();



  @override

  Widget build(BuildContext context) {

    return FutureBuilder<List<ReceiveSaveLocation>>(

      future: context.read(fileSaverProvider).getReceiveSaveLocations(),

      builder: (context, snapshot) {

        final locations = snapshot.data;

        return NetDropCard(

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Row(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Container(

                    width: 44,

                    height: 44,

                    decoration: BoxDecoration(

                      color: NetDropColors.iconArchives.withValues(alpha: 0.12),

                      borderRadius: BorderRadius.circular(12),

                    ),

                    child: const Icon(Icons.folder_outlined, color: NetDropColors.iconArchives),

                  ),

                  const SizedBox(width: 14),

                  Expanded(

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        Text(

                          'Save locations',

                          style: Theme.of(context).textTheme.titleSmall?.copyWith(

                                fontWeight: FontWeight.w600,

                              ),

                        ),

                        const SizedBox(height: 4),

                        Text(

                          locations == null

                              ? 'Loading…'

                              : locations.length == 1

                                  ? 'All received files are saved here.'

                                  : 'Android stores media by type. All paths include a NetDrop folder.',

                          style: Theme.of(context).textTheme.bodySmall?.copyWith(

                                color: context.nd.textSecondary,

                              ),

                        ),

                      ],

                    ),

                  ),

                ],

              ),

              if (locations != null && locations.isNotEmpty) ...[

                const SizedBox(height: 14),

                const Divider(height: 1),

                const SizedBox(height: 12),

                ...locations.map(

                  (location) => Padding(

                    padding: const EdgeInsets.only(bottom: 10),

                    child: Row(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        SizedBox(

                          width: 112,

                          child: Text(

                            location.label,

                            style: Theme.of(context).textTheme.bodySmall?.copyWith(

                                  fontWeight: FontWeight.w600,

                                ),

                          ),

                        ),

                        Expanded(

                          child: Text(

                            location.path,

                            style: Theme.of(context).textTheme.bodySmall?.copyWith(

                                  color: context.nd.textSecondary,

                                  fontFamily: 'monospace',

                                ),

                          ),

                        ),

                      ],

                    ),

                  ),

                ),

              ],

            ],

          ),

        );

      },

    );

  }

}

class _TrustedDevicesCard extends StatelessWidget {
  const _TrustedDevicesCard();

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch(devicePreferencesProvider);
    final devices = context.watch(nearbyDevicesProvider).devices;
    final trusted = prefs.trustedFingerprints.toList()..sort();

    if (trusted.isEmpty) {
      return NetDropCard(
        child: Text(
          'Long-press a device on the Send tab and choose “Trust device” to auto-accept incoming files.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.nd.textSecondary,
              ),
        ),
      );
    }

    return NetDropCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < trusted.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.verified_user, color: NetDropColors.online),
              title: Text(devices[trusted[i]]?.alias ?? trusted[i]),
              subtitle: const Text('Auto-accepts incoming transfers'),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => context.notifier(devicePreferencesProvider).setTrusted(trusted[i], false),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

