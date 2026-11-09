import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/validation.dart';
import '../../../core/widgets/nexo_button.dart';
import '../../../core/widgets/nexo_field.dart';
import '../../../core/widgets/ob_scaffold.dart';
import '../application/email_flow.dart';
import '../data/auth_repository.dart';
import 'auth_messages.dart';

/// 7.2 vista `forgot` · `POST /v1/identity/password/forgot`.
/// La respuesta es igual exista o no la cuenta (sin enumeración).
class ForgotPage extends ConsumerStatefulWidget {
  const ForgotPage({super.key, this.initialEmail});
  final String? initialEmail;

  @override
  ConsumerState<ForgotPage> createState() => _ForgotPageState();
}

class _ForgotPageState extends ConsumerState<ForgotPage> {
  late final _email = TextEditingController(text: widget.initialEmail ?? '');
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _email.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!emailOk(_email.text) || _loading) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final email = normalizeEmail(_email.text);
      final d = await ref.read(authRepositoryProvider).requestPasswordReset(email);
      ref.read(resetFlowProvider.notifier).codeSent(email, d);
      if (mounted) context.push(Routes.forgotCode);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ObScaffold(
      icon: 'key',
      title: 'Recupera tu contraseña',
      subtitle: 'Escribe el correo con el que creaste tu cuenta y te enviaremos un código.',
      content: [
        NexoField(
          label: 'Correo electrónico',
          controller: _email,
          hint: 'tu@correo.com',
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => _submit(),
          maxLength: 254,
          helper: 'Por seguridad, te enviamos el código si el correo tiene una cuenta.',
        ),
        if (_error != null) NexoError(_error!),
      ],
      footer: [
        NexoButton(
          label: 'Enviar código',
          loading: _loading,
          onPressed: emailOk(_email.text) ? _submit : null,
        ),
      ],
    );
  }
}
