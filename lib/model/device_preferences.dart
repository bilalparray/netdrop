class ManualDeviceRecord {
  const ManualDeviceRecord({
    required this.fingerprint,
    required this.ip,
    required this.port,
    required this.alias,
    this.https = false,
  });

  final String fingerprint;
  final String ip;
  final int port;
  final String alias;
  final bool https;

  Map<String, dynamic> toJson() => {
        'fingerprint': fingerprint,
        'ip': ip,
        'port': port,
        'alias': alias,
        'https': https,
      };

  factory ManualDeviceRecord.fromJson(Map<String, dynamic> json) {
    return ManualDeviceRecord(
      fingerprint: json['fingerprint'] as String,
      ip: json['ip'] as String,
      port: json['port'] as int,
      alias: json['alias'] as String,
      https: json['https'] as bool? ?? false,
    );
  }
}

class DevicePreferencesState {
  const DevicePreferencesState({
    this.trustedFingerprints = const {},
    this.pinnedFingerprints = const {},
    this.manualDevices = const {},
  });

  final Set<String> trustedFingerprints;
  final Set<String> pinnedFingerprints;
  final Map<String, ManualDeviceRecord> manualDevices;

  bool isTrusted(String fingerprint) => trustedFingerprints.contains(fingerprint);

  bool isPinned(String fingerprint) => pinnedFingerprints.contains(fingerprint);

  bool isManual(String fingerprint) => manualDevices.containsKey(fingerprint);

  DevicePreferencesState copyWith({
    Set<String>? trustedFingerprints,
    Set<String>? pinnedFingerprints,
    Map<String, ManualDeviceRecord>? manualDevices,
  }) {
    return DevicePreferencesState(
      trustedFingerprints: trustedFingerprints ?? this.trustedFingerprints,
      pinnedFingerprints: pinnedFingerprints ?? this.pinnedFingerprints,
      manualDevices: manualDevices ?? this.manualDevices,
    );
  }
}
