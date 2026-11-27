import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../core/widgets/nexo_button.dart';
import '../../core/widgets/nexo_sheet.dart';
import '../../core/widgets/ui.dart';

/// La publicación tal como se reconoce: su foto, su texto y sus detalles.
class PublicationPreview extends StatelessWidget {
  const PublicationPreview({super.key, required this.text, this.imageUrl, this.meta = '', this.photos = 0});
  final String text;
  final String? imageUrl;
  final String meta;
  final int photos;

  Widget _chip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(color: NexoColors.surface2, borderRadius: BorderRadius.circular(99)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: NexoColors.muted),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: NexoText.body(11.5, weight: FontWeight.w700, color: NexoColors.muted),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: NexoColors.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: NexoColors.line),
      boxShadow: const [BoxShadow(color: Color(0x141F302B), blurRadius: 20, offset: Offset(0, 8))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (imageUrl != null) AspectRatio(aspectRatio: 2.5, child: NexoImage(imageUrl!)),
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 13, 15, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                maxLines: imageUrl == null ? 4 : 2,
                overflow: TextOverflow.ellipsis,
                style: NexoText.body(14.5, weight: FontWeight.w600, height: 1.45),
              ),
              if (meta.isNotEmpty || photos > 1) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    if (meta.isNotEmpty) _chip(Icons.sell_outlined, meta),
                    if (photos > 1) _chip(Icons.photo_library_outlined, '$photos fotos'),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

/// Hoja de opciones de una publicación propia. Devuelve `edit` o `delete`.
/// Editar es la acción principal; eliminar queda aparte y en segundo plano.
Future<String?> showPublicationMenu(
  BuildContext context, {
  required String title,
  required Widget preview,
  required String? editLabel,
  String editDetail = 'Cambia el texto, las fotos y los detalles',
}) => showNexoSheet<String>(
  context,
  builder: (sheet) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SheetHeader(title, subtitle: 'Así la ven los demás.'),
      preview,
      const SizedBox(height: 16),
      if (editLabel != null) ...[
        Semantics(
          button: true,
          child: Material(
            color: NexoColors.brand,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.pop(sheet, 'edit'),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .16),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(Icons.edit_outlined, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            editLabel,
                            style: NexoText.body(15.5, weight: FontWeight.w800, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(editDetail, style: NexoText.body(12.5, color: Colors.white.withValues(alpha: .82))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 21),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
      ],
      TextButton.icon(
        onPressed: () => Navigator.pop(sheet, 'delete'),
        style: TextButton.styleFrom(foregroundColor: NexoColors.danger, minimumSize: const Size(0, 50)),
        icon: const Icon(Icons.delete_outline_rounded, size: 20),
        label: Text(
          'Eliminar publicación',
          style: NexoText.body(14, weight: FontWeight.w800, color: NexoColors.danger),
        ),
      ),
    ],
  ),
);

class _Consequence extends StatelessWidget {
  const _Consequence(this.text, {required this.icon, required this.color});
  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(color: color.withValues(alpha: .12), shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(text, style: NexoText.body(13.5, height: 1.4)),
          ),
        ),
      ],
    ),
  );
}

/// Confirmación de eliminar: se mantiene presionado, así no se borra por un
/// toque accidental. [onDelete] lanza si el servidor no confirma; el error se
/// muestra aquí mismo y la publicación se conserva.
Future<bool> confirmPublicationDelete(
  BuildContext context, {
  required Widget preview,
  required String loses,
  required String keeps,
  String? warning,
  required String keepLabel,
  required Future<void> Function() onDelete,
}) async {
  final deleted = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: NexoColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
    builder: (_) => _DeleteSheet(
      preview: preview,
      loses: loses,
      keeps: keeps,
      warning: warning,
      keepLabel: keepLabel,
      onDelete: onDelete,
    ),
  );
  return deleted == true;
}

/// Parte del botón ya rellenada.
class _Filled extends CustomClipper<Rect> {
  const _Filled(this.part);
  final double part;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * part, size.height);

  @override
  bool shouldReclip(_Filled old) => old.part != part;
}

class _DeleteSheet extends StatefulWidget {
  const _DeleteSheet({
    required this.preview,
    required this.loses,
    required this.keeps,
    required this.warning,
    required this.keepLabel,
    required this.onDelete,
  });
  final Widget preview;
  final String loses, keeps, keepLabel;
  final String? warning;
  final Future<void> Function() onDelete;

  @override
  State<_DeleteSheet> createState() => _DeleteSheetState();
}

class _DeleteSheetState extends State<_DeleteSheet> with SingleTickerProviderStateMixin {
  late final _hold = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) _delete();
    });
  bool _busy = false;
  bool _tapped = false;
  String? _error;

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  void _press() {
    if (_busy) return;
    unawaited(HapticFeedback.selectionClick());
    setState(() => _tapped = false);
    _hold.forward(from: _hold.value);
  }

  void _release() {
    // También con valor 0: un toque más rápido que un cuadro debe cancelar.
    if (_busy || _hold.isCompleted) return;
    // Un toque corto explica cómo se confirma.
    if (_hold.value < .35) setState(() => _tapped = true);
    _hold.reverse();
  }

  Future<void> _delete() async {
    if (_busy) return;
    unawaited(HapticFeedback.heavyImpact());
    _hold.value = 1;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onDelete();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _hold.reverse();
      setState(() {
        _busy = false;
        _error = apiErrorMessage(e);
      });
    }
  }

  Widget _holdButton() => Semantics(
    button: true,
    enabled: !_busy,
    label: 'Eliminar publicación',
    hint: 'Mantén presionado para confirmar',
    // Con lector de pantalla, la activación confirma directamente.
    onTap: _busy ? null : _delete,
    excludeSemantics: true,
    child: Listener(
      onPointerDown: (_) => _press(),
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: AnimatedBuilder(
        animation: _hold,
        builder: (_, __) {
          final label = _busy
              ? 'Eliminando…'
              : _hold.isAnimating && _hold.status == AnimationStatus.forward
              ? 'Sigue presionando…'
              : _tapped
              ? 'No sueltes hasta que se llene'
              : _error != null
              ? 'Mantén presionado para reintentar'
              : 'Mantén presionado para eliminar';
          // El texto se pinta dos veces: en rojo, y en blanco recortado al relleno.
          Widget content(Color ink) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_busy)
                SizedBox.square(dimension: 19, child: CircularProgressIndicator(strokeWidth: 2.2, color: ink))
              else
                Icon(Icons.delete_outline_rounded, size: 21, color: ink),
              const SizedBox(width: 9),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: NexoText.body(14.5, weight: FontWeight.w800, color: ink),
                ),
              ),
            ],
          );
          return ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: 58,
              color: NexoColors.danger.withValues(alpha: .1),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  content(NexoColors.danger),
                  ClipRect(
                    clipper: _Filled(_hold.value),
                    child: ColoredBox(color: NexoColors.danger, child: content(Colors.white)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 22, 20, 14 + MediaQuery.paddingOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text('¿Eliminar esta publicación?', style: NexoText.display(21))),
          const SizedBox(height: 4),
          Text('No se puede deshacer.', style: NexoText.body(13.5, color: NexoColors.muted)),
          const SizedBox(height: 16),
          // La publicación se va apagando mientras se confirma.
          AnimatedBuilder(
            animation: _hold,
            child: widget.preview,
            builder: (_, child) => Opacity(
              opacity: 1 - .55 * _hold.value,
              child: Transform.scale(scale: 1 - .05 * _hold.value, child: child),
            ),
          ),
          const SizedBox(height: 18),
          _Consequence(widget.loses, icon: Icons.visibility_off_outlined, color: NexoColors.danger),
          _Consequence(widget.keeps, icon: Icons.check_rounded, color: NexoColors.ok),
          if (widget.warning case final text?)
            _Consequence(text, icon: Icons.info_outline_rounded, color: NexoColors.warn),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  _error!,
                  style: NexoText.body(13, weight: FontWeight.w700, color: NexoColors.danger, height: 1.4),
                ),
              ),
            ),
          const SizedBox(height: 4),
          _holdButton(),
          const SizedBox(height: 9),
          NexoButton(
            label: widget.keepLabel,
            variant: NexoButtonVariant.line,
            onPressed: _busy ? null : () => Navigator.pop(context, false),
          ),
        ],
      ),
    ),
  );
}
