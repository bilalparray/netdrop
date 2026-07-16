import 'package:basic_utils/basic_utils.dart';
import 'package:netdrop/config/constants.dart';
import 'package:netdrop/model/stored_security_context.dart';

class SecurityHelper {
  static StoredSecurityContext generate() {
    final keyPair = CryptoUtils.generateRSAKeyPair(keySize: 2048);
    final privateKey = keyPair.privateKey as RSAPrivateKey;
    final publicKey = keyPair.publicKey as RSAPublicKey;

    final csr = X509Utils.generateRsaCsrPem(
      {'CN': '$appDisplayName User'},
      privateKey,
      publicKey,
    );
    final certificatePem = X509Utils.generateSelfSignedCertificate(
      privateKey,
      csr,
      3650,
    );
    final privateKeyPem = CryptoUtils.encodeRSAPrivateKeyToPemPkcs1(privateKey);
    final fingerprint = fingerprintFromCertificatePem(certificatePem);

    return StoredSecurityContext(
      certificatePem: certificatePem,
      privateKeyPem: privateKeyPem,
      fingerprint: fingerprint,
    );
  }
}
