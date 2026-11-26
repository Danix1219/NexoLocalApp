import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/api_provider.dart';
import '../../../core/widgets/toast.dart';
import '../../location/location_picker_page.dart';
import '../../../app/router.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/widgets/nexo_icon.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/validation.dart';
import '../../../core/widgets/nexo_button.dart';
import '../../../core/widgets/nexo_field.dart';
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
  LocationPick? _location;
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

  bool get _valid => personNameOk(_name.text) && pwOk(_p1.text) && _p1.text == _p2.text && _terms && _location != null;

  Future<void> _submit() async {
    final flow = ref.read(signupFlowProvider);
    if (!_valid || _loading || flow.ticket == null) return;
    FocusScope.of(context).unfocus();
    final signup = ref.read(signupFlowProvider.notifier);
    final auth = ref.read(authRepositoryProvider);
    final session = ref.read(sessionProvider.notifier);
    final selectedLocation = ref.read(searchLocationProvider.notifier);
    final router = GoRouter.of(context);
    setState(() => _loading = true);
    try {
      final a = await ref
          .read(authRepositoryProvider)
          .createAccount(
            location: _location!.point,
            radiusKm: _location!.radiusKm,
            ticket: flow.ticket!,
            name: _name.text,
            password: _p1.text,
            intent: flow.intent,
            idempotencyKey: flow.idempotencyKey,
          );
      final name = a.name.isEmpty ? _name.text.trim() : a.name;
      signup.accountCreated(CreatedAccount(name: name, nextStep: a.nextStep, tokens: a.tokens));
      try {
        final tokens = a.tokens ?? await auth.login(flow.email, _p1.text);
        await session.signIn(tokens, name: name);
      } on ApiException {
        router.go(Routes.registerDone);
        return;
      }
      await selectedLocation.remember(_location!.point, _location!.radiusKm, zoneLabel: _location!.zoneLabel);
      // Account creation succeeded. A later location error must never repeat it.
      try {
        await selectedLocation.set(
          _location!.point,
          _location!.radiusKm,
          source: _location!.source,
          zoneLabel: _location!.zoneLabel,
        );
        signup.locationStored();
      } catch (_) {
        await selectedLocation.remember(_location!.point, _location!.radiusKm, zoneLabel: _location!.zoneLabel);
        showNexoToast(
          'Tu cuenta está creada. Puedes volver a guardar la ubicación desde la confirmación o desde Cuenta.',
        );
      }
      router.go(Routes.registerDone);
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

  Future<void> _pickLocation() async {
    final selected = await context.push<LocationPick>(
      Routes.location,
      extra: LocationPickerArgs(initial: _location?.point, radiusKm: _location?.radiusKm ?? 10),
    );
    if (selected != null && mounted) setState(() => _location = selected);
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(signupFlowProvider);
    return ObScaffold(
      icon: 'user',
      title: 'Completa tu cuenta',
      subtitle: 'Tu nombre, tu zona y una contraseña para entrar.',
      progress: 1,
      steps: 3,
      stepLabel: 'Tu cuenta · paso 3 de 3',
      onClose: () => confirmExitSignup(context, ref),
      content: [
        ObSection(
          title: 'Sobre ti',
          icon: 'user',
          children: [
            NexoField(
              label: 'Tu nombre',
              controller: _name,
              hint: 'Ej. María González',
              autofillHints: const [AutofillHints.name],
              textInputAction: TextInputAction.next,
              capitalization: TextCapitalization.words,
              maxLength: 80,
            ),
          ],
        ),
        ObSection(
          title: flow.intent == 'provider' ? '¿Dónde te encuentras?' : '¿Dónde buscas servicios?',
          icon: 'pin',
          children: [_LocationTile(location: _location, onTap: _pickLocation)],
        ),
        ObSection(
          title: 'Crea tu contraseña',
          icon: 'shield',
          children: [
            NexoPasswordField(label: 'Contraseña', controller: _p1, isNew: true, textInputAction: TextInputAction.next),
            NexoPasswordField(
              label: 'Confirma tu contraseña',
              controller: _p2,
              isNew: true,
              textInputAction: TextInputAction.done,
            ),
            PasswordRequirements(password: _p1.text, confirm: _p2.text),
          ],
        ),
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
              alignment: WrapAlignment.center,
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
        NexoButton(label: 'Finalizar', loading: _loading, onPressed: _valid && flow.ticket != null ? _submit : null),
      ],
    );
  }
}

/// Zona elegida: tarjeta que muestra lo seleccionado y permite cambiarlo.
class _LocationTile extends StatelessWidget {
  const _LocationTile({required this.location, required this.onTap});
  final LocationPick? location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = location;
    final name = l == null
        ? 'Elegir mi ubicación'
        : l.label ?? l.zoneLabel ?? '${l.point.lat.toStringAsFixed(3)}, ${l.point.lng.toStringAsFixed(3)}';
    return Semantics(
      button: true,
      child: Material(
        color: l == null ? NexoColors.field : NexoColors.brandSoft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: l == null ? NexoColors.line : NexoColors.brand, width: 1.3),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                NexoIcon(l == null ? 'pin' : 'check', size: 21, color: NexoColors.brand),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: NexoText.body(14.5, weight: FontWeight.w800)),
                      Text(
                        l == null ? 'Elige en el mapa tu zona y el radio' : 'Radio de ${l.radiusKm} km · Cambiar',
                        style: NexoText.body(12.5, color: NexoColors.muted),
                      ),
                    ],
                  ),
                ),
                const NexoIcon('chevron', size: 16, color: NexoColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
