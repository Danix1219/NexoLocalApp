import 'publication_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../core/widgets/nexo_button.dart';
import '../../core/widgets/pick_image.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/ui.dart';
import '../../data/api_provider.dart';
import '../../data/models.dart';
import '../../data/nexo_api.dart';
import 'publication_actions_ui.dart';
import 'publication_editor_ui.dart';

String? _uploadId(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.path.startsWith('/v1/discovery/media/')) return null;
  final id = uri.pathSegments.last;
  return RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(id) ? id : null;
}

Future<void> showRequestEditor(BuildContext context, WidgetRef ref, ServiceRequest request) async {
  if (!request.mine || request.closed) return;
  final text = TextEditingController(text: request.description);
  var urgency = request.urgency;
  var contact = request.contact;
  final photos = List<String>.of(request.photos);
  final picked = <PickedImage>[];
  var busy = false;
  String? saveError;
  bool dirty() =>
      text.text.trim() != request.description.trim() ||
      urgency != request.urgency ||
      contact != request.contact ||
      picked.isNotEmpty ||
      !listEquals(photos, request.photos);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // Arrastrar para cerrar perdería los cambios sin preguntar.
    enableDrag: false,
    backgroundColor: NexoColors.bg,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (sheet) => StatefulBuilder(
      builder: (sheet, setSheet) => PublicationEditorShell(
        title: 'Editar solicitud',
        error: saveError,
        dirty: dirty(),
        busy: busy,
        footer: NexoButton(
          label: 'Guardar cambios',
          loading: busy,
          onPressed: !dirty()
              ? null
              : () async {
                  final description = text.text.trim();
                  final headline = autoTitle(description);
                  if (description.length < 10 || description.length > 600) {
                    setSheet(() => saveError = 'Escribe entre 10 y 600 caracteres.');
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
                      final id = _uploadId(url);
                      if (id == null) {
                        throw StateError('Una foto anterior no puede conservarse. Quítala e inténtalo.');
                      }
                      ids.add(id);
                    }
                    for (final image in picked) {
                      ids.add(await api.upload(image, purpose: 'request'));
                    }
                    await api.editRequest(
                      request.id,
                      title: headline,
                      description: description,
                      urgency: urgency,
                      contact: contact,
                      imageUploadIds: ids,
                    );
                    ref.invalidate(myRequestsProvider);
                    ref.invalidate(opportunitiesProvider);
                    if (sheet.mounted) Navigator.of(sheet).pop();
                    showNexoToast('Solicitud actualizada');
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
        subtitle: 'Actualiza lo que verán los prestadores',
        children: [
          EditorCard(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: NexoColors.brandSoft, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 17, color: NexoColors.brandDeep),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        request.zoneLabel.isEmpty
                            ? 'El servicio y la ubicación se conservan.'
                            : '${request.zoneLabel} · El servicio y la ubicación se conservan.',
                        style: NexoText.body(12.5, weight: FontWeight.w700, color: NexoColors.brandDeep, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              EditorField(
                label: '¿Qué necesitas resolver?',
                controller: text,
                limit: 600,
                lines: 5,
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
              const SizedBox(height: 18),
              EditorChoice(
                label: '¿Para cuándo?',
                options: const [('today', 'Hoy'), ('week', 'Esta semana'), ('noRush', 'Sin prisa')],
                value: urgency,
                onChanged: (v) => setSheet(() => urgency = v),
              ),
              const SizedBox(height: 16),
              EditorChoice(
                label: 'Te contactan por',
                options: const [('chat', 'Solo chat'), ('chatCall', 'Chat o llamada')],
                value: contact,
                onChanged: (v) => setSheet(() => contact = v),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  text.dispose();
}

Future<void> showRequestOptions(BuildContext context, WidgetRef ref, ServiceRequest request) async {
  if (!request.mine) return;
  final preview = PublicationPreview(
    text: request.description.isEmpty ? request.title : request.description,
    imageUrl: request.photos.firstOrNull,
    photos: request.photos.length,
    meta: [request.urgencyText, request.zoneLabel].where((part) => part.isNotEmpty).join(' · '),
  );
  final action = await showPublicationMenu(
    context,
    title: 'Tu solicitud',
    preview: preview,
    editLabel: request.status == 'open' ? 'Editar solicitud' : null,
    editDetail: 'Descripción, fotos, urgencia y contacto',
  );
  if (!context.mounted || action == null) return;
  if (action == 'edit') {
    await showRequestEditor(context, ref, request);
    return;
  }
  final deleted = await confirmPublicationDelete(
    context,
    preview: preview,
    loses: 'Dejará de mostrarse a los prestadores.',
    keeps: 'Los pedidos y su historial se conservan.',
    warning: 'Si ya elegiste a alguien, primero resuelve ese pedido.',
    keepLabel: 'Conservar solicitud',
    onDelete: () async {
      await ref.read(apiProvider).deleteRequest(request.id);
      ref.invalidate(myRequestsProvider);
      ref.invalidate(opportunitiesProvider);
      ref.invalidate(feedProvider);
      ref.invalidate(savedProvider);
    },
  );
  if (deleted) showNexoToast('Publicación eliminada');
}
