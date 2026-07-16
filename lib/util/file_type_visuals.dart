import 'package:flutter/material.dart';
import 'package:netdrop/config/app_colors.dart';

IconData fileIconFor(String fileName, String fileType) {
  final lowerName = fileName.toLowerCase();
  final lowerType = fileType.toLowerCase();

  if (lowerType.startsWith('image/') ||
      lowerName.endsWith('.jpg') ||
      lowerName.endsWith('.jpeg') ||
      lowerName.endsWith('.png') ||
      lowerName.endsWith('.gif') ||
      lowerName.endsWith('.webp')) {
    return Icons.image_outlined;
  }
  if (lowerType.startsWith('video/') ||
      lowerName.endsWith('.mp4') ||
      lowerName.endsWith('.mov') ||
      lowerName.endsWith('.mkv')) {
    return Icons.movie_outlined;
  }
  if (lowerType.startsWith('audio/') ||
      lowerName.endsWith('.mp3') ||
      lowerName.endsWith('.wav')) {
    return Icons.audiotrack_outlined;
  }
  if (lowerType == 'application/pdf' || lowerName.endsWith('.pdf')) {
    return Icons.picture_as_pdf_outlined;
  }
  if (lowerType.startsWith('text/') || lowerName.endsWith('.txt')) {
    return Icons.description_outlined;
  }
  return Icons.insert_drive_file_outlined;
}

Color fileIconColorFor(String fileName, String fileType) {
  final lowerName = fileName.toLowerCase();
  final lowerType = fileType.toLowerCase();

  if (lowerType.startsWith('image/') ||
      lowerName.endsWith('.jpg') ||
      lowerName.endsWith('.png')) {
    return NetDropColors.iconImages;
  }
  if (lowerType.startsWith('video/') || lowerName.endsWith('.mp4')) {
    return NetDropColors.iconVideos;
  }
  if (lowerType.startsWith('audio/') || lowerName.endsWith('.mp3')) {
    return NetDropColors.iconAudio;
  }
  if (lowerType == 'application/pdf' || lowerName.endsWith('.pdf')) {
    return NetDropColors.iconDocuments;
  }
  if (lowerName.endsWith('.zip') || lowerName.endsWith('.rar')) {
    return NetDropColors.iconArchives;
  }
  return NetDropColors.iconOther;
}

bool isTextMessageFile(String fileName, String fileType, {required bool isInMemory}) {
  return isInMemory && fileType == 'text/plain' && fileName == 'message.txt';
}
