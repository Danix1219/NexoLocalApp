import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../core/widgets/nexo_icon.dart';
import '../../core/widgets/nexo_sheet.dart';
import '../../core/widgets/ui.dart';
import '../../data/nexo_api.dart';

class PublicationEditorShell extends StatelessWidget {
  const PublicationEditorShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.footer,
    this.error,
    this.dirty = false,
    this.busy = false,
  });

  /// Botón de guardar, siempre a la vista.
  final Widget? footer;

  /// Fallo al guardar: se muestra dentro de la hoja, junto al botón.
  final String? error;

  /// Hay cambios sin guardar: salir pide confirmación.
  final bool dirty, busy;
  final String title;
  final String subtitle;
  final List<Widget> children;

  Future<void> _askDiscard(BuildContext context) async {
    final discard = await confirmSheet(
      context,
      title: '¿Descartar tus cambios?',
      subtitle: 'Tu publicación se quedará como estaba.',
      confirmLabel: 'Descartar cambios',
      cancelLabel: 'Seguir editando',
      confirmFirst: false,
    );
    if (discard == true && context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !dirty && !busy,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && !busy) _askDiscard(context);
    },
    child: FractionallySizedBox(
      heightFactor: .94,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 18, 12),
              child: Row(
                children: [
                  Material(
                    color: NexoColors.surface,
                    shape: const CircleBorder(side: BorderSide(color: NexoColors.line)),
                    child: IconButton(
                      tooltip: 'Cerrar edición',
                      onPressed: busy ? null : () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close_rounded, color: NexoColors.ink, size: 21),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: NexoText.display(20, weight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(subtitle, style: NexoText.body(12.5, color: NexoColors.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(14, 2, 14, 24),
                children: children,
              ),
            ),
            if (footer != null)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                decoration: const BoxDecoration(
                  color: NexoColors.surface,
                  boxShadow: [BoxShadow(color: Color(0x141F302B), blurRadius: 16, offset: Offset(0, -4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      liveRegion: true,
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 180),
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 9),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                error != null
                                    ? Icons.error_outline_rounded
                                    : dirty
                                    ? Icons.circle
                                    : Icons.check_circle_outline_rounded,
                                size: dirty && error == null ? 10 : 17,
                                color: error != null
                                    ? NexoColors.danger
                                    : dirty
                                    ? NexoColors.accent
                                    : NexoColors.muted,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  error ?? (dirty ? 'Tienes cambios sin guardar' : 'Aún no has cambiado nada'),
                                  style: NexoText.body(
                                    12.5,
                                    weight: FontWeight.w700,
                                    color: error != null ? NexoColors.danger : NexoColors.muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    footer!,
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class EditorCard extends StatelessWidget {
  const EditorCard({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: NexoColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: NexoColors.line),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
  );
}

class EditorField extends StatelessWidget {
  const EditorField({
    super.key,
    required this.label,
    required this.controller,
    required this.limit,
    this.onChanged,
    this.lines = 1,
    this.hint,
  });
  final String label;
  final ValueChanged<String>? onChanged;
  final TextEditingController controller;
  final int limit;
  final int lines;
  final String? hint;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: NexoText.body(14, weight: FontWeight.w800)),
      const SizedBox(height: 9),
      TextField(
        controller: controller,
        onChanged: onChanged,
        maxLength: limit,
        minLines: lines,
        maxLines: lines == 1 ? 1 : lines + 3,
        textCapitalization: TextCapitalization.sentences,
        style: NexoText.body(15, height: 1.45),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: NexoText.body(14, color: NexoColors.muted),
          filled: true,
          fillColor: NexoColors.field,
          contentPadding: const EdgeInsets.all(14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: NexoColors.brand, width: 1.5),
          ),
          counterStyle: NexoText.body(11.5, color: NexoColors.muted),
        ),
      ),
    ],
  );
}

class EditorChoice extends StatelessWidget {
  const EditorChoice({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final List<(String, String)> options;
  final String value;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label, style: NexoText.body(14, weight: FontWeight.w800)),
      const SizedBox(height: 9),
      SegControl<String>(options: options, value: value, onChanged: onChanged),
    ],
  );
}

/// Barra para agregar fotos, con cuántas van. La usan publicar y editar.
class AddPhotosBar extends StatelessWidget {
  const AddPhotosBar({super.key, required this.count, required this.onTap});
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final full = count >= 6;
    final color = full ? NexoColors.ok : NexoColors.brand;
    return Semantics(
      button: !full,
      child: Material(
        color: full ? NexoColors.okSoft : NexoColors.brandSoft.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: full ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 7, 14, 7),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: NexoColors.surface, borderRadius: BorderRadius.circular(12)),
                  child: NexoIcon(full ? 'check' : 'camera', size: 19, color: color),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    full ? 'Fotos completas' : (count == 0 ? 'Agregar fotos' : 'Agregar más fotos'),
                    style: NexoText.body(14, weight: FontWeight.w800, color: color),
                  ),
                ),
                Text(
                  '$count/6',
                  style: NexoText.body(12.5, weight: FontWeight.w700, color: NexoColors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EditorPhotos extends StatelessWidget {
  const EditorPhotos({
    super.key,
    required this.photos,
    required this.picked,
    required this.busy,
    required this.onRemovePhoto,
    required this.onRemovePicked,
    required this.onAdd,
  });
  final List<String> photos;
  final List<PickedImage> picked;
  final bool busy;
  final ValueChanged<String> onRemovePhoto;
  final ValueChanged<PickedImage> onRemovePicked;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) {
    final items = <(String, VoidCallback)>[
      for (final url in photos) (url, () => onRemovePhoto(url)),
      for (final image in picked) ('file://${image.path}', () => onRemovePicked(image)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Fotos', style: NexoText.body(14, weight: FontWeight.w800)),
        const SizedBox(height: 9),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          alignment: Alignment.topCenter,
          child: items.isEmpty
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SizedBox(
                    height: 108,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 9),
                      itemBuilder: (_, i) => _tile(items[i].$1, items[i].$2, cover: i == 0),
                    ),
                  ),
                ),
        ),
        AddPhotosBar(count: items.length, onTap: busy ? null : onAdd),
      ],
    );
  }

  Widget _tile(String url, VoidCallback remove, {required bool cover}) => SizedBox.square(
    dimension: 108,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(17),
      child: Stack(
        fit: StackFit.expand,
        children: [
          NexoImage(url),
          if (cover)
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xDD1C2926), borderRadius: BorderRadius.circular(99)),
                child: Text(
                  'Portada',
                  style: NexoText.body(10.5, weight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ),
          Positioned(
            right: 5,
            top: 5,
            child: Material(
              color: const Color(0xDD1C2926),
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: 'Quitar foto',
                onPressed: busy ? null : remove,
                icon: const Icon(Icons.close, size: 15, color: Colors.white),
                // Pequeño para no tapar la foto.
                style: IconButton.styleFrom(
                  minimumSize: const Size(28, 28),
                  fixedSize: const Size(28, 28),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
