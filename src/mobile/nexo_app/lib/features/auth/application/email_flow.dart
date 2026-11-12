import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/auth_repository.dart';

enum EmailPurpose { signup, resetPassword }

/// Estado de un flujo correo → código → ticket (registro o recuperación).
/// Vive solo en memoria: el ticket no se guarda en disco.
class EmailFlowState {
  const EmailFlowState({
    this.email = '',
    this.sentAt,
    this.resendAfterSeconds = 60,
    this.ticket,
    this.intent = 'client',
    this.idempotencyKey = '',
    this.createdName,
    this.locationSaved = false,
    this.nextStep,
  });

  final String email;
  final DateTime? sentAt;
  final int resendAfterSeconds;
  final String? ticket;

  /// Solo registro: `client` o `provider` (pista de navegación, no permiso).
  final String intent;

  /// Solo registro: misma llave para los reintentos de un mismo envío.
  final String idempotencyKey;

  /// Solo registro: datos para la pantalla "Tu cuenta está lista".
  final String? createdName;
  final bool locationSaved;
  final String? nextStep;

  EmailFlowState copyWith({
    String? email,
    DateTime? sentAt,
    int? resendAfterSeconds,
    String? ticket,
    bool clearTicket = false,
    String? intent,
    String? idempotencyKey,
    String? createdName,
    bool? locationSaved,
    String? nextStep,
  }) =>
      EmailFlowState(
        email: email ?? this.email,
        sentAt: sentAt ?? this.sentAt,
        resendAfterSeconds: resendAfterSeconds ?? this.resendAfterSeconds,
        ticket: clearTicket ? null : (ticket ?? this.ticket),
        intent: intent ?? this.intent,
        idempotencyKey: idempotencyKey ?? this.idempotencyKey,
        createdName: createdName ?? this.createdName,
        locationSaved: locationSaved ?? this.locationSaved,
        nextStep: nextStep ?? this.nextStep,
      );
}

class EmailFlowController extends Notifier<EmailFlowState> {
  @override
  EmailFlowState build() => const EmailFlowState();

  void setIntent(String intent) => state = EmailFlowState(intent: intent == 'provider' ? 'provider' : 'client');

  void codeSent(String email, CodeDelivery d) {
    state = state.copyWith(
      email: email,
      sentAt: DateTime.now(),
      resendAfterSeconds: d.resendAfterSeconds,
      clearTicket: true,
    );
  }

  void ticketReady(String ticket) => state = state.copyWith(ticket: ticket, idempotencyKey: const Uuid().v4());

  void accountCreated(CreatedAccount a) => state = state.copyWith(createdName: a.name, nextStep: a.nextStep);

  void locationStored() => state = state.copyWith(locationSaved: true);

  void reset() => state = const EmailFlowState();
}

final signupFlowProvider = NotifierProvider<EmailFlowController, EmailFlowState>(EmailFlowController.new);

final resetFlowProvider = NotifierProvider<EmailFlowController, EmailFlowState>(EmailFlowController.new);

NotifierProvider<EmailFlowController, EmailFlowState> flowFor(EmailPurpose p) =>
    p == EmailPurpose.signup ? signupFlowProvider : resetFlowProvider;
