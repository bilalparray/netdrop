import 'dart:io';

import 'package:flutter/services.dart';

const _androidReceiveChannel = MethodChannel('com.qayham.netdrop/receive');

Future<void> restartApp() async {
  if (Platform.isAndroid) {
    await _androidReceiveChannel.invokeMethod<void>('restartApp');
    return;
  }
  SystemNavigator.pop();
}
