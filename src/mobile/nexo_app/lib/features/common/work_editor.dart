import 'publication_text.dart';
import 'package:flutter/foundation.dart';
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
import 'publication_actions_ui.dart';
import 'publication_editor_ui.dart';

String? _mediaId(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.path.startsWith('/v1/discovery/media/')) return null;
  final id = uri.pathSegments.last;
  return RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(id) ? id : null;
}

Future<Work?> showWorkEditor(BuildContext context, WidgetRef ref, Work work) async {
  final text = TextEditingController(text: work.text);
  final tag = TextEditingController(text: work.tag ?? '');
  final photos = work.images.map((i) => i.url).toList();
  final picked = <PickedImage>[];
  var busy = false;
  String? saveError;
  final originalPhotos = List<String>.of(photos);
  bool dirty() =>
      text.text.trim() != work.text.trim() ||
      tag.text.trim() != (work.tag ?? '').trim() ||
      picked.isNotEmpty ||
      !listEquals(photos, originalPhotos);
  final result = await showModalBottomSheet<Work>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // Arrastrar para cerrar perdería los cambios sin preguntar.
    enableDrag: false,
    backgroundColor: NexoColors.bg,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (sheet) => StatefulBuilder(
      builder: (sheet, setSheet) => PublicationEditorShell(
        title: 'Editar trabajo',
        error: saveError,
        dirty: dirty(),
        busy: busy,
        footer: NexoButton(
          label: 'Guardar cambios',
          loading: busy,
          onPressed: !dirty()
              ? null
              : () async {
                  final headline = autoTitle(text.text);
                  final body = text.text.trim();
                  if (headline.length < 5 || headline.length > 90 || body.length < 20 || body.length > 1000) {
                    setSheet(() => saveError = 'Escribe entre 20 y 1000 caracteres.');
                    return;
                  }
                  setSheet(() {
                    busy = true;
                    saveError = null;
                  });
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
                    final updated = await api.editWork(
                      work,
                      title: headline,
                      text: body,
                      tag: tag.text.trim(),
                      imageUploadIds: ids,
                    );
                    ref.invalidate(providerWorksProvider(work.provider.id));
                    if (sheet.mounted) Navigator.of(sheet).pop(updated);
                    showNexoToast('Trabajo actualizado');
                  } catch (e) {
                    if (sheet.mounted) {
                      setSheet(() {
                        busy = false;
                        saveError = e is StateError ? e.message : apiErrorMessage(e);
                      });
                    }
                  }
                },
        ),
        subtitle: 'Actualiza la publicación de tu perfil',
        children: [
          EditorCard(
            children: [
              EditorField(
                label: 'Descripción',
                controller: text,
                limit: 1000,
                lines: 5,
                onChanged: (_) => setSheet(() => saveError = null),
              ),
              const SizedBox(height: 8),
              EditorField(
                label: 'Etiqueta',
                controller: tag,
                limit: 40,
                hint: 'Una frase breve para destacar',
                onChanged: (_) => setSheet(() => saveError = null),
              ),
              const SizedBox(height: 10),
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
            ],
          ),
        ],
      ),
    ),
  );
  text.dispose();
  tag.dispose();
  return result;
}

Future<Work?> showWorkOptions(BuildContext context, WidgetRef ref, Work work) async {
  final preview = PublicationPreview(
    text: work.text.isEmpty ? work.title : work.text,
    imageUrl: work.images.firstOrNull?.url,
    meta: work.tag ?? '',
    photos: work.images.length,
  );
  final action = await showPublicationMenu(
    context,
    title: 'Tu trabajo',
    preview: preview,
    editLabel: 'Editar trabajo',
    editDetail: 'Descripción, etiqueta y fotos',
  );
  if (!context.mounted || action == null) return null;
  if (action == 'edit') return showWorkEditor(context, ref, work);
  final deleted = await confirmPublicationDelete(
    context,
    preview: preview,
    loses: 'Dejará de aparecer en tu perfil y en las búsquedas.',
    keeps: 'Tus conversaciones y pedidos se conservan.',
    keepLabel: 'Conservar trabajo',
    onDelete: () async {
      await ref.read(apiProvider).deleteWork(work.id);
      ref.invalidate(providerWorksProvider(work.provider.id));
      ref.invalidate(myProviderProvider);
      ref.invalidate(feedProvider);
      ref.invalidate(savedProvider);
    },
  );
  if (deleted) showNexoToast('Publicación eliminada');
  return null;
}
