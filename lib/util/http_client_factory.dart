import 'dart:convert';
import 'dart:io';

import 'package:netdrop/model/stored_security_context.dart';

HttpClient createHttpClient({
  required bool https,
  StoredSecurityContext? security,
  Duration? connectionTimeout,
}) {
  final HttpClient client;
  if (https) {
    if (security == null) {
      throw StateError('HTTPS requires a security context');
    }
    final context = SecurityContext();
    context.useCertificateChainBytes(utf8.encode(security.certificatePem));
    context.usePrivateKeyBytes(utf8.encode(security.privateKeyPem));
    client = HttpClient(context: context);
    client.badCertificateCallback = (_, __, ___) => true;
  } else {
    client = HttpClient();
  }
  if (connectionTimeout != null) {
    client.connectionTimeout = connectionTimeout;
  }
  return client;
}
