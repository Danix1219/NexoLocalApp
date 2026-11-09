import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/nexo_api.dart';
import 'nexo_sheet.dart';

final _picker = ImagePicker();

String _type(String path) {
  final p = path.toLowerCase();
  if (p.endsWith('.png')) return 'image/png';
  if (p.endsWith('.webp')) return 'image/webp';
  if (p.endsWith('.heic') || p.endsWith('.heif')) return 'image/heic';
  return 'image/jpeg';
}

Future<PickedImage?> _toPicked(XFile? f) async {
  if (f == null) return null;
  return PickedImage(path: f.path, bytes: await f.readAsBytes(), contentType: _type(f.path));
}

/// Pregunta cámara o galería y devuelve la foto reducida (máx. 1600 px).
Future<PickedImage?> pickOneImage(BuildContext context) async {
  final src = await showNexoSheet<ImageSource>(
    context,
    builder: (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetHeader('Agregar foto'),
        OptRow(icon: 'camera', label: 'Tomar foto', onTap: () => Navigator.of(ctx).pop(ImageSource.camera)),
        const SizedBox(height: 8),
        OptRow(icon: 'image', label: 'Elegir de la galería', onTap: () => Navigator.of(ctx).pop(ImageSource.gallery)),
      ],
    ),
  );
  if (src == null) return null;
  try {
    return _toPicked(await _picker.pickImage(source: src, maxWidth: 1600, maxHeight: 1600, imageQuality: 85));
  } catch (_) {
    return null;
  }
}

/// Varias fotos de la galería (publicar un trabajo, hasta [max]).
Future<List<PickedImage>> pickImages({int max = 4}) async {
  try {
    final files = await _picker.pickMultiImage(maxWidth: 1600, maxHeight: 1600, imageQuality: 85, limit: max >= 2 ? max : null);
    final out = <PickedImage>[];
    for (final f in files.take(max)) {
      final p = await _toPicked(f);
      if (p != null) out.add(p);
    }
    return out;
  } catch (_) {
    return const [];
  }
}
