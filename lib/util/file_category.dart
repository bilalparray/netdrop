/// Resolves a MIME type from a file name and an optional hint.
///
/// [hint] may be a full MIME type (`image/jpeg`) or a bare extension (`jpg`).
/// Bare extensions are not treated as MIME types.
String resolveMimeType(String fileName, [String? hint]) {
  final normalizedHint = hint?.trim();
  if (normalizedHint != null &&
      normalizedHint.isNotEmpty &&
      normalizedHint.contains('/') &&
      normalizedHint != 'application/octet-stream') {
    return normalizedHint;
  }

  final ext = _extensionFrom(fileName, normalizedHint);
  if (ext.isNotEmpty) {
    return _mimeFromExtension(ext);
  }
  return 'application/octet-stream';
}

String _extensionFrom(String fileName, String? extensionHint) {
  if (fileName.contains('.')) {
    final ext = fileName.split('.').last.toLowerCase();
    if (ext.isNotEmpty && ext != fileName.toLowerCase()) {
      return ext;
    }
  }
  if (extensionHint != null &&
      extensionHint.isNotEmpty &&
      !extensionHint.contains('/')) {
    return extensionHint.toLowerCase();
  }
  return '';
}

String _mimeFromExtension(String ext) {
  return switch (ext) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'gif' => 'image/gif',
    'webp' => 'image/webp',
    'bmp' => 'image/bmp',
    'heic' => 'image/heic',
    'heif' => 'image/heif',
    'mp4' => 'video/mp4',
    'mov' => 'video/quicktime',
    'avi' => 'video/x-msvideo',
    'mkv' => 'video/x-matroska',
    'webm' => 'video/webm',
    '3gp' => 'video/3gpp',
    'm4v' => 'video/x-m4v',
    'mp3' => 'audio/mpeg',
    'wav' => 'audio/wav',
    'flac' => 'audio/flac',
    'aac' => 'audio/aac',
    'm4a' => 'audio/mp4',
    'ogg' => 'audio/ogg',
    'pdf' => 'application/pdf',
    'txt' => 'text/plain',
    'doc' => 'application/msword',
    'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls' => 'application/vnd.ms-excel',
    'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'ppt' => 'application/vnd.ms-powerpoint',
    'pptx' => 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'zip' => 'application/zip',
    'rar' => 'application/vnd.rar',
    '7z' => 'application/x-7z-compressed',
    'tar' => 'application/x-tar',
    'gz' => 'application/gzip',
    _ => 'application/octet-stream',
  };
}

String netDropCategoryFor(String fileName, String fileType) {
  final mimeType = resolveMimeType(fileName, fileType);

  if (mimeType.startsWith('image/')) {
    return 'photos';
  }
  if (mimeType.startsWith('video/')) {
    return 'videos';
  }
  if (mimeType.startsWith('audio/')) {
    return 'audio';
  }
  if (mimeType == 'application/pdf' ||
      mimeType.startsWith('text/') ||
      mimeType.contains('document') ||
      mimeType.contains('word') ||
      mimeType.contains('sheet') ||
      mimeType.contains('presentation') ||
      mimeType.contains('msword') ||
      mimeType.contains('spreadsheet')) {
    return 'documents';
  }
  if (mimeType.contains('zip') ||
      mimeType.contains('rar') ||
      mimeType.contains('7z') ||
      mimeType.contains('archive') ||
      mimeType.contains('compressed') ||
      mimeType.contains('gzip') ||
      mimeType.contains('x-tar')) {
    return 'archives';
  }
  return 'other';
}

const netDropSubfolders = ['photos', 'videos', 'audio', 'documents', 'archives', 'other'];
