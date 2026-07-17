import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:netdrop/config/constants.dart';
import 'package:netdrop/config/netdrop_theme_ext.dart';
import 'package:netdrop/model/device.dart';
import 'package:netdrop/network/device_connect.dart';
import 'package:netdrop/provider/device_preferences_provider.dart';
import 'package:netdrop/provider/local_ip_provider.dart';
import 'package:netdrop/provider/settings_provider.dart';
import 'package:netdrop/util/pairing_codec.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:refena_flutter/refena_flutter.dart';

class PairDevicePage extends StatefulWidget {
  const PairDevicePage({super.key});

  @override
  State<PairDevicePage> createState() => _PairDevicePageState();
}

class _PairDevicePageState extends State<PairDevicePage> with Refena {
  final _ipController = TextEditingController();
  var _connecting = false;
  String? _error;

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _connectParsed(Device device) async {
    setState(() {
      _connecting = true;
      _error = null;
    });

    final connected = await connectToDevice(
      ref: ref,
      ip: device.ip,
      port: device.port,
      preferHttps: device.https,
      knownDevice: device,
    );

    if (!mounted) {
      return;
    }

    if (connected == null) {
      setState(() {
        _connecting = false;
        _error = 'Could not reach that device. Check IP, port, and Wi‑Fi.';
      });
      return;
    }

    await ref.notifier(devicePreferencesProvider).saveManualDevice(connected);
    if (mounted) {
      Navigator.of(context).pop(connected);
    }
  }

  Future<void> _connectManualIp() async {
    final parsed = parseHostPort(_ipController.text);
    if (parsed == null) {
      setState(() => _error = 'Enter a valid IP or IP:port (e.g. 192.168.1.5:53317)');
      return;
    }

    setState(() {
      _connecting = true;
      _error = null;
    });

    final device = await fetchDeviceAt(
      ref: ref,
      ip: parsed.ip,
      port: parsed.port,
    );

    if (!mounted) {
      return;
    }

    if (device == null) {
      setState(() {
        _connecting = false;
        _error = 'No NetDrop device found at that address.';
      });
      return;
    }

    await _connectParsed(device);
  }

  void _onQrDetected(BarcodeCapture capture) {
    if (_connecting) {
      return;
    }
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) {
        continue;
      }
      final device = decodePairingPayload(raw);
      if (device != null) {
        _connectParsed(device);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pair device'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Scan QR'),
              Tab(text: 'Enter IP'),
              Tab(text: 'My QR'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ScanTab(onDetect: _onQrDetected, connecting: _connecting, error: _error),
            _ManualIpTab(
              controller: _ipController,
              connecting: _connecting,
              error: _error,
              onConnect: _connectManualIp,
            ),
            const _MyQrTab(),
          ],
        ),
      ),
    );
  }
}

class _ScanTab extends StatelessWidget {
  const _ScanTab({
    required this.onDetect,
    required this.connecting,
    required this.error,
  });

  final void Function(BarcodeCapture capture) onDetect;
  final bool connecting;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(onDetect: onDetect),
              if (connecting)
                ColoredBox(
                  color: Colors.black45,
                  child: Center(
                    child: CircularProgressIndicator(color: context.cs.primary),
                  ),
                ),
            ],
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              error!,
              style: TextStyle(color: context.cs.error),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

class _ManualIpTab extends StatelessWidget {
  const _ManualIpTab({
    required this.controller,
    required this.connecting,
    required this.error,
    required this.onConnect,
  });

  final TextEditingController controller;
  final bool connecting;
  final String? error;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Connect when discovery fails (guest Wi‑Fi, iOS, etc.)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.nd.textSecondary,
                ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'IP address',
              hintText: '192.168.1.5 or 192.168.1.5:53317',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onConnect(),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: connecting ? null : onConnect,
            child: connecting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Connect'),
          ),
          if (error != null) ...[
            const SizedBox(height: 16),
            Text(
              error!,
              style: TextStyle(color: context.cs.error),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _MyQrTab extends StatelessWidget {
  const _MyQrTab();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch(settingsProvider);

    return FutureBuilder<List<String>>(
      future: context.read(localIpProvider).getLocalIps(),
      builder: (context, snapshot) {
        final ip = snapshot.data?.firstOrNull;
        if (ip == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final payload = encodePairingPayload(
          ip: ip,
          port: settings.port,
          fingerprint: settings.fingerprint,
          alias: settings.alias,
          https: settings.https,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                'Ask the other device to scan this code',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.nd.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: payload,
                  version: QrVersions.auto,
                  size: 220,
                ),
              ),
              const SizedBox(height: 20),
              SelectableText(
                payload,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.nd.textMuted,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: payload));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pairing link copied')),
                  );
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy link'),
              ),
            ],
          ),
        );
      },
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
