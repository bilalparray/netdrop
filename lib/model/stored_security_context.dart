import 'dart:convert';

import 'package:crypto/crypto.dart';

class StoredSecurityContext {
  const StoredSecurityContext({
    required this.certificatePem,
    required this.privateKeyPem,
    required this.fingerprint,
  });

  final String certificatePem;
  final String privateKeyPem;
  final String fingerprint;

  Map<String, dynamic> toJson() => {
        'certificate': certificatePem,
        'privateKey': privateKeyPem,
        'fingerprint': fingerprint,
      };

  factory StoredSecurityContext.fromJson(Map<String, dynamic> json) {
    return StoredSecurityContext(
      certificatePem: json['certificate'] as String,
      privateKeyPem: json['privateKey'] as String,
      fingerprint: json['fingerprint'] as String,
    );
  }
}

String fingerprintFromCertificatePem(String certificatePem) {
  final der = _pemToDer(certificatePem);
  return sha256.convert(der).bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

List<int> _pemToDer(String pem) {
  final body = pem
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty && !line.startsWith('-----'))
      .join();
  return base64.decode(body);
}
