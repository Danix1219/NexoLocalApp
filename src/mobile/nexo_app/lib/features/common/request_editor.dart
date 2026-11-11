import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/tokens.dart';
import '../../core/widgets/nexo_button.dart';
import '../../core/widgets/pick_image.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/ui.dart';
import '../../data/api_provider.dart';
import '../../data/models.dart';
import '../../data/nexo_api.dart';
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
  final title = TextEditingController(text: request.title);
  var urgency = request.urgency;
  var contact = request.contact;
  final photos = List<String>.of(request.photos);
  final picked = <PickedImage>[];
  var busy = false;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: NexoColors.bg,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (sheet) => StatefulBuilder(
        builder: (sheet, setSheet) => PublicationEditorShell(
              title: 'Editar solicitud',
              subtitle: 'Actualiza lo que verán los prestadores',
              children: [
                EditorCard(children: [
                  Text(request.zoneLabel, style: const TextStyle(color: NexoColors.brand, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text('El servicio y la ubicación se conservan.'),
                  const SizedBox(height: 14),
                  EditorField(label: 'Título', controller: title, limit: 90, hint: 'Resume lo que necesitas'),
                  EditorField(label: '¿Qué necesitas resolver?', controller: text, limit: 600, lines: 5),
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
                const SizedBox(height: 12),
                EditorCard(children: [
                  EditorChoice(label: '¿Para cuándo?', options: const [('today', 'Hoy'), ('week', 'Esta semana'), ('noRush', 'Sin prisa')], value: urgency, onChanged: (v) => setSheet(() => urgency = v)),
                  const SizedBox(height: 14),
                  EditorChoice(label: 'Te contactan por', options: const [('chat', 'Solo chat'), ('chatCall', 'Chat o llamada')], value: contact, onChanged: (v) => setSheet(() => contact = v)),
                ]),
                const SizedBox(height: 12),
                NexoButton(
                    label: 'Guardar cambios',
                    loading: busy,
                    onPressed: () async {
                      final description = text.text.trim();
                      final headline = title.text.trim();
                      if (headline.length < 5 || headline.length > 90) {
                        showNexoToast('El título debe tener entre 5 y 90 caracteres.');
                        return;
                      }
                      if (description.length < 10 || description.length > 600) {
                        showNexoToast('Escribe entre 10 y 600 caracteres.');
                        return;
                      }
                      setSheet(() => busy = true);
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
                        await api.editRequest(request.id,
                            title: headline,
                            description: description,
                            urgency: urgency,
                            contact: contact,
                            imageUploadIds: ids);
                        ref.invalidate(myRequestsProvider);
                        ref.invalidate(opportunitiesProvider);
                        if (sheet.mounted) Navigator.of(sheet).pop();
                        showNexoToast('Solicitud actualizada');
                      } catch (e) {
                        showNexoToast(apiErrorMessage(e));
                        if (sheet.mounted) setSheet(() => busy = false);
                      }
                    }),
              ],
            )),
  );
  text.dispose();
  title.dispose();
}
