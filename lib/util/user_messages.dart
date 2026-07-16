import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:netdrop/network/transfer_client.dart';

enum UserMessageContext {
  send,
  receive,
  openFile,
  server,
  general,
}

String friendlyErrorMessage(
  Object? error, {
  UserMessageContext context = UserMessageContext.general,
  String? fallback,
  bool portBlocked = false,
}) {
  if (error == null) {
    return fallback ?? _defaultFallback(context);
  }

  if (error is SessionCancelledException) {
    return 'Transfer was cancelled.';
  }

  final text = error.toString();
  final lower = text.toLowerCase();

  if (error is SocketException || lower.contains('socketexception')) {
    if (portBlocked || context == UserMessageContext.server) {
      if (lower.contains('address already in use') ||
          lower.contains('eaddrinuse') ||
          portBlocked) {
        return 'This port is already in use on this device — often by LocalSend or another file-sharing app. Tap Use next port, or change it in Settings.';
      }
      return 'NetDrop could not start on this device. Check your Wi‑Fi and try again.';
    }
    return 'Could not reach the other device. Make sure both devices are on the same Wi‑Fi network.';
  }

  if (error is TimeoutException || lower.contains('timeout')) {
    return switch (context) {
      UserMessageContext.send => 'The other device took too long to respond. Please try again.',
      UserMessageContext.receive => 'The sender stopped responding. Please try again.',
      _ => 'The connection timed out. Please try again.',
    };
  }

  if (error is HttpException || lower.contains('httpexception')) {
    return _friendlyHttpMessage(text, context: context);
  }

  if (error is StateError) {
    if (lower.contains('security context')) {
      return 'Secure connection is not ready on this device. Try resetting the app in Settings.';
    }
    if (lower.contains('no path or bytes')) {
      return 'One of the selected files could not be read.';
    }
  }

  if (error is FileSystemException || lower.contains('filesystemexception')) {
    return 'Could not save the file on this device. Check available storage and try again.';
  }

  if (error is PlatformException) {
    return error.message ?? _defaultFallback(context);
  }

  if (lower.contains('certificate') ||
      lower.contains('handshake') ||
      lower.contains('tls') ||
      lower.contains('ssl')) {
    return 'Secure connection failed. Try matching HTTPS settings on both devices.';
  }

  if (lower.contains('connection refused') || lower.contains('connection reset')) {
    return 'Could not connect to the other device. Make sure NetDrop is open on both devices.';
  }

  if (lower.contains('network is unreachable') || lower.contains('no route to host')) {
    return 'Network unavailable. Check your Wi‑Fi connection and try again.';
  }

  if (lower.contains('file not found')) {
    return switch (context) {
      UserMessageContext.openFile => 'This file is no longer available on your device.',
      _ => 'A file could not be found. Please try again.',
    };
  }

  if (lower.contains('busy')) {
    return 'The other device is busy with another transfer. Try again in a moment.';
  }

  if (lower.contains('declined')) {
    return 'The receiver declined the transfer.';
  }

  if (lower.contains('cancelled') || lower.contains('canceled')) {
    return 'Transfer was cancelled.';
  }

  return fallback ?? _defaultFallback(context);
}

String _friendlyHttpMessage(
  String text, {
  required UserMessageContext context,
}) {
  final lower = text.toLowerCase();

  if (lower.contains('409') || lower.contains('busy')) {
    return 'The other device is busy with another transfer. Try again in a moment.';
  }

  if (lower.contains('declined')) {
    return 'The receiver declined the transfer.';
  }

  if (lower.contains('timed out') || lower.contains('timeout')) {
    return 'The other device did not respond in time. Please try again.';
  }

  if (lower.contains('invalid token') || lower.contains('forbidden')) {
    if (lower.contains('prepare upload')) {
      return 'The receiver did not accept the transfer in time. Please try again.';
    }
    return 'This transfer is no longer valid. Please send the files again.';
  }

  if (lower.contains('prepare upload failed')) {
    if (lower.contains('403')) {
      return 'The receiver declined the transfer or did not respond in time.';
    }
    if (lower.contains('404')) {
      return 'Could not reach the other device. Make sure NetDrop is running on it.';
    }
    if (lower.contains('500') || lower.contains('502') || lower.contains('503')) {
      return 'The other device had a problem receiving files. Please try again.';
    }
    return 'Could not start the transfer. Please try again.';
  }

  if (lower.contains('upload failed')) {
    return 'Could not finish sending the file. Check your connection and try again.';
  }

  return switch (context) {
    UserMessageContext.send => 'Could not send the files. Please try again.',
    UserMessageContext.receive => 'Could not receive the files. Please try again.',
    UserMessageContext.openFile => 'Could not open this file.',
    UserMessageContext.server => 'NetDrop could not start on this device. Try changing the port in Settings.',
    UserMessageContext.general => 'Something went wrong. Please try again.',
  };
}

String _defaultFallback(UserMessageContext context) {
  return switch (context) {
    UserMessageContext.send => 'Could not send the files. Please try again.',
    UserMessageContext.receive => 'Could not receive the files. Please try again.',
    UserMessageContext.openFile => 'Could not open this file.',
    UserMessageContext.server => 'Something went wrong with this device. Please try again.',
    UserMessageContext.general => 'Something went wrong. Please try again.',
  };
}

String friendlyOpenFileMessage(Object? error) {
  return friendlyErrorMessage(
    error,
    context: UserMessageContext.openFile,
    fallback: 'Could not open this file.',
  );
}
