/// Sugerencia de categoría a partir de una foto (función de ML, spec 049).
///
/// La inferencia la hace un modelo de visión en el teléfono (ML Kit Image
/// Labeling, ver `ml_kit_suggester.dart`); aquí solo vive la decisión:
/// sumar la confianza de las etiquetas por categoría y abstenerse cuando el
/// modelo no está seguro. La persona siempre puede corregir la categoría.
library;

class CategoryGuess {
  const CategoryGuess({required this.category, required this.confidence, required this.labels, this.latencyMs = 0});

  /// Slug de la categoría de Nexo (`plomeria`, `electricidad`…).
  final String category;

  /// 0..1 — se muestra como porcentaje para que se vea la incertidumbre.
  final double confidence;

  /// Etiquetas del modelo que sostienen la sugerencia (para explicarla).
  final List<String> labels;
  final int latencyMs;
}

/// Etiquetas del modelo base de ML Kit (en inglés) → categoría de Nexo.
const labelToCategory = <String, String>{
  // plomería
  'sink': 'plomeria', 'bathroom': 'plomeria', 'bathtub': 'plomeria', 'toilet': 'plomeria',
  'tap': 'plomeria', 'plumbing': 'plomeria', 'pipe': 'plomeria', 'shower': 'plomeria', 'water': 'plomeria',
  // electricidad
  'lamp': 'electricidad', 'light': 'electricidad', 'light fixture': 'electricidad', 'chandelier': 'electricidad',
  'electrical wiring': 'electricidad', 'cable': 'electricidad', 'wire': 'electricidad', 'electricity': 'electricidad',
  'electrical supply': 'electricidad',
  // carpintería
  'wood': 'carpinteria', 'furniture': 'carpinteria', 'chair': 'carpinteria', 'table': 'carpinteria',
  'cabinetry': 'carpinteria', 'shelf': 'carpinteria', 'desk': 'carpinteria', 'drawer': 'carpinteria',
  'door': 'carpinteria', 'hardwood': 'carpinteria', 'plank': 'carpinteria',
  // pintura
  'paint': 'pintura', 'wall': 'pintura', 'graffiti': 'pintura', 'paint roller': 'pintura', 'ceiling': 'pintura',
  // jardinería
  'plant': 'jardineria', 'flower': 'jardineria', 'garden': 'jardineria', 'grass': 'jardineria', 'lawn': 'jardineria',
  'tree': 'jardineria', 'leaf': 'jardineria', 'shrub': 'jardineria', 'flowerpot': 'jardineria',
  'houseplant': 'jardineria',
  // cerrajería
  'lock': 'cerrajeria', 'key': 'cerrajeria', 'padlock': 'cerrajeria', 'door handle': 'cerrajeria',
};

/// Decide la categoría a partir de `(etiqueta, confianza)`.
///
/// Devuelve `null` (abstención) si ninguna categoría junta [minScore] o si
/// la segunda está a menos de [minMargin] de la primera.
CategoryGuess? guessFromLabels(
  List<(String, double)> labels, {
  double minScore = 0.55,
  double minMargin = 0.15,
  Set<String>? allowed,
  int latencyMs = 0,
}) {
  final score = <String, double>{};
  final why = <String, List<String>>{};
  for (final (raw, conf) in labels) {
    if (conf.isNaN || conf <= 0) continue;
    final cat = labelToCategory[raw.trim().toLowerCase()];
    if (cat == null || (allowed != null && !allowed.contains(cat))) continue;
    score[cat] = (score[cat] ?? 0) + conf.clamp(0, 1).toDouble();
    (why[cat] ??= []).add(raw);
  }
  if (score.isEmpty) return null;
  final ranked = score.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  final top = ranked.first;
  final second = ranked.length > 1 ? ranked[1].value : 0.0;
  if (top.value < minScore) return null;
  if (top.value - second < minMargin) return null;
  return CategoryGuess(
    category: top.key,
    confidence: top.value.clamp(0, 1).toDouble(),
    labels: why[top.key]!,
    latencyMs: latencyMs,
  );
}

abstract class CategorySuggester {
  /// `null` = el modelo se abstiene o no está disponible; nunca lanza.
  Future<CategoryGuess?> suggest(String imagePath, {Set<String>? allowed});
  Future<void> close();
}
