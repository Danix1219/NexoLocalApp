/// Quita datos de contacto y domicilio antes de mandar texto al asistente de
/// IA generativa (spec 049 / 013: "GenAI no recibe contacto, domicilio ni
/// conversaciones privadas"). Se aplica en el teléfono, antes de la red.
String redactForAssist(String input) {
  var s = input;
  s = s.replaceAll(RegExp(r'https?://\S+|www\.\S+', caseSensitive: false), '[enlace]');
  s = s.replaceAll(RegExp(r'[\w.+-]+@[\w-]+(\.[\w-]+)+'), '[correo]');
  s = s.replaceAllMapped(RegExp(r'\+?\d[\d\s().-]{6,}\d'), (m) {
    final digits = m.group(0)!.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 8 ? '[teléfono]' : m.group(0)!;
  });
  s = s.replaceAll(
    RegExp(r'\b(calle|c\.|avenida|av\.?|privada|priv\.|callej[oó]n|andador|boulevard|blvd\.?)\s+[^,.;\n]{1,40}?\s*(#|n[uú]m\.?|no\.)?\s*\d+[a-z]?\b',
        caseSensitive: false),
    '[domicilio]',
  );
  return s.replaceAll(RegExp(r'[ \t]+'), ' ').trim();
}

/// Límite de lo que se manda al asistente (EP-082 `lengthLimit`).
const kAssistMaxInput = 600;
