import 'package:flutter/material.dart';

import 'package:netdrop/config/netdrop_theme_ext.dart';

import 'package:netdrop/config/theme.dart';

import 'package:netdrop/model/state/server_state.dart';

import 'package:netdrop/provider/network/server_provider.dart';

import 'package:netdrop/util/format_helpers.dart';

import 'package:netdrop/widget/design/netdrop_card.dart';

import 'package:netdrop/widget/received_file_list_tile.dart';

import 'package:refena_flutter/refena_flutter.dart';

import 'package:routerino/routerino.dart';



class ReceivePage extends StatefulWidget {

  const ReceivePage({super.key, required this.session});



  final ReceiveSessionState session;



  @override

  State<ReceivePage> createState() => _ReceivePageState();

}



class _ReceivePageState extends State<ReceivePage> with Refena {

  var _handledDismiss = false;



  void _maybeDismiss(BuildContext context, ServerState serverState) {

    if (_handledDismiss) {

      return;

    }



    final active = serverState.activeSession;

    if (active != null && active.sessionId == widget.session.sessionId) {

      return;

    }



    _handledDismiss = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {

      if (!context.mounted) {

        return;

      }

      if (active == null) {

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(content: Text('Transfer was cancelled by sender')),

        );

      }

      context.pop();

    });

  }



  @override

  Widget build(BuildContext context) {

    final serverState = context.watch(serverProvider);

    _maybeDismiss(context, serverState);



    final firstFile = widget.session.files.values.firstOrNull;



    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }

        final serverState = context.read(serverProvider);
        final active = serverState.activeSession;
        if (active != null &&
            active.sessionId == widget.session.sessionId &&
            active.status == ReceiveSessionStatus.pending) {
          await context.notifier(serverProvider).declineSession(widget.session.sessionId);
        }

        if (context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(

      appBar: AppBar(title: const Text('Incoming transfer')),

      body: Padding(

        padding: const EdgeInsets.all(24),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [

            const SizedBox(height: 8),

            Center(

              child: Container(

                width: 80,

                height: 80,

                decoration: BoxDecoration(

                  color: context.nd.surfaceMuted,

                  shape: BoxShape.circle,

                ),

                child: Icon(

                  Icons.laptop_mac,

                  size: 40,

                  color: context.cs.primary,

                ),

              ),

            ),

            const SizedBox(height: 20),

            Text(

              widget.session.sender.alias,

              textAlign: TextAlign.center,

              style: Theme.of(context).textTheme.headlineSmall?.copyWith(

                    fontWeight: FontWeight.w700,

                  ),

            ),

            const SizedBox(height: 6),

            Text(

              'wants to send you ${widget.session.files.length} file(s)',

              textAlign: TextAlign.center,

              style: Theme.of(context).textTheme.bodyMedium?.copyWith(

                    color: context.nd.textSecondary,

                  ),

            ),

            const SizedBox(height: 24),

            Expanded(

              child: ListView(

                children: widget.session.files.values.map((file) {

                  return Padding(

                    padding: const EdgeInsets.only(bottom: 10),

                    child: NetDropCard(

                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

                      child: ReceivedFileListTile(

                        fileName: file.fileName,

                        fileType: file.fileType,

                        size: file.size,

                        completed: false,

                      ),

                    ),

                  );

                }).toList(),

              ),

            ),

            if (firstFile != null)

              Padding(

                padding: const EdgeInsets.only(bottom: 16),

                child: Text(

                  'Total size: ${formatFileSize(widget.session.files.values.fold<int>(0, (sum, f) => sum + f.size))}',

                  textAlign: TextAlign.center,

                  style: Theme.of(context).textTheme.bodySmall?.copyWith(

                        color: context.nd.textMuted,

                      ),

                ),

              ),

            FilledButton(

              onPressed: () async {

                await context.notifier(serverProvider).acceptSession(widget.session.sessionId);

                if (context.mounted) {

                  context.pop();

                  ScaffoldMessenger.of(context).showSnackBar(

                    const SnackBar(content: Text('Transfer accepted')),

                  );

                }

              },

              child: const Text('Accept'),

            ),

            const SizedBox(height: 10),

            OutlinedButton(

              onPressed: () async {

                await context.notifier(serverProvider).declineSession(widget.session.sessionId);

                if (context.mounted) {

                  context.pop();

                }

              },

              style: netDropDangerOutlinedButtonStyle(context),

              child: const Text('Reject'),

            ),

          ],

        ),

      ),

      ),

    );

  }

}



extension _FirstOrNull<T> on Iterable<T> {

  T? get firstOrNull {

    final iterator = this.iterator;

    if (!iterator.moveNext()) {

      return null;

    }

    return iterator.current;

  }

}


