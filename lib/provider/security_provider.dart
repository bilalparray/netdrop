import 'dart:convert';
import 'dart:io';

import 'package:netdrop/model/stored_security_context.dart';
import 'package:refena/refena.dart';

class SecurityService extends Notifier<StoredSecurityContext> {
  @override
  StoredSecurityContext init() {
    throw UnimplementedError('SecurityService must be overridden at startup');
  }

  SecurityContext createServerContext() {
    final context = SecurityContext();
    context.useCertificateChainBytes(utf8.encode(state.certificatePem));
    context.usePrivateKeyBytes(utf8.encode(state.privateKeyPem));
    return context;
  }

  SecurityContext createClientContext() {
    final context = SecurityContext();
    context.useCertificateChainBytes(utf8.encode(state.certificatePem));
    context.usePrivateKeyBytes(utf8.encode(state.privateKeyPem));
    return context;
  }

  void replaceContext(StoredSecurityContext context) {
    state = context;
  }
}

final securityProvider = NotifierProvider<SecurityService, StoredSecurityContext>(
  (ref) => SecurityService(),
);
