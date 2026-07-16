import 'package:refena/refena.dart';

enum HomeTab { send, receive, transfers, settings }

class HomeTabService extends Notifier<HomeTab> {
  @override
  HomeTab init() => HomeTab.send;

  void select(HomeTab tab) {
    state = tab;
  }
}

final homeTabProvider = NotifierProvider<HomeTabService, HomeTab>(
  (ref) => HomeTabService(),
);
