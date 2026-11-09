import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/env.dart';
import '../../../app/router.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/validation.dart';
import '../../../core/widgets/nexo_button.dart';
import '../../../core/widgets/nexo_field.dart';
import '../../../core/widgets/nexo_icon.dart';
import '../../../core/widgets/nexo_sheet.dart';
import '../../../core/widgets/ob_scaffold.dart';
import '../application/email_flow.dart';
import '../data/auth_repository.dart';
import 'auth_messages.dart';
import 'legal_sheets.dart';
import 'register_email_page.dart';

/// Registro, paso 3 de 3 (`who` + `passBlock`): nombre, zona, contraseña y
/// términos · `POST /v1/identity/accounts`.
class RegisterAccountPage extends ConsumerStatefulWidget {
  const RegisterAccountPage({super.key});

  @override
  ConsumerState<RegisterAccountPage> createState() => _RegisterAccountPageState();
}

class _RegisterAccountPageState extends ConsumerState<RegisterAccountPage> {
  final _name = TextEditingController();
  final _p1 = TextEditingController();
  final _p2 = TextEditingController();
  bool _terms = false;
  bool _loading = false;
  String? _error;
  String? _errorCode;

  @override
  void initState() {
    super.initState();
    void changed() => setState(() {
          _error = null;
          _errorCode = null;
        });
    _name.addListener(changed);
    _p1.addListener(changed);
    _p2.addListener(changed);
  }

  @override
  void dispose() {
    _name.dispose();
    _p1.dispose();
    _p2.dispose();
    super.dispose();
  }

  bool get _valid => personNameOk(_name.text) && pwOk(_p1.text) && _p1.text == _p2.text && _terms;

  Future<void> _submit() async {
    final flow = ref.read(signupFlowProvider);
    if (!_valid || _loading || flow.ticket == null) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final a = await ref.read(authRepositoryProvider).createAccount(
            ticket: flow.ticket!,
            name: _name.text,
            password: _p1.text,
            intent: flow.intent,
            idempotencyKey: flow.idempotencyKey,
          );
      final name = a.name.isEmpty ? _name.text.trim() : a.name;
      ref
          .read(signupFlowProvider.notifier)
          .accountCreated(CreatedAccount(name: name, nextStep: a.nextStep, tokens: a.tokens));
      // El registro no devuelve sesión (contrato): se inicia con lo recién creado.
      final tokens = a.tokens ?? await ref.read(authRepositoryProvider).login(flow.email, _p1.text);
      // Al iniciar sesión, el router lleva de aquí a "Tu cuenta está lista".
      await ref.read(sessionProvider.notifier).signIn(tokens, name: name);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = authErrorMessage(e);
        _errorCode = e.code;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(signupFlowProvider);
    return ObScaffold(
      icon: 'user',
      title: 'Completa tu cuenta',
      subtitle: 'Tu nombre, tu zona y una contraseña para entrar.',
      progress: 1,
      stepLabel: 'Tu cuenta · paso 3 de 3',
      onClose: () => confirmExitSignup(context, ref),
      content: [
        NexoField(
          label: 'Tu nombre',
          controller: _name,
          hint: 'Ej. María González',
          autofillHints: const [AutofillHints.name],
          textInputAction: TextInputAction.next,
          capitalization: TextCapitalization.words,
          maxLength: 80,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('¿Dónde buscas servicios?', style: NexoText.body(14, weight: FontWeight.w700)),
            const SizedBox(height: 7),
            const _DefaultLocation(),
          ],
        ),
        Text('Crea tu contraseña', style: NexoText.body(14, weight: FontWeight.w700)),
        NexoPasswordField(
          label: 'Contraseña',
          controller: _p1,
          isNew: true,
          textInputAction: TextInputAction.next,
        ),
        NexoPasswordField(
          label: 'Confirma tu contraseña',
          controller: _p2,
          isNew: true,
          textInputAction: TextInputAction.done,
        ),
        PasswordRequirements(password: _p1.text, confirm: _p2.text),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OptRow(
              icon: _terms ? 'check' : 'shield',
              label: 'Acepto los Términos de uso y el Aviso de privacidad.',
              selected: _terms,
              onTap: () => setState(() => _terms = !_terms),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 16,
              children: [
                NexoLink('Leer Términos', onTap: () => showTermsSheet(context)),
                NexoLink('Leer Aviso de privacidad', onTap: () => showPrivacySheet(context)),
              ],
            ),
          ],
        ),
        if (_error != null) NexoError(_error!),
        if (_errorCode == 'email.already_registered')
          Align(
            alignment: Alignment.centerLeft,
            child: NexoButton(
              label: 'Iniciar sesión',
              variant: NexoButtonVariant.ghost,
              block: false,
              small: true,
              onPressed: () => context.go(Routes.login, extra: flow.email),
            ),
          ),
        if (_errorCode == 'email.ticket_invalid')
          Align(
            alignment: Alignment.centerLeft,
            child: NexoButton(
              label: 'Volver a pedir el código',
              variant: NexoButtonVariant.ghost,
              block: false,
              small: true,
              onPressed: () => context.go(Routes.registerEmail),
            ),
          ),
      ],
      footer: [
        NexoButton(
          label: 'Finalizar',
          loading: _loading,
          onPressed: _valid && flow.ticket != null ? _submit : null,
        ),
      ],
    );
  }
}

/// Ubicación por defecto (la maqueta la toma de `S.loc`, zona Centro). El
/// selector de mapa con radio es de otra spec; aquí solo se muestra.
class _DefaultLocation extends StatelessWidget {
  const _DefaultLocation();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: 'Ubicación: ${Env.defaultZone}',
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: NexoColors.brandSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: NexoColors.line, width: 1.5),
            ),
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _GridPainter())),
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: NexoColors.brand.withValues(alpha: .16),
                      border: Border.all(color: NexoColors.brand, width: 2),
                    ),
                  ),
                ),
                const Align(
                  alignment: Alignment(0, -.15),
                  child: NexoIcon('pin', size: 38, color: Colors.white, fillColor: NexoColors.accent),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 10,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                      decoration: BoxDecoration(
                        color: NexoColors.surface,
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: const [
                          BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const NexoIcon('pin', size: 15, color: NexoColors.brand),
                          const SizedBox(width: 6),
                          Text('${Env.defaultZone} · hasta ${Env.defaultRadiusKm} km',
                              style: NexoText.body(13, weight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const NexoIcon('pin', size: 14, color: NexoColors.brand),
            const SizedBox(width: 6),
            Expanded(
              child: Text('Ubicación predeterminada. Podrás cambiarla después en Cuenta.',
                  style: NexoText.body(12.5, color: NexoColors.muted)),
            ),
          ],
        ),
      ],
    );
  }
}

/// Cuadrícula tenue que imita el fondo del mapa sin cargar mosaicos.
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0x2E788C8C)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}
