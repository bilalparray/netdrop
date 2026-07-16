import 'package:flutter/material.dart';
import 'package:netdrop/pages/tabs/history_tab.dart';
import 'package:netdrop/pages/tabs/receive_tab.dart';
import 'package:netdrop/pages/tabs/send_tab.dart';
import 'package:netdrop/pages/tabs/settings_tab.dart';
import 'package:netdrop/provider/home_tab_provider.dart';
import 'package:netdrop/widget/design/netdrop_logo.dart';
import 'package:netdrop/widget/responsive_builder.dart';
import 'package:refena_flutter/refena_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with Refena {
  final _pageController = PageController();
  HomeTab? _lastSyncedTab;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = context.watch(homeTabProvider);
    if (_lastSyncedTab != currentTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pageController.hasClients) {
          return;
        }
        _pageController.jumpToPage(currentTab.index);
        _lastSyncedTab = currentTab;
      });
    }

    final isDesktop = ResponsiveBuilder.isDesktop(context);
    final isMobile = ResponsiveBuilder.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: const NetDropAppBarTitle(),
        centerTitle: false,
      ),
      body: Row(
        children: [
          if (!isMobile)
            NavigationRail(
              extended: isDesktop,
              selectedIndex: currentTab.index,
              onDestinationSelected: (index) {
                context.notifier(homeTabProvider).select(HomeTab.values[index]);
              },
              labelType: isDesktop ? NavigationRailLabelType.none : NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.upload_outlined),
                  selectedIcon: Icon(Icons.upload),
                  label: Text('Send'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.download_outlined),
                  selectedIcon: Icon(Icons.download),
                  label: Text('Receive'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.swap_horiz_outlined),
                  selectedIcon: Icon(Icons.swap_horiz),
                  label: Text('Transfers'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
              ],
            ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                SendTab(),
                ReceiveTab(),
                HistoryTab(),
                SettingsTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isMobile
          ? NavigationBar(
              selectedIndex: currentTab.index,
              onDestinationSelected: (index) {
                context.notifier(homeTabProvider).select(HomeTab.values[index]);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.upload_outlined),
                  selectedIcon: Icon(Icons.upload),
                  label: 'Send',
                ),
                NavigationDestination(
                  icon: Icon(Icons.download_outlined),
                  selectedIcon: Icon(Icons.download),
                  label: 'Receive',
                ),
                NavigationDestination(
                  icon: Icon(Icons.swap_horiz_outlined),
                  selectedIcon: Icon(Icons.swap_horiz),
                  label: 'Transfers',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            )
          : null,
    );
  }
}
