import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';

String _minutes(Duration d) {
  final m = (d.inSeconds / 60).ceil();
  return m <= 1 ? '1 minuto' : '$m minutos';
}

/// Traduce los códigos estables de la API a textos de la maqueta. Los mensajes
/// de credenciales son únicos para no delatar si un correo existe.
String authErrorMessage(ApiException e) {
  final c = e.code;
  if (e.isNetwork || c == 'server.dependency_unavailable') {
    return 'No pudimos conectar. Revisa tu conexión e intenta de nuevo.';
  }
  if (c.contains('pending_deletion')) {
    return e.detail ?? 'Tu cuenta está en proceso de eliminación. Recupera tu contraseña para entrar y cancelarla.';
  }
  switch (c) {
    case 'auth.invalid_credentials':
    case 'invalid_grant':
      return 'El correo o la contraseña no son correctos.';
    case 'auth.account_locked':
      final wait = e.retryAfter == null ? '' : ' o espera ${_minutes(e.retryAfter!)}';
      return 'Demasiados intentos. Recupera tu contraseña para continuar$wait.';
    case 'auth.email_not_verified':
      return 'Tu correo aún no está verificado.';
    case 'rate.limit_exceeded':
    case 'email.too_many_codes':
      return 'Hiciste muchos intentos. Espera un momento y vuelve a intentar.';
    case 'email.invalid':
      return 'Revisa que el correo esté bien escrito.';
    case 'email.code_invalid':
      return 'El código no es correcto.';
    case 'email.code_expired':
      return 'El código venció. Pide uno nuevo.';
    case 'email.too_many_attempts':
      return 'Demasiados intentos con este código. Pide uno nuevo.';
    case 'email.ticket_invalid':
      return 'La verificación venció. Vuelve a pedir el código.';
    case 'email.already_registered':
      return 'Ya hay una cuenta con este correo.';
    case 'password.too_weak':
      return 'La contraseña necesita al menos 8 caracteres, una letra y un número.';
    case 'password.mismatch':
      return 'Las contraseñas no coinciden.';
    case 'password.same_as_current':
      return 'Elige una contraseña distinta a la anterior.';
    case 'resource.not_found':
      return 'Esta cuenta ya no existe.';
    case 'validation_failed':
      return e.detail ?? 'Revisa los datos e intenta de nuevo.';
    default:
      final base = e.detail ?? 'Algo salió mal. Intenta de nuevo.';
      // En debug se muestra el código para poder diagnosticar.
      return kDebugMode ? '$base [${e.status ?? '-'} · $c]' : base;
  }
}
