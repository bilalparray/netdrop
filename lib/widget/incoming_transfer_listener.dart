import 'package:flutter/material.dart';
import 'package:netdrop/model/state/server_state.dart';
import 'package:netdrop/pages/receive_page.dart';
import 'package:netdrop/provider/network/server_provider.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

/// Shows the incoming transfer screen whenever the server has a pending session.
class IncomingTransferListener extends StatefulWidget {
  const IncomingTransferListener({super.key, required this.child});

  final Widget child;

  @override
  State<IncomingTransferListener> createState() => _IncomingTransferListenerState();
}

class _IncomingTransferListenerState extends State<IncomingTransferListener> with Refena {
  String? _presentedSessionId;

  @override
  Widget build(BuildContext context) {
    final session = context.watch(
      serverProvider.select((state) => state.activeSession),
    );

    if (session?.status == ReceiveSessionStatus.pending) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _presentIfNeeded(session!);
      });
    } else {
      _presentedSessionId = null;
    }

    return widget.child;
  }

  void _presentIfNeeded(ReceiveSessionState session) {
    if (!mounted) {
      return;
    }
    if (_presentedSessionId == session.sessionId) {
      return;
    }

    final navigator = Routerino.navigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    _presentedSessionId = session.sessionId;
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => ReceivePage(session: session),
        fullscreenDialog: true,
      ),
    );
  }
}
