import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/validation.dart';
import '../../../core/widgets/nexo_button.dart';
import '../../../core/widgets/nexo_field.dart';
import '../../../core/widgets/nexo_sheet.dart';
import '../../../core/widgets/ob_scaffold.dart';
import '../application/email_flow.dart';
import '../data/auth_repository.dart';
import 'auth_messages.dart';

/// `obexit`: "¿Salir del registro?".
Future<void> confirmExitSignup(BuildContext context, WidgetRef ref) async {
  final stay = await confirmSheet(
    context,
    title: '¿Salir del registro?',
    subtitle: 'Si sales ahora perderás los datos que llevas capturados.',
    confirmLabel: 'Seguir aquí',
    cancelLabel: 'Salir',
  );
  // En la maqueta el botón principal es "Seguir aquí"; solo se sale con "Salir".
  if (stay != false || !context.mounted) return;
  ref.read(signupFlowProvider.notifier).reset();
  context.go(Routes.welcome);
}

/// Registro, paso 1 de 3 (`phone` en la maqueta → ahora correo) ·
/// `POST /v1/identity/email/verification` (purpose signup).
class RegisterEmailPage extends ConsumerStatefulWidget {
  const RegisterEmailPage({super.key});

  @override
  ConsumerState<RegisterEmailPage> createState() => _RegisterEmailPageState();
}

class _RegisterEmailPageState extends ConsumerState<RegisterEmailPage> {
  late final _email = TextEditingController(text: ref.read(signupFlowProvider).email);
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
      final d = await ref.read(authRepositoryProvider).sendSignupCode(email);
      ref.read(signupFlowProvider.notifier).codeSent(email, d);
      if (mounted) context.push(Routes.registerCode);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(signupFlowProvider).intent == 'provider';
    return ObScaffold(
      icon: 'mail',
      title: provider ? 'Confirma tu correo' : '¿Cuál es tu correo?',
      subtitle: 'Te enviaremos un código para confirmar que eres tú.',
      progress: 1 / 3,
      stepLabel: 'Tu cuenta · paso 1 de 3',
      onClose: () => confirmExitSignup(context, ref),
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
          autofocus: true,
        ),
        NexoHint(provider
            ? 'Tu correo no se publica. Los clientes te escriben por chat dentro de la app.'
            : 'Tu correo no aparece en tu perfil. Lo usarás para iniciar sesión.'),
        if (_error != null) NexoError(_error!),
      ],
      footer: [
        NexoButton(
          label: 'Continuar',
          loading: _loading,
          onPressed: emailOk(_email.text) ? _submit : null,
        ),
      ],
    );
  }
}
