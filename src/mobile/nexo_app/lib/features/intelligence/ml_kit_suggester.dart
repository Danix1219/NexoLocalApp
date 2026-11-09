import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

import 'category_suggester.dart';

/// Modelo de visión en el teléfono (ML Kit, modelo base incluido en la app):
/// la foto no sale del dispositivo para esta sugerencia.
class MlKitCategorySuggester implements CategorySuggester {
  MlKitCategorySuggester() : _labeler = ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.35));

  final ImageLabeler _labeler;

  @override
  Future<CategoryGuess?> suggest(String imagePath, {Set<String>? allowed}) async {
    final sw = Stopwatch()..start();
    try {
      final labels = await _labeler.processImage(InputImage.fromFilePath(imagePath));
      sw.stop();
      final g = guessFromLabels([for (final l in labels) (l.label, l.confidence)],
          allowed: allowed, latencyMs: sw.elapsedMilliseconds);
      if (kDebugMode) {
        debugPrint('[ML] ${labels.length} etiquetas en ${sw.elapsedMilliseconds} ms -> ${g?.category ?? 'se abstiene'}');
      }
      return g;
    } catch (_) {
      // Modelo no disponible: la persona elige la categoría a mano.
      return null;
    }
  }

  @override
  Future<void> close() => _labeler.close();
}

final categorySuggesterProvider = Provider<CategorySuggester>((ref) {
  final s = MlKitCategorySuggester();
  ref.onDispose(s.close);
  return s;
});
