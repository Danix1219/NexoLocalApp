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

/// 7.2 vista `newpass` · `POST /v1/identity/password/reset`.
class NewPasswordPage extends ConsumerStatefulWidget {
  const NewPasswordPage({super.key});

  @override
  ConsumerState<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends ConsumerState<NewPasswordPage> {
  final _p1 = TextEditingController();
  final _p2 = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _ticketExpired = false;

  @override
  void initState() {
    super.initState();
    void changed() => setState(() => _error = null);
    _p1.addListener(changed);
    _p2.addListener(changed);
  }

  @override
  void dispose() {
    _p1.dispose();
    _p2.dispose();
    super.dispose();
  }

  bool get _valid => pwOk(_p1.text) && _p1.text == _p2.text;

  Future<void> _submit() async {
    final flow = ref.read(resetFlowProvider);
    if (!_valid || _loading || flow.ticket == null) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).resetPassword(
            ticket: flow.ticket!,
            password: _p1.text,
            confirm: _p2.text,
          );
      ref.read(resetFlowProvider.notifier).reset();
      if (mounted) context.go(Routes.forgotDone, extra: flow.email);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = authErrorMessage(e);
        _ticketExpired = e.code == 'email.ticket_invalid';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.read(resetFlowProvider).email;
    return ObScaffold(
      icon: 'shield',
      title: 'Crea una contraseña nueva',
      subtitle: 'Elige una contraseña distinta a la anterior.',
      content: [
        NexoPasswordField(
          label: 'Contraseña nueva',
          controller: _p1,
          isNew: true,
          textInputAction: TextInputAction.next,
        ),
        NexoPasswordField(
          label: 'Confirma la contraseña',
          controller: _p2,
          isNew: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
        PasswordRequirements(password: _p1.text, confirm: _p2.text),
        if (_error != null) NexoError(_error!),
        if (_ticketExpired)
          Align(
            alignment: Alignment.centerLeft,
            child: NexoButton(
              label: 'Pedir otro código',
              variant: NexoButtonVariant.ghost,
              block: false,
              small: true,
              onPressed: () => context.go(Routes.forgot, extra: email),
            ),
          ),
      ],
      footer: [
        NexoButton(
          label: 'Guardar contraseña',
          loading: _loading,
          onPressed: _valid ? _submit : null,
        ),
      ],
    );
  }
}
