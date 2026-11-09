import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../core/widgets/nexo_button.dart';
import '../../core/widgets/nexo_field.dart';
import '../../core/widgets/nexo_sheet.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/ui.dart';
import '../../data/api_provider.dart';

/// Registrar y confirmar el celular (`POST /me/phone` + `/me/phone/confirm`).
Future<void> showPhoneSheet(BuildContext context, WidgetRef ref) =>
    showNexoSheet<void>(context, builder: (_) => const _PhoneSheet());

class _PhoneSheet extends ConsumerStatefulWidget {
  const _PhoneSheet();
  @override
  ConsumerState<_PhoneSheet> createState() => _PhoneSheetState();
}

class _PhoneSheetState extends ConsumerState<_PhoneSheet> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  String? _masked;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  String get _digits => _phone.text.replaceAll(RegExp(r'\D'), '');

  Future<void> _send() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final m = await ref.read(apiProvider).addPhone('+52$_digits');
      setState(() => _masked = m);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final nav = Navigator.of(context);
    try {
      await ref.read(apiProvider).confirmPhone(_code.text);
      ref.invalidate(accountProvider);
      ref.invalidate(myProviderProvider);
      nav.pop();
      showNexoToast('Celular confirmado');
    } catch (e) {
      if (mounted) setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_masked == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHeader('Confirma tu celular',
              subtitle:
                  'Te enviaremos un código por mensaje. Con el celular confirmado ganas la insignia de confianza.'),
          Container(
            decoration: BoxDecoration(
              color: NexoColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: NexoColors.line, width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                color: NexoColors.surface2,
                child: Text('+52', style: NexoText.body(16, weight: FontWeight.w800, color: NexoColors.muted)),
              ),
              Expanded(
                child: TextField(
                  controller: _phone,
                  autofocus: true,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumberNational],
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                  onChanged: (_) => setState(() {}),
                  style: NexoText.body(17, letterSpacing: .5),
                  decoration: const InputDecoration(
                    hintText: '771 555 0123',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          Text('Tu número no se publica. Solo se muestra si activas las llamadas.',
              style: NexoText.body(12.5, color: NexoColors.muted)),
          if (_error != null) ...[const SizedBox(height: 8), NexoError(_error!)],
          const SizedBox(height: 14),
          NexoButton(label: 'Enviar código', loading: _busy, onPressed: _digits.length == 10 ? _send : null),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader('Escribe el código', subtitle: 'Lo enviamos al $_masked.'),
        TextField(
          controller: _code,
          autofocus: true,
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
          textAlign: TextAlign.center,
          onChanged: (_) => setState(() {}),
          style: NexoText.display(26, letterSpacing: 10),
          decoration: nexoInputDecoration(hint: '······'),
        ),
        if (_error != null) ...[const SizedBox(height: 8), NexoError(_error!)],
        const SizedBox(height: 14),
        NexoButton(label: 'Confirmar', loading: _busy, onPressed: _code.text.length == 6 ? _confirm : null),
        const SizedBox(height: 6),
        NexoLink('Cambiar número', center: true, onTap: () => setState(() => _masked = null)),
      ],
    );
  }
}
