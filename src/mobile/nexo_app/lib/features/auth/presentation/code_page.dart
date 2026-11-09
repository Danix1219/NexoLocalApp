import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/typography.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/validation.dart';
import '../../../core/widgets/nexo_button.dart';
import '../../../core/widgets/nexo_field.dart';
import '../../../core/widgets/nexo_sheet.dart';
import '../../../core/widgets/ob_scaffold.dart';
import '../../../core/widgets/toast.dart';
import '../application/email_flow.dart';
import '../data/auth_repository.dart';
import 'auth_messages.dart';
import 'register_email_page.dart';

/// Paso `code` (registro) y vista `code` (recuperación) ·
/// `POST /v1/identity/email/verification/confirm`.
class CodePage extends ConsumerStatefulWidget {
  const CodePage({super.key, required this.purpose});
  final EmailPurpose purpose;

  @override
  ConsumerState<CodePage> createState() => _CodePageState();
}

class _CodePageState extends ConsumerState<CodePage> {
  final _code = TextEditingController();
  bool _loading = false;
  bool _resending = false;
  String? _error;
  Timer? _timer;
  int _wait = 0;
  String _lastAuto = '';

  bool get _signup => widget.purpose == EmailPurpose.signup;

  @override
  void initState() {
    super.initState();
    _code.addListener(_onCode);
    _wait = _remaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _onCode() {
    final t = _code.text;
    if (_error != null) setState(() => _error = null);
    // Envío automático al completar 6 dígitos, una vez por código escrito.
    if (codeOk(t) && t != _lastAuto) {
      _lastAuto = t;
      _submit();
    } else if (!codeOk(t)) {
      _lastAuto = '';
      setState(() {});
    }
  }

  int _remaining() {
    final f = ref.read(flowFor(widget.purpose));
    final until = f.sentAt?.add(Duration(seconds: f.resendAfterSeconds));
    if (until == null) return 0;
    return (until.difference(DateTime.now()).inSeconds + 1).clamp(0, 999);
  }

  void _tick() {
    final next = _remaining();
    if (next != _wait && mounted) setState(() => _wait = next);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!codeOk(_code.text) || _loading) return;
    final flow = ref.read(flowFor(widget.purpose));
    setState(() => _loading = true);
    try {
      final r = await ref.read(authRepositoryProvider).confirmCode(flow.email, _code.text);
      if (!mounted) return;
      if (_signup && r.accountExists) {
        await _accountExists(flow.email);
        return;
      }
      ref.read(flowFor(widget.purpose).notifier).ticketReady(r.ticket);
      context.push(_signup ? Routes.registerAccount : Routes.forgotNew);
    } on ApiException catch (e) {
      if (!mounted) return;
      // Primero se limpia el campo (su listener borra el error) y luego se muestra.
      if (e.code == 'email.code_invalid') _code.clear();
      setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// `accountExists` solo se conoce aquí, ya probado el control del buzón.
  Future<void> _accountExists(String email) async {
    final go = await confirmSheet(
      context,
      title: 'Ya tienes una cuenta',
      subtitle: 'Este correo ya está registrado. Inicia sesión con tu contraseña.',
      confirmLabel: 'Iniciar sesión',
      cancelLabel: 'Usar otro correo',
    );
    if (!mounted) return;
    if (go == true) {
      context.go(Routes.login, extra: email);
    } else if (go == false) {
      context.pop();
    }
  }

  Future<void> _resend() async {
    if (_wait > 0 || _resending) return;
    final email = ref.read(flowFor(widget.purpose)).email;
    setState(() => _resending = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final d = _signup
          ? await repo.sendSignupCode(email)
          : await repo.requestPasswordReset(email);
      ref.read(flowFor(widget.purpose).notifier).codeSent(email, d);
      _code.clear();
      _tick();
      showNexoToast('Código reenviado');
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  String get _resendLabel {
    if (_wait <= 0) return 'Reenviar código';
    final m = _wait ~/ 60, s = (_wait % 60).toString().padLeft(2, '0');
    return 'Reenviar código ($m:$s)';
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(flowFor(widget.purpose)).email;
    return ObScaffold(
      icon: _signup ? 'chat' : 'mail',
      title: 'Escribe el código',
      subtitle: 'Lo enviamos a $email.',
      progress: _signup ? 2 / 3 : null,
      stepLabel: _signup ? 'Tu cuenta · paso 2 de 3' : null,
      onClose: _signup ? () => confirmExitSignup(context, ref) : null,
      content: [
        NexoField(
          label: 'Código de 6 dígitos',
          controller: _code,
          hint: '······',
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 6,
          textAlign: TextAlign.center,
          autofocus: true,
          style: NexoText.display(28, weight: FontWeight.w700, letterSpacing: 12),
          helper: 'Revisa también tu carpeta de spam. El código vence en 15 minutos.',
        ),
        if (_error != null) NexoError(_error!),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            NexoButton(
              label: _resendLabel,
              variant: NexoButtonVariant.ghost,
              block: false,
              small: true,
              loading: _resending,
              onPressed: _wait > 0 ? null : _resend,
            ),
            if (_signup)
              NexoButton(
                label: 'Cambiar correo',
                variant: NexoButtonVariant.ghost,
                block: false,
                small: true,
                onPressed: () => context.pop(),
              ),
          ],
        ),
      ],
      footer: [
        NexoButton(
          label: 'Continuar',
          loading: _loading,
          onPressed: codeOk(_code.text) ? _submit : null,
        ),
      ],
    );
  }
}
