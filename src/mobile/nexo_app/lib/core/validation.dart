// Reglas de entrada que la maqueta valida en el cliente. El servidor valida
// de nuevo; esto solo sirve para habilitar botones y dar retroalimentación.

/// `pwOK` de la maqueta: al menos 8 caracteres.
bool pwHasLength(String p) => p.length >= 8;

/// `pwOK`: al menos una letra y un número.
bool pwHasLetterAndDigit(String p) => RegExp(r'[A-Za-z]').hasMatch(p) && RegExp(r'\d').hasMatch(p);

/// Contrato: 8–64 caracteres, al menos una letra y un número.
bool pwOk(String p) => pwHasLength(p) && p.length <= 64 && pwHasLetterAndDigit(p);

String normalizeEmail(String e) => e.trim().toLowerCase();

/// Validación ligera: un `@` y un dominio con TLD. El servidor decide.
bool emailOk(String e) {
  final v = normalizeEmail(e);
  return v.length <= 254 && RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(v);
}

/// Contrato de `POST /accounts`: mínimo 2, máximo 80, ni solo espacios ni solo dígitos.
bool personNameOk(String n) {
  final v = n.trim();
  return v.length >= 2 && v.length <= 80 && !RegExp(r'^\d+$').hasMatch(v);
}

bool codeOk(String c) => RegExp(r'^\d{6}$').hasMatch(c);
