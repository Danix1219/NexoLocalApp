import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/tokens.dart';
import '../../core/widgets/nexo_button.dart';
import '../../core/widgets/pick_image.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/ui.dart';
import '../../data/nexo_api.dart';
import '../../data/api_provider.dart';
import '../../data/models.dart';
import 'publication_editor_ui.dart';

String? _mediaId(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.path.startsWith('/v1/discovery/media/')) return null;
  final id = uri.pathSegments.last;
  return RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(id) ? id : null;
}

Future<Work?> showWorkEditor(BuildContext context, WidgetRef ref, Work work) async {
  final title = TextEditingController(text: work.title);
  final text = TextEditingController(text: work.text);
  final tag = TextEditingController(text: work.tag ?? '');
  final photos = work.images.map((i) => i.url).toList();
  final picked = <PickedImage>[];
  var busy = false;
  final result = await showModalBottomSheet<Work>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: NexoColors.bg,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (sheet) => StatefulBuilder(
        builder: (sheet, setSheet) => PublicationEditorShell(
              title: 'Editar trabajo',
              subtitle: 'Actualiza la publicación de tu perfil',
              children: [
                EditorCard(children: [
                  EditorField(label: 'Título', controller: title, limit: 90, hint: 'Resume el trabajo realizado'),
                  EditorField(label: 'Descripción', controller: text, limit: 1000, lines: 5),
                  EditorField(label: 'Etiqueta', controller: tag, limit: 40, hint: 'Una frase breve para destacar'),
                ]),
                const SizedBox(height: 12),
                EditorPhotos(
                  photos: photos,
                  picked: picked,
                  busy: busy,
                  onRemovePhoto: (url) => setSheet(() => photos.remove(url)),
                  onRemovePicked: (image) => setSheet(() => picked.remove(image)),
                  onAdd: () async {
                    final images = await pickImages(max: 6 - photos.length - picked.length);
                    if (sheet.mounted) setSheet(() => picked.addAll(images));
                  },
                ),
                const SizedBox(height: 18),
                NexoButton(
                    label: 'Guardar cambios',
                    loading: busy,
                    onPressed: () async {
                      final headline = title.text.trim();
                      final body = text.text.trim();
                      if (headline.length < 5 || headline.length > 90 || body.length < 20 || body.length > 1000) {
                        showNexoToast('Revisa el título y la descripción.');
                        return;
                      }
                      setSheet(() => busy = true);
                      try {
                        final api = ref.read(apiProvider);
                        final ids = <String>[];
                        for (final url in photos) {
                          final id = _mediaId(url);
                          if (id == null) {
                            throw StateError('Una foto anterior no puede conservarse. Quítala e inténtalo.');
                          }
                          ids.add(id);
                        }
                        for (final image in picked) {
                          ids.add(await api.upload(image, purpose: 'work'));
                        }
                        final updated = await api.editWork(work,
                            title: headline, text: body, tag: tag.text.trim(), imageUploadIds: ids);
                        ref.invalidate(providerWorksProvider(work.provider.id));
                        if (sheet.mounted) Navigator.of(sheet).pop(updated);
                        showNexoToast('Trabajo actualizado');
                      } catch (e) {
                        showNexoToast(apiErrorMessage(e));
                        if (sheet.mounted) setSheet(() => busy = false);
                      }
                    }),
              ],
            )),
  );
  title.dispose();
  text.dispose();
  tag.dispose();
  return result;
}
