import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:netdrop/config/constants.dart';
import 'package:netdrop/config/init.dart';
import 'package:netdrop/config/theme.dart';
import 'package:netdrop/pages/home_page.dart';
import 'package:netdrop/provider/network/server_provider.dart';
import 'package:netdrop/provider/settings_provider.dart';
import 'package:netdrop/util/web_splash.dart';
import 'package:netdrop/widget/design/netdrop_logo.dart';
import 'package:netdrop/widget/incoming_transfer_listener.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = await preInit();
  runApp(
    RefenaScope.withContainer(
      container: container,
      child: const NetDropApp(),
    ),
  );
}

class NetDropApp extends StatefulWidget {
  const NetDropApp({super.key});

  @override
  State<NetDropApp> createState() => _NetDropAppState();
}

class _NetDropAppState extends State<NetDropApp> with Refena {
  var _ready = kIsWeb;

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) => removeWebSplash());
      ensureRef((ref) async {
        try {
          await postInit(ref);
        } catch (error, stackTrace) {
          debugPrint('postInit failed: $error\n$stackTrace');
        }
      });
      return;
    }

    ensureRef((ref) async {
      try {
        await postInit(ref);
      } catch (error, stackTrace) {
        debugPrint('postInit failed: $error\n$stackTrace');
      } finally {
        if (mounted) {
          setState(() => _ready = true);
        }
      }
    });
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      ref.notifier(serverProvider).stopServer();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch(settingsProvider.select((s) => s.themeMode));

    return MaterialApp(
      title: appDisplayName,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(brightness: Brightness.light),
      darkTheme: buildAppTheme(brightness: Brightness.dark),
      themeMode: themeMode,
      navigatorKey: Routerino.navigatorKey,
      navigatorObservers: [RouterinoObserver()],
      home: _ready
          ? RouterinoHome(
              builder: () => const IncomingTransferListener(child: HomePage()),
            )
          : const _StartupSplash(),
    );
  }
}

class _StartupSplash extends StatelessWidget {
  const _StartupSplash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const NetDropBrandLockup(logoSize: 160),
            const SizedBox(height: 28),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
