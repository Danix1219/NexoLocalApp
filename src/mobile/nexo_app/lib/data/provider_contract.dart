// Puente versionado hasta exponer el catálogo público del backend (bloque 04).
import 'fake/fake_seed.dart';

const _specialtySlugs = <String, List<String>>{
  'plomeria': ['fugas', 'calentadores', 'destapes', 'tinacos', 'banos'],
  'electricidad': ['residencial', 'comercial', 'tableros', 'cortos', 'iluminacion'],
  'carpinteria': ['cocinas', 'puertas', 'muebles', 'reparaciones', 'restauracion'],
  'pintura': ['interiores', 'exteriores', 'impermeabilizado', 'acabados', 'muros'],
  'jardineria': ['mantenimiento', 'poda', 'diseno', 'riego', 'pasto'],
  'cerrajeria': ['aperturas', 'chapas', 'llaves', 'seguridad', 'automotriz'],
  'otros': [],
};

List<String> providerSpecialtySlugs(List<String> categories, List<String> values) => [
      for (final value in values)
        (() {
          for (final cat in fakeCats.where((cat) => categories.contains(cat.id))) {
            final slugs = _specialtySlugs[cat.id] ?? const <String>[];
            if (slugs.contains(value)) return value;
            final index = cat.specs.indexOf(value);
            if (index >= 0 && index < slugs.length) return slugs[index];
          }
          throw const FormatException('La especialidad no pertenece a las categorías seleccionadas.');
        })(),
    ];

String providerSpecialtyLabel(List<String> categories, String value) {
  for (final cat in fakeCats.where((cat) => categories.contains(cat.id))) {
    final index = (_specialtySlugs[cat.id] ?? const <String>[]).indexOf(value);
    if (index >= 0 && index < cat.specs.length) return cat.specs[index];
  }
  return value;
}

String? responseTimeLabel(String? value) => switch (value) {
      'sameDay' => 'El mismo día',
      'h24' => 'En 24 h',
      'h48' => 'En 48 h',
      'week' => 'En la semana',
      _ => value,
    };
String paymentLabel(String value) => switch (value) {
      'cash' => 'Efectivo',
      'transfer' => 'Transferencia',
      'card' => 'Tarjeta',
      'deposit' => 'Depósito',
      'other' => 'Otro',
      _ => value,
    };
String centsInput(int cents) =>
    cents % 100 == 0 ? '${cents ~/ 100}' : '${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';
int? parseProviderMoney(String text) {
  final value = text.trim();
  if (!RegExp(r'^\d{1,6}([.,]\d{1,2})?$').hasMatch(value)) return null;
  final parts = value.replaceAll(',', '.').split('.');
  final cents = int.parse(parts[0]) * 100 + (parts.length == 2 ? int.parse(parts[1].padRight(2, '0')) : 0);
  return cents <= 99999900 ? cents : null;
}
