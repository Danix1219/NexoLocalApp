import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/env.dart';
import '../../../core/auth/auth_tokens.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/validation.dart';

class CodeDelivery {
  const CodeDelivery({
    this.expiresInSeconds = 900,
    this.resendAfterSeconds = 60,
    this.codeLength = 6,
  });

  factory CodeDelivery.fromJson(Map<String, dynamic>? j) => CodeDelivery(
        expiresInSeconds: (j?['expiresInSeconds'] as num?)?.toInt() ?? 900,
        resendAfterSeconds: (j?['resendAfterSeconds'] as num?)?.toInt() ?? 60,
        codeLength: (j?['codeLength'] as num?)?.toInt() ?? 6,
      );

  final int expiresInSeconds;
  final int resendAfterSeconds;
  final int codeLength;
}

class CodeConfirmation {
  const CodeConfirmation({required this.ticket, required this.accountExists});
  final String ticket;
  final bool accountExists;
}

class CreatedAccount {
  const CreatedAccount({
    required this.name,
    required this.nextStep,
    required this.tokens,
  });

  factory CreatedAccount.fromJson(Map<String, dynamic>? j) => CreatedAccount(
        name: (j?['name'] as String?) ?? '',
        nextStep: (j?['nextStep'] as String?) ?? 'home',
        tokens: j == null ? null : AuthTokens.tryFromAccount(j),
      );

  final String name;

  /// `home` o `createProvider`.
  final String nextStep;

  /// Null si el backend no devolvió sesión: la app inicia sesión enseguida.
  final AuthTokens? tokens;
}

/// Consumo de los endpoints de Identity. La app no decide nada que le toque
/// al servidor: solo envía, interpreta la respuesta y muestra el estado.
class AuthRepository {
  AuthRepository(this._dio);
  final Dio _dio;

  Future<T> _call<T>(Future<T> Function() f) async {
    try {
      return await f();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    } on ApiException {
      rethrow;
    } catch (e, st) {
      // La respuesta llegó, pero no tiene la forma del contrato.
      if (kDebugMode) debugPrint('[API] respuesta inesperada: $e\n$st');
      throw ApiException(code: 'client.unexpected_response', detail: kDebugMode ? '$e' : null);
    }
  }

  /// `POST /connect/token` (grant password). El usuario es el correo.
  Future<AuthTokens> login(String email, String password) => _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/connect/token',
          data: {
            'grant_type': 'password',
            'username': normalizeEmail(email),
            'password': password,
            'scope': Env.oauthScope,
            if (Env.oauthClientId.isNotEmpty) 'client_id': Env.oauthClientId,
          },
          options: Options(contentType: Headers.formUrlEncodedContentType),
        );
        return AuthTokens.fromOAuth(r.data!);
      });

  /// `POST /v1/identity/email/verification` (purpose signup).
  Future<CodeDelivery> sendSignupCode(String email) => _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/v1/identity/email/verification',
          data: {'email': normalizeEmail(email), 'purpose': 'signup'},
        );
        return CodeDelivery.fromJson(r.data);
      });

  /// `POST /v1/identity/password/forgot`.
  Future<CodeDelivery> requestPasswordReset(String email) => _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/v1/identity/password/forgot',
          data: {'email': normalizeEmail(email)},
        );
        return CodeDelivery.fromJson(r.data);
      });

  /// `POST /v1/identity/email/verification/confirm`.
  Future<CodeConfirmation> confirmCode(String email, String code) => _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/v1/identity/email/verification/confirm',
          data: {'email': normalizeEmail(email), 'code': code},
        );
        final j = r.data!;
        return CodeConfirmation(
          ticket: j['verificationTicket'] as String,
          accountExists: j['accountExists'] == true,
        );
      });

  /// `POST /v1/identity/accounts`. La [idempotencyKey] se reutiliza en los
  /// reintentos del mismo envío para no crear la cuenta dos veces.
  Future<CreatedAccount> createAccount({
    required String ticket,
    required String name,
    required String password,
    required String intent,
    required String idempotencyKey,
  }) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/v1/identity/accounts',
          data: {
            'verificationTicket': ticket,
            'name': name.trim(),
            'password': password,
            'acceptedTerms': true,
            'searchLocation': {'lat': Env.defaultLat, 'lng': Env.defaultLng},
            'searchZoneLabel': Env.defaultZone,
            'searchRadiusKm': Env.defaultRadiusKm,
            'intent': intent,
          },
          options: Options(headers: {'Idempotency-Key': idempotencyKey}),
        );
        if (kDebugMode) {
          // Solo los nombres de los campos: nunca los valores (traen tokens).
          debugPrint('[API] POST /v1/identity/accounts -> ${r.statusCode} campos: '
              '${r.data?.keys.toList()}');
        }
        return CreatedAccount.fromJson(r.data);
      });

  /// `POST /v1/identity/password/reset` → 204.
  Future<void> resetPassword({
    required String ticket,
    required String password,
    required String confirm,
  }) =>
      _call(() async {
        await _dio.post<void>(
          '/v1/identity/password/reset',
          data: {
            'verificationTicket': ticket,
            'password': password,
            'passwordConfirm': confirm,
          },
        );
      });

  /// `POST /v1/identity/logout` → 204. Nunca lanza: cerrar sesión siempre se
  /// completa en el dispositivo aunque el servidor no responda.
  Future<bool> logout(String refreshToken) async {
    try {
      await _dio.post<void>(
        '/v1/identity/logout',
        data: {'refreshToken': refreshToken, 'allDevices': false},
        options: Options(extra: {kAuth: true}),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(ref.read(dioProvider)));
