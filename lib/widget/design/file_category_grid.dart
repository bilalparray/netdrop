import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:netdrop/config/app_colors.dart';
import 'package:netdrop/config/netdrop_theme_ext.dart';

class FileCategoryGrid extends StatelessWidget {
  const FileCategoryGrid({super.key, required this.onCategoryTap});

  final ValueChanged<FilePickCategory> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: FilePickCategory.values.map((category) {
        return _CategoryTile(
          category: category,
          onTap: () => onCategoryTap(category),
        );
      }).toList(),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});

  final FilePickCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;

    return Material(
      color: context.cs.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: nd.border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: nd.cardShadow,
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(category.icon, color: category.color, size: 26),
              ),
              const SizedBox(height: 10),
              Text(
                category.label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.cs.onSurface,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum FilePickCategory {
  documents('Documents', Icons.description_outlined, NetDropColors.iconDocuments),
  images('Images', Icons.image_outlined, NetDropColors.iconImages),
  videos('Videos', Icons.movie_outlined, NetDropColors.iconVideos),
  audio('Audio', Icons.audiotrack_outlined, NetDropColors.iconAudio),
  archives('Archives', Icons.folder_zip_outlined, NetDropColors.iconArchives),
  other('Other', Icons.insert_drive_file_outlined, NetDropColors.iconOther);

  const FilePickCategory(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  List<String>? get allowedExtensions => switch (this) {
        FilePickCategory.documents => const [
            'pdf',
            'doc',
            'docx',
            'txt',
            'xls',
            'xlsx',
            'ppt',
            'pptx',
          ],
        FilePickCategory.archives => const ['zip', 'rar', '7z', 'tar', 'gz'],
        _ => null,
      };

  /// Native picker mode — gallery for images, etc.
  FileType get pickerType => switch (this) {
        FilePickCategory.images => FileType.image,
        FilePickCategory.videos => FileType.video,
        FilePickCategory.audio => FileType.audio,
        FilePickCategory.documents || FilePickCategory.archives => FileType.custom,
        FilePickCategory.other => FileType.any,
      };

  /// Fallback MIME when the OS does not provide a useful file name.
  String get fallbackMime => switch (this) {
        FilePickCategory.images => 'image/jpeg',
        FilePickCategory.videos => 'video/mp4',
        FilePickCategory.audio => 'audio/mpeg',
        FilePickCategory.documents => 'application/octet-stream',
        FilePickCategory.archives => 'application/zip',
        FilePickCategory.other => 'application/octet-stream',
      };
}
