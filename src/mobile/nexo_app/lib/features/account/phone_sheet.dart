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
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
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
      ref.invalidate(accountProvider);
      if (mounted) Navigator.of(context).pop();
      showNexoToast('Celular guardado: $m');
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetHeader(
          'Celular de contacto',
          subtitle: 'Guarda tu celular de contacto. La cuenta se verifica mediante tu correo electrónico.',
        ),
        Container(
          decoration: BoxDecoration(
            color: NexoColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: NexoColors.line, width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 15,
                ),
                color: NexoColors.surface2,
                child: Text(
                  '+52',
                  style: NexoText.body(
                    16,
                    weight: FontWeight.w800,
                    color: NexoColors.muted,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _phone,
                  autofocus: true,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumberNational],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  onChanged: (_) => setState(() {}),
                  style: NexoText.body(17, letterSpacing: .5),
                  decoration: const InputDecoration(
                    hintText: '771 555 0123',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tu número no se publica. Solo se muestra si activas las llamadas.',
          style: NexoText.body(12.5, color: NexoColors.muted),
        ),
        if (_error != null) ...[const SizedBox(height: 8), NexoError(_error!)],
        const SizedBox(height: 14),
        NexoButton(
          label: 'Guardar celular',
          loading: _busy,
          onPressed: _digits.length == 10 ? _send : null,
        ),
      ],
    );
  }
}
