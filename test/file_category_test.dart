import 'package:flutter_test/flutter_test.dart';
import 'package:netdrop/util/file_category.dart';

void main() {
  group('resolveMimeType', () {
    test('uses extension from file name', () {
      expect(resolveMimeType('photo.jpg'), 'image/jpeg');
      expect(resolveMimeType('clip.MP4'), 'video/mp4');
    });

    test('treats bare extension hint as extension not mime', () {
      expect(resolveMimeType('IMG_001', 'jpg'), 'image/jpeg');
      expect(resolveMimeType('video', 'mp4'), 'video/mp4');
    });

    test('uses full mime hint when provided', () {
      expect(resolveMimeType('file', 'image/png'), 'image/png');
      expect(resolveMimeType('file.bin', 'application/pdf'), 'application/pdf');
    });
  });

  group('netDropCategoryFor', () {
    test('classifies images picked with extension hint', () {
      expect(netDropCategoryFor('IMG_001', 'jpg'), 'photos');
      expect(netDropCategoryFor('photo.heic', ''), 'photos');
    });
  });
}
