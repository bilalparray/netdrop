import 'package:flutter/material.dart';
import 'package:netdrop/config/app_colors.dart';
import 'package:netdrop/config/netdrop_theme_ext.dart';
import 'package:netdrop/provider/network/server_provider.dart';
import 'package:netdrop/util/app_restart.dart';
import 'package:refena_flutter/refena_flutter.dart';

class ServerStatusBanner extends StatefulWidget {
  const ServerStatusBanner({super.key});

  @override
  State<ServerStatusBanner> createState() => _ServerStatusBannerState();
}

class _ServerStatusBannerState extends State<ServerStatusBanner> {
  var _restarting = false;

  Future<void> _retry() async {
    await context.notifier(serverProvider).startServer();
  }

  Future<void> _restartApp() async {
    if (_restarting) {
      return;
    }
    setState(() => _restarting = true);
    try {
      await restartApp();
    } finally {
      if (mounted) {
        setState(() => _restarting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final server = context.watch(serverProvider);
    if (server.running) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: NetDropColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: NetDropColors.error, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Receive server is off',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: NetDropColors.error,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          server.error ??
                              'This device cannot accept files until the server starts.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: context.nd.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (server.portBlocked) ...[
                    TextButton(
                      onPressed: server.starting ? null : () => context.notifier(serverProvider).tryNextPort(),
                      child: const Text('Use next port'),
                    ),
                    TextButton(
                      onPressed: _restarting ? null : _restartApp,
                      child: _restarting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Restart app'),
                    ),
                  ],
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: server.starting ? null : _retry,
                    child: server.starting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Retry'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
