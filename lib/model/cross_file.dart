import 'dart:convert';

class CrossFile {
  const CrossFile({
    required this.id,
    required this.fileName,
    required this.size,
    required this.fileType,
    this.path,
    this.bytes,
  });

  final String id;
  final String fileName;
  final int size;
  final String fileType;
  final String? path;
  final List<int>? bytes;

  bool get isInMemory => bytes != null;

  factory CrossFile.text({
    required String id,
    required String message,
  }) {
    final encoded = utf8.encode(message);
    return CrossFile(
      id: id,
      fileName: 'message.txt',
      size: encoded.length,
      fileType: 'text/plain',
      bytes: encoded,
    );
  }
}
