class FileDto {
  const FileDto({
    required this.id,
    required this.fileName,
    required this.size,
    required this.fileType,
    this.preview,
  });

  final String id;
  final String fileName;
  final int size;
  final String fileType;
  final String? preview;

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'size': size,
        'fileType': fileType,
        if (preview != null) 'preview': preview,
      };

  factory FileDto.fromJson(Map<String, dynamic> json) {
    return FileDto(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      size: json['size'] as int,
      fileType: json['fileType'] as String,
      preview: json['preview'] as String?,
    );
  }
}

class PrepareUploadRequestDto {
  const PrepareUploadRequestDto({
    required this.info,
    required this.files,
  });

  final Map<String, dynamic> info;
  final Map<String, FileDto> files;

  factory PrepareUploadRequestDto.fromJson(Map<String, dynamic> json) {
    final rawFiles = json['files'] as Map<String, dynamic>;
    return PrepareUploadRequestDto(
      info: Map<String, dynamic>.from(json['info'] as Map),
      files: rawFiles.map(
        (key, value) => MapEntry(key, FileDto.fromJson(Map<String, dynamic>.from(value as Map))),
      ),
    );
  }
}

class PrepareUploadResponseDto {
  const PrepareUploadResponseDto({
    required this.sessionId,
    required this.files,
  });

  final String sessionId;
  final Map<String, String> files;

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'files': files,
      };
}
