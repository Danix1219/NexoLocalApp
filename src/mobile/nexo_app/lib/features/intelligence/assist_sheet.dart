import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../core/network/api_exception.dart';
import '../../core/widgets/nexo_button.dart';
import '../../core/widgets/nexo_icon.dart';
import '../../core/widgets/nexo_sheet.dart';
import '../../core/widgets/ui.dart';
import '../../data/api_provider.dart';
import '../../data/nexo_api.dart';
import 'category_suggester.dart';
import 'redact.dart';

/// Mensaje cuando el asistente no puede responder: la persona sigue
/// escribiendo a mano (spec 049, AC-003).
String assistErrorMessage(Object e) {
  if (e is ApiException) {
    if (e.code == 'content.inappropriate')
      return 'El texto no cumple las reglas de la comunidad. Cámbialo e inténtalo de nuevo.';
    if (e.status == 429) return 'Usaste el asistente muchas veces. Espera un momento o escribe tú el texto.';
    if (e.code == 'assist.unavailable' || e.isNetwork || isUnavailable(e)) {
      return 'El asistente no está disponible ahora. Puedes escribir tu texto normalmente.';
    }
  }
  return apiErrorMessage(e);
}

/// Botón "Ayúdame a redactar" (IA generativa). Abre una hoja con el borrador;
/// nada se publica desde aquí.
class AssistButton extends StatelessWidget {
  const AssistButton({super.key, required this.enabled, required this.onTap});
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: enabled ? onTap : null,
      icon: NexoIcon('star', size: 18, color: enabled ? NexoColors.brand : NexoColors.muted),
      label: Text('Ayúdame a redactar',
          style: NexoText.body(14, weight: FontWeight.w700, color: enabled ? NexoColors.brand : NexoColors.muted)),
    );
  }
}

/// Devuelve el texto aceptado (ya editable en el campo) o `null`.
Future<String?> showAssistSheet(
  BuildContext context, {
  required String kind,
  required String category,
  required String userText,
}) =>
    showNexoSheet<String>(
      context,
      builder: (_) => _AssistSheet(kind: kind, category: category, userText: userText),
    );

class _AssistSheet extends ConsumerStatefulWidget {
  const _AssistSheet({required this.kind, required this.category, required this.userText});
  final String kind;
  final String category;
  final String userText;

  @override
  ConsumerState<_AssistSheet> createState() => _AssistSheetState();
}

class _AssistSheetState extends ConsumerState<_AssistSheet> {
  final _draft = TextEditingController();
  bool _busy = true;
  String? _error;
  String _model = '';

  @override
  void initState() {
    super.initState();
    _ask();
  }

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final clean = redactForAssist(widget.userText);
      final d = await ref.read(apiProvider).assistDraft(
            kind: widget.kind,
            category: widget.category,
            userText: clean.length > kAssistMaxInput ? clean.substring(0, kAssistMaxInput) : clean,
            lengthLimit: widget.kind == 'work' ? 1000 : 600,
          );
      if (!mounted) return;
      setState(() {
        _draft.text = d.text;
        _model = d.modelVersion;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = assistErrorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final demo = _model.startsWith('demo');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetHeader('Borrador sugerido',
            subtitle:
                'Revísalo y cámbialo a tu gusto. No incluye precios ni datos de contacto, y no se publica hasta que tú lo hagas.'),
        const SizedBox(height: 12),
        if (_busy)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(child: CircularProgressIndicator(color: NexoColors.brand)),
          )
        else if (_error != null) ...[
          Notice(_error!, icon: 'info', tone: BadgeTone.warn),
          const SizedBox(height: 12),
          NexoButton(label: 'Intentar de nuevo', variant: NexoButtonVariant.line, onPressed: _ask),
        ] else ...[
          Semantics(
            label: 'Borrador editable',
            child: TextField(
              controller: _draft,
              minLines: 4,
              maxLines: 10,
              maxLength: widget.kind == 'work' ? 1000 : 600,
              style: NexoText.body(15, height: 1.45),
              decoration: InputDecoration(
                filled: true,
                fillColor: NexoColors.surface2,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ),
          Text(
            demo
                ? 'Ejemplo de prueba (sin IA): solo en modo de desarrollo.'
                : 'Generado con IA${_model.isEmpty ? '' : ' · $_model'}. Puede equivocarse: revísalo.',
            style: NexoText.body(12, color: NexoColors.muted),
          ),
          const SizedBox(height: 12),
          NexoButton(
            label: 'Usar este texto',
            onPressed: () {
              final t = _draft.text.trim();
              Navigator.of(context).pop(t.isEmpty ? null : t);
            },
          ),
        ],
        const SizedBox(height: 8),
        NexoButton(
            label: 'Seguir escribiendo yo',
            variant: NexoButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }
}

/// Aviso con la sugerencia del modelo de visión: muestra la confianza y deja
/// usarla o ignorarla (spec 049, AC-002).
class CategoryGuessNotice extends StatelessWidget {
  const CategoryGuessNotice(
      {super.key, required this.guess, required this.name, required this.onUse, required this.onDismiss});
  final CategoryGuess guess;
  final String name;
  final VoidCallback onUse;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final pct = (guess.confidence * 100).round();
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(color: NexoColors.brandSoft, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        const NexoIcon('star', size: 18, color: NexoColors.brandDeep),
        const SizedBox(width: 8),
        Expanded(
          child: Semantics(
            liveRegion: true,
            child: Text('Por la foto parece $name ($pct % de confianza).',
                style: NexoText.body(13.5, weight: FontWeight.w600, color: NexoColors.brandDeep)),
          ),
        ),
        TextButton(
            onPressed: onUse,
            child: Text('Usar', style: NexoText.body(14, weight: FontWeight.w800, color: NexoColors.brand))),
        IconButton(
          tooltip: 'Ignorar sugerencia',
          visualDensity: VisualDensity.compact,
          onPressed: onDismiss,
          icon: const NexoIcon('close', size: 16, color: NexoColors.brandDeep),
        ),
      ]),
    );
  }
}
