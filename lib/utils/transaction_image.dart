import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'constants.dart';

/// Turn API image refs (full URL or path) into a loadable URL.
String resolveTransactionImageUrl(String ref) {
  final t = ref.trim();
  if (t.isEmpty) return '';
  if (t.startsWith('http://') || t.startsWith('https://')) return t;
  final base = Constants.backendUrl.replaceAll(RegExp(r'/+$'), '');
  return t.startsWith('/') ? '$base$t' : '$base/$t';
}

/// Copy picker output into app documents so paths survive after temp cleanup.
Future<String> persistQcDraftPhoto(XFile photo) async {
  final dir = await getApplicationDocumentsDirectory();
  final draftDir = Directory('${dir.path}/qc_draft_photos');
  if (!await draftDir.exists()) {
    await draftDir.create(recursive: true);
  }
  final basename = photo.name.isNotEmpty ? photo.name : 'img.jpg';
  final safe = basename.replaceAll(RegExp(r'[^\w.\-]'), '_');
  final destPath =
      '${draftDir.path}/${DateTime.now().millisecondsSinceEpoch}_$safe';
  await File(photo.path).copy(destPath);
  return destPath;
}

/// Drop missing files from a saved draft list (cache/temp paths).
List<String> filterExistingPhotoPaths(List<dynamic> raw) {
  return raw
      .map((e) => e.toString().trim())
      .where((p) => p.isNotEmpty && File(p).existsSync())
      .toList();
}
