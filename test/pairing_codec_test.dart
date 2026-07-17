import 'package:flutter_test/flutter_test.dart';
import 'package:netdrop/util/pairing_codec.dart';

void main() {
  group('pairing_codec', () {
    test('encode and decode round trip', () {
      const payload = 'netdrop://pair?v=2.1&ip=192.168.1.5&port=53317&fp=abc123&alias=Phone&https=0';
      final device = decodePairingPayload(payload);

      expect(device, isNotNull);
      expect(device!.ip, '192.168.1.5');
      expect(device.port, 53317);
      expect(device.fingerprint, 'abc123');
      expect(device.alias, 'Phone');
      expect(device.https, isFalse);
    });

    test('parseHostPort accepts ip only and ip:port', () {
      expect(parseHostPort('10.0.0.2')?.ip, '10.0.0.2');
      expect(parseHostPort('10.0.0.2:8080')?.port, 8080);
      expect(parseHostPort('bad:port'), isNull);
    });
  });
}
