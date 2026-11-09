import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/validation.dart';
import '../../../core/widgets/nexo_button.dart';
import '../../../core/widgets/nexo_field.dart';
import '../../../core/widgets/ob_scaffold.dart';
import '../../../core/widgets/toast.dart';
import '../data/auth_repository.dart';
import 'auth_messages.dart';
import 'signup_sheet.dart';

/// 7.2 vista `login` · `POST /connect/token` (grant password).
/// Sin botones de cuentas de prueba (contrato: no se publican).
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, this.initialEmail});
  final String? initialEmail;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  late final _email = TextEditingController(text: widget.initialEmail ?? '');
  final _pass = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _email.addListener(_changed);
    _pass.addListener(_changed);
  }

  void _changed() => setState(() => _error = null);

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  bool get _valid => emailOk(_email.text) && _pass.text.isNotEmpty;

  Future<void> _submit() async {
    if (!_valid || _loading) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tokens = await ref.read(authRepositoryProvider).login(_email.text, _pass.text);
      TextInput.finishAutofillContext();
      await ref.read(sessionProvider.notifier).signIn(tokens);
      showNexoToast('Bienvenido');
      // El router redirige a /home al cambiar la sesión.
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: ObScaffold(
        icon: 'user',
        title: 'Inicia sesión',
        subtitle: 'Usa tu correo y tu contraseña.',
        content: [
          NexoField(
            label: 'Correo electrónico',
            controller: _email,
            hint: 'tu@correo.com',
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email, AutofillHints.username],
            textInputAction: TextInputAction.next,
            maxLength: 254,
          ),
          NexoPasswordField(
            label: 'Contraseña',
            controller: _pass,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null) NexoError(_error!),
          Align(
            alignment: Alignment.centerLeft,
            child: NexoLink(
              '¿Olvidaste tu contraseña?',
              onTap: () => context.push(Routes.forgot, extra: _email.text.trim()),
            ),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('¿Aún no tienes cuenta?',
                  style: NexoText.body(12.5, color: NexoColors.muted)),
              NexoLink('Crear cuenta', onTap: () => showSignupSheet(context)),
            ],
          ),
        ],
        footer: [
          NexoButton(
            label: 'Entrar',
            loading: _loading,
            onPressed: _valid ? _submit : null,
          ),
        ],
      ),
    );
  }
}
