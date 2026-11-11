import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../core/widgets/nexo_icon.dart';
import '../../core/widgets/ui.dart';
import '../../data/nexo_api.dart';

class PublicationEditorShell extends StatelessWidget {
  const PublicationEditorShell({super.key, required this.title, required this.subtitle, required this.children});
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
        heightFactor: .94,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: Column(children: [
            const SizedBox(height: 10),
            Center(
                child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(color: NexoColors.line, borderRadius: BorderRadius.circular(9)))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 15, 12, 14),
              child: Row(children: [
                Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: NexoText.display(22, weight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: NexoText.body(12.5, color: NexoColors.muted)),
                ])),
                IconButton(
                    tooltip: 'Cerrar edición',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: NexoColors.ink)),
              ]),
            ),
            const Divider(height: 1, color: NexoColors.line),
            Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 28), children: children)),
          ]),
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
            border: Border.all(color: NexoColors.line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      );
}

class EditorField extends StatelessWidget {
  const EditorField(
      {super.key, required this.label, required this.controller, required this.limit, this.lines = 1, this.hint});
  final String label;
  final TextEditingController controller;
  final int limit;
  final int lines;
  final String? hint;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: NexoText.body(14, weight: FontWeight.w800)),
        const SizedBox(height: 9),
        TextField(
          controller: controller,
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
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: NexoColors.line)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: NexoColors.line)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: NexoColors.brand, width: 1.5)),
            counterStyle: NexoText.body(11.5, color: NexoColors.muted),
          ),
        ),
      ]);
}

class EditorChoice extends StatelessWidget {
  const EditorChoice(
      {super.key, required this.label, required this.options, required this.value, required this.onChanged});
  final String label;
  final List<(String, String)> options;
  final String value;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: NexoText.body(14, weight: FontWeight.w800)),
        const SizedBox(height: 9),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final option in options)
            ChoiceChip(
              label: Text(option.$2),
              selected: value == option.$1,
              onSelected: (_) => onChanged(option.$1),
              showCheckmark: false,
              selectedColor: NexoColors.brandSoft,
              backgroundColor: NexoColors.surface,
              side: BorderSide(color: value == option.$1 ? NexoColors.brand : NexoColors.line),
              labelStyle: NexoText.body(13,
                  weight: FontWeight.w700, color: value == option.$1 ? NexoColors.brandDeep : NexoColors.muted),
            ),
        ]),
      ]);
}

class EditorPhotos extends StatelessWidget {
  const EditorPhotos(
      {super.key,
      required this.photos,
      required this.picked,
      required this.busy,
      required this.onRemovePhoto,
      required this.onRemovePicked,
      required this.onAdd});
  final List<String> photos;
  final List<PickedImage> picked;
  final bool busy;
  final ValueChanged<String> onRemovePhoto;
  final ValueChanged<PickedImage> onRemovePicked;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) {
    final count = photos.length + picked.length;
    return EditorCard(children: [
      Row(children: [
        const NexoIcon('camera', size: 19, color: NexoColors.brand),
        const SizedBox(width: 8),
        Expanded(child: Text('Fotos de la publicación', style: NexoText.body(14, weight: FontWeight.w800))),
        Text('$count/6', style: NexoText.body(12, color: NexoColors.muted)),
      ]),
      const SizedBox(height: 5),
      Text('Desliza para verlas. Puedes quitar o agregar fotos.', style: NexoText.body(12, color: NexoColors.muted)),
      if (count > 0) ...[
        const SizedBox(height: 14),
        SizedBox(
            height: 106,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (final url in photos) _tile(url, () => onRemovePhoto(url)),
              for (final image in picked) _tile('file://${image.path}', () => onRemovePicked(image)),
            ])),
      ],
      if (count < 6) ...[
        const SizedBox(height: 9),
        OutlinedButton.icon(
            onPressed: busy ? null : onAdd,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Agregar fotos')),
      ],
    ]);
  }

  Widget _tile(String url, VoidCallback remove) => Padding(
        padding: const EdgeInsets.only(right: 9),
        child: SizedBox(
            width: 106,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Stack(fit: StackFit.expand, children: [
                NexoImage(url),
                Positioned(
                    right: 4,
                    top: 4,
                    child: Material(
                      color: const Color(0xDD1C2926),
                      shape: const CircleBorder(),
                      child: IconButton(
                          tooltip: 'Quitar foto',
                          onPressed: busy ? null : remove,
                          icon: const Icon(Icons.close, size: 16, color: Colors.white),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.zero),
                    )),
              ]),
            )),
      );
}
