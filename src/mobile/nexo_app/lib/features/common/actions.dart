import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../app/router.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../core/auth/session_controller.dart';
import '../../core/widgets/map_view.dart';
import '../../core/widgets/nexo_button.dart';
import '../../core/widgets/nexo_field.dart';
import '../../core/widgets/nexo_icon.dart';
import '../../core/widgets/nexo_sheet.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/ui.dart';
import '../../data/api_provider.dart';
import '../../data/models.dart';
import '../location/location_picker_page.dart';
import '../shell/gate.dart';
import 'carousel.dart';

const _uuid = Uuid();

// ------------------------------------------------------------------ chat

/// "Iniciar chat" con un prestador → `POST /conversations` y abre el chat.
Future<void> openChatWithProvider(BuildContext context, WidgetRef ref, String providerId, {String? requestId}) async {
  if (!requireAccount(context, ref)) return;
  final router = GoRouter.of(context);
  try {
    final id = await ref.read(apiProvider).openConversation(providerId: providerId, requestId: requestId);
    ref.invalidate(inboxProvider);
    router.push(Routes.chat(id));
  } catch (e) {
    showNexoToast(apiErrorMessage(e));
  }
}

/// El prestador le escribe a quien publicó la solicitud.
Future<void> openChatForRequest(BuildContext context, WidgetRef ref, String requestId) async {
  final router = GoRouter.of(context);
  try {
    final id = await ref.read(apiProvider).openConversation(requestId: requestId);
    ref.invalidate(inboxProvider);
    router.push(Routes.chat(id));
  } catch (e) {
    showNexoToast(apiErrorMessage(e));
  }
}

// ------------------------------------------------------------- contactar

/// `contactSheet`: chat como vía principal; el número solo se copia.
Future<void> showContactSheet(BuildContext context, WidgetRef ref, ProviderMini p,
    {String? responseTime, bool canCall = true, String? requestId}) async {
  if (!requireAccount(context, ref, why: 'Con una cuenta puedes escribirle a ${p.name} y acordar todo en un chat.')) return;
  await showNexoSheet<void>(
    context,
    builder: (ctx) => _ContactSheet(p: p, responseTime: responseTime, canCall: canCall, requestId: requestId, outer: context),
  );
}

class _ContactSheet extends ConsumerStatefulWidget {
  const _ContactSheet({required this.p, this.responseTime, required this.canCall, this.requestId, required this.outer});
  final ProviderMini p;
  final String? responseTime;
  final bool canCall;
  final String? requestId;
  final BuildContext outer;

  @override
  ConsumerState<_ContactSheet> createState() => _ContactSheetState();
}

class _ContactSheetState extends ConsumerState<_ContactSheet> {
  String? _phone;
  bool _loading = false;
  bool _opening = false;

  Future<void> _reveal() async {
    setState(() => _loading = true);
    try {
      final r = await ref.read(apiProvider).revealPhone(targetId: widget.p.id, targetType: 'provider', context: 'profile');
      if (mounted) setState(() => _phone = r.displayPhone);
    } catch (e) {
      showNexoToast(apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _chat() async {
    setState(() => _opening = true);
    final nav = Navigator.of(context);
    final router = GoRouter.of(context);
    try {
      final id = await ref.read(apiProvider).openConversation(providerId: widget.p.id, requestId: widget.requestId);
      ref.invalidate(inboxProvider);
      nav.pop();
      router.push(Routes.chat(id));
    } catch (e) {
      showNexoToast(apiErrorMessage(e));
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 44, bottom: 16),
          child: Row(
            children: [
              NexoAvatar(name: p.name, url: p.photoUrl, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Contactar a ${p.name}', style: NexoText.display(19)),
                    const SizedBox(height: 2),
                    Row(children: [
                      const NexoIcon('clock', size: 14, color: NexoColors.muted),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                            'Suele responder ${(widget.responseTime ?? 'el mismo día').toLowerCase().startsWith('menos') ? 'en ' : ''}${(widget.responseTime ?? 'el mismo día').toLowerCase()}',
                            style: NexoText.body(13, color: NexoColors.muted)),
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
        NexoButton(label: 'Iniciar chat', icon: 'chat', loading: _opening, onPressed: _chat),
        const SizedBox(height: 10),
        Row(
          children: [
            const NexoIcon('shield', size: 16, color: NexoColors.ok),
            const SizedBox(width: 6),
            Expanded(
              child: Text('Tu número no se comparte. Acuerden precio, fecha y lugar en el chat.',
                  style: NexoText.body(13, color: NexoColors.muted)),
            ),
          ],
        ),
        if (widget.canCall) ...[
          const SizedBox(height: 16),
          Row(children: [
            const Expanded(child: Divider(color: NexoColors.line)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('¿Prefieres llamar?', style: NexoText.body(12.5, color: NexoColors.muted)),
            ),
            const Expanded(child: Divider(color: NexoColors.line)),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: NexoColors.surface2, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Teléfono', style: NexoText.body(12, color: NexoColors.muted)),
                      Text(_phone ?? '••• ••• ••••', style: NexoText.display(17, weight: FontWeight.w700, letterSpacing: .5)),
                    ],
                  ),
                ),
                NexoButton(
                  label: _phone == null ? 'Ver número' : 'Copiar',
                  icon: _phone == null ? 'phone' : 'copy',
                  small: true,
                  block: false,
                  loading: _loading,
                  variant: NexoButtonVariant.ghost,
                  onPressed: _phone == null
                      ? _reveal
                      : () {
                          Clipboard.setData(ClipboardData(text: _phone!));
                          showNexoToast('Número copiado');
                        },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// --------------------------------------------------------------- reportar

const reportCategories = [
  ('scam', 'Fraude o estafa'),
  ('fakeProfile', 'Perfil falso o suplantación'),
  ('inappropriateContent', 'Contenido inapropiado'),
  ('harassment', 'Acoso o trato ofensivo'),
  ('notAService', 'No es un servicio'),
  ('other', 'Otro motivo'),
];

/// `reportSheet` → `POST /v1/engagement/reports`.
Future<void> showReportSheet(BuildContext context, WidgetRef ref, {required String targetType, required String targetId}) async {
  if (!requireAccount(context, ref)) return;
  await showNexoSheet<void>(context, builder: (_) => _ReportSheet(targetType: targetType, targetId: targetId));
}

class _ReportSheet extends ConsumerStatefulWidget {
  const _ReportSheet({required this.targetType, required this.targetId});
  final String targetType;
  final String targetId;
  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  String? _cat;
  final _text = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _ok => _cat != null && _text.text.trim().length >= 10;

  Future<void> _send() async {
    setState(() => _sending = true);
    final nav = Navigator.of(context);
    try {
      final msg = await ref.read(apiProvider).report(
          targetType: widget.targetType, targetId: widget.targetId, category: _cat!, reason: _text.text.trim());
      nav.pop();
      showNexoToast(msg);
    } catch (e) {
      showNexoToast(apiErrorMessage(e));
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetHeader('Reportar', subtitle: 'Moderación revisa cada reporte y registra su decisión.'),
        for (final c in reportCategories) ...[
          OptRow(
            icon: _cat == c.$1 ? 'check' : 'flag',
            label: c.$2,
            selected: _cat == c.$1,
            onTap: () => setState(() => _cat = c.$1),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 4),
        Text('Cuéntanos qué pasó', style: NexoText.body(14, weight: FontWeight.w700)),
        const SizedBox(height: 7),
        TextField(
          controller: _text,
          maxLines: 3,
          maxLength: 300,
          onChanged: (_) => setState(() {}),
          style: NexoText.body(15),
          decoration: nexoInputDecoration(hint: 'Mínimo 10 caracteres'),
        ),
        const SizedBox(height: 10),
        NexoButton(label: 'Enviar reporte', loading: _sending, onPressed: _ok ? _send : null),
      ],
    );
  }
}

// ---------------------------------------------------------------- señales

/// `trustSheet`: cómo leer las insignias.
Future<void> showTrustSheet(BuildContext context) => showNexoSheet<void>(
      context,
      builder: (ctx) {
        Widget tier(String icon, String t, String d) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: NexoColors.brandSoft, borderRadius: BorderRadius.circular(12)),
                    child: Center(child: NexoIcon(icon, size: 19, color: NexoColors.brand)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t, style: NexoText.body(15, weight: FontWeight.w800)),
                        Text(d, style: NexoText.body(13.5, color: NexoColors.muted, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHeader('Cómo leer las señales', subtitle: 'Cada insignia dice exactamente qué se sabe.'),
            tier('user', 'Declarado', 'Lo que el prestador dice de sí mismo. Se muestra con su fecha de actualización.'),
            tier('shield', 'Teléfono confirmado',
                'Nexo Local comprobó que la persona controla ese número. No certifica su capacidad técnica.'),
            tier('thumb', 'Recomendaciones', 'Opiniones de otros usuarios. Ayudan a decidir, pero no garantizan el resultado.'),
            tier('info', 'Perfil nuevo', 'Aún no tiene historial. No es una calificación negativa.'),
            const SizedBox(height: 4),
            NexoButton(label: 'Entendido', onPressed: () => Navigator.of(ctx).pop()),
          ],
        );
      },
    );

/// `workSheet`: detalle de un trabajo publicado.
Future<void> showWorkSheet(BuildContext context, Work w) => showNexoSheet<void>(
      context,
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 30),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: PhotoCarousel(images: w.images, category: w.category, aspect: 4 / 3),
          ),
          const SizedBox(height: 14),
          Text(w.title, style: NexoText.display(20)),
          const SizedBox(height: 4),
          Text('${w.provider.name} · ${w.zoneLabel} · ${w.ago}', style: NexoText.body(14, color: NexoColors.muted)),
          const SizedBox(height: 10),
          Text(w.text, style: NexoText.body(15, height: 1.5)),
        ],
      ),
    );

/// Compartir: sin paquete de compartir, se copia el enlace público.
void shareLink(String path, String what) {
  Clipboard.setData(ClipboardData(text: 'https://nexolocal.mx$path'));
  showNexoToast('Enlace de $what copiado');
}

// -------------------------------------------------------------- guardados

Future<bool?> toggleSaved(BuildContext context, WidgetRef ref, String kind, String id, bool on) async {
  if (!requireAccount(context, ref, why: 'Con una cuenta puedes guardar prestadores y trabajos para volver a ellos.')) {
    return null;
  }
  try {
    await ref.read(apiProvider).setSaved(kind, id, on);
    ref.invalidate(accountProvider);
    showNexoToast(on ? 'Guardado' : 'Quitado de guardados');
    return on;
  } catch (e) {
    showNexoToast(apiErrorMessage(e));
    return null;
  }
}

void toggleCompare(BuildContext context, WidgetRef ref, ProviderMini p) {
  if (!requireAccount(context, ref, why: 'Con una cuenta puedes comparar prestadores lado a lado.')) return;
  final ok = ref.read(compareProvider.notifier).toggle(p);
  if (!ok) showNexoToast('Ya elegiste 2. Quita uno para agregar otro.');
}

// ---------------------------------------------------------- pedir servicio

/// `agSheet`: "Pedir servicio" → `POST /v1/engagement/orders`.
Future<void> showRequestServiceSheet(BuildContext context, WidgetRef ref, ProviderProfile p, {ServiceRequest? request}) async {
  if (!requireAccount(context, ref)) return;
  if (ref.read(sessionProvider).isProviderMode) {
    showNexoToast('Cambia a modo cliente en Cuenta para pedir un servicio.');
    return;
  }
  await showNexoSheet<void>(context, builder: (_) => _OrderSheet(p: p, request: request, outer: context));
}

class _OrderSheet extends ConsumerStatefulWidget {
  const _OrderSheet({required this.p, this.request, required this.outer});
  final ProviderProfile p;
  final ServiceRequest? request;
  final BuildContext outer;
  @override
  ConsumerState<_OrderSheet> createState() => _OrderSheetState();
}

class _OrderSheetState extends ConsumerState<_OrderSheet> {
  late String _cat = widget.request?.category ?? (widget.p.categories.isEmpty ? 'otros' : widget.p.categories.first);
  late String _att = widget.p.attention == 'shop' ? 'shop' : 'home';
  late final _desc = TextEditingController(text: widget.request?.title ?? '');
  final _addr = TextEditingController();
  late GeoPoint _place = ref.read(searchLocationProvider).point;
  bool _sending = false;
  final _idem = _uuid.v4();

  @override
  void dispose() {
    _desc.dispose();
    _addr.dispose();
    super.dispose();
  }

  bool get _ok => _desc.text.trim().length >= 10 && (_att == 'shop' || _addr.text.trim().length >= 5);

  Future<void> _pickPlace() async {
    final r = await GoRouter.of(context).push<LocationPick>(Routes.location,
        extra: LocationPickerArgs(
            title: 'Tu domicilio',
            subtitle: 'Mueve el mapa hasta tu casa. Solo el prestador lo verá y solo al aceptar.',
            initial: _place,
            showRadius: false,
            button: 'Usar este punto'));
    if (r != null && mounted) setState(() => _place = r.point);
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    final nav = Navigator.of(context);
    final router = GoRouter.of(context);
    try {
      final o = await ref.read(apiProvider).createOrder(
            providerId: widget.p.id,
            requestId: widget.request?.id,
            category: _cat,
            description: _desc.text.trim(),
            attention: _att,
            address: _att == 'shop' ? null : _addr.text.trim(),
            location: _att == 'shop' ? null : _place,
            idempotencyKey: _idem,
          );
      refreshActivity(ref);
      nav.pop();
      showNexoToast('Pedido enviado a ${widget.p.name}');
      router.push(Routes.order(o.id));
    } catch (e) {
      showNexoToast(apiErrorMessage(e));
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final me = ref.watch(sessionProvider).name ?? 'Tú';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader('Pedir servicio',
            subtitle:
                'Le enviaremos tu pedido a ${p.name}. Puede aceptarlo o rechazarlo y, si ya lo acordaron, indicar el precio.'),
        Row(
          children: [
            AvatarPair(a: (me, null), b: (p.name, p.photoUrl)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tú y ${p.name}', style: NexoText.body(15, weight: FontWeight.w800)),
                  Text(catInfo(_cat).name, style: NexoText.body(13, color: NexoColors.muted)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (p.categories.length > 1 && widget.request == null) ...[
          Text('Servicio', style: NexoText.body(14, weight: FontWeight.w700)),
          const SizedBox(height: 7),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final c in p.categories)
              ToggleChip(
                  label: catInfo(c).name, icon: catInfo(c).icon, selected: _cat == c, onTap: () => setState(() => _cat = c)),
          ]),
          const SizedBox(height: 14),
        ],
        Text('¿Qué necesitas?', style: NexoText.body(14, weight: FontWeight.w700)),
        const SizedBox(height: 7),
        TextField(
          controller: _desc,
          maxLines: 2,
          maxLength: 160,
          onChanged: (_) => setState(() {}),
          style: NexoText.body(15),
          decoration: nexoInputDecoration(hint: 'Ej. Revisar la fuga y cambiar la llave'),
        ),
        if (p.attention == 'both') ...[
          const SizedBox(height: 8),
          Text('¿Dónde será?', style: NexoText.body(14, weight: FontWeight.w700)),
          const SizedBox(height: 7),
          SegControl<String>(
            options: const [('home', 'En mi domicilio'), ('shop', 'Voy a su local')],
            value: _att,
            onChanged: (v) => setState(() => _att = v),
          ),
        ],
        const SizedBox(height: 14),
        if (_att == 'shop') ...[
          Text('Su local', style: NexoText.body(14, weight: FontWeight.w700)),
          const SizedBox(height: 7),
          MiniMap(point: p.shopLocation ?? p.zonePoint ?? _place, label: p.zoneLabel),
          const SizedBox(height: 6),
          Text('Irás a su local · ${p.distanceText.replaceFirst('a ', 'a ')}', style: NexoText.body(13, color: NexoColors.muted)),
        ] else ...[
          Text('Tu domicilio', style: NexoText.body(14, weight: FontWeight.w700)),
          const SizedBox(height: 7),
          MiniMap(point: _place, label: 'Tu domicilio', actionLabel: 'Cambiar', onAction: _pickPlace),
          const SizedBox(height: 12),
          Text('Calle, número y referencias', style: NexoText.body(14, weight: FontWeight.w700)),
          const SizedBox(height: 7),
          TextField(
            controller: _addr,
            maxLength: 80,
            onChanged: (_) => setState(() {}),
            autofillHints: const [AutofillHints.fullStreetAddress],
            style: NexoText.body(15),
            decoration: nexoInputDecoration(hint: 'Ej. Hidalgo 24, portón negro'),
          ),
          Row(children: [
            const NexoIcon('shield', size: 15, color: NexoColors.ok),
            const SizedBox(width: 6),
            Expanded(
              child: Text('Solo ${p.name} verá tu dirección, y solo al confirmar.',
                  style: NexoText.body(12.5, color: NexoColors.muted)),
            ),
          ]),
        ],
        const SizedBox(height: 14),
        NexoButton(label: 'Enviar pedido', icon: 'check', loading: _sending, onPressed: _ok ? _send : null),
      ],
    );
  }
}

// ------------------------------------------------------------- solicitudes

/// "Me interesa" / "Interés enviado" (prestador).
Future<void> toggleInterest(BuildContext context, WidgetRef ref, ServiceRequest r) async {
  if (!requireAccount(context, ref)) return;
  final on = !r.iAmInterested;
  try {
    await ref.read(apiProvider).setInterest(r.id, on);
    ref.invalidate(opportunitiesProvider);
    showNexoToast(on ? 'Le avisamos a ${r.clientName.split(' ').first} que te interesa' : 'Retiraste tu interés');
  } catch (e) {
    showNexoToast(apiErrorMessage(e));
  }
}

/// "Ya lo resolví · cerrar solicitud".
Future<void> showCloseRequestSheet(BuildContext context, WidgetRef ref, ServiceRequest r) async {
  final outcome = await showNexoSheet<String>(
    context,
    builder: (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader('Cerrar solicitud', subtitle: '«${r.title}» dejará de verse para los prestadores.'),
        OptRow(icon: 'check', label: 'Lo resolví con alguien de Nexo', onTap: () => Navigator.of(ctx).pop('solvedHere')),
        const SizedBox(height: 8),
        OptRow(icon: 'out', label: 'Lo resolví por otro lado', onTap: () => Navigator.of(ctx).pop('solvedElsewhere')),
        const SizedBox(height: 8),
        OptRow(icon: 'close', label: 'Ya no lo necesito', onTap: () => Navigator.of(ctx).pop('noLongerNeeded')),
      ],
    ),
  );
  if (outcome == null) return;
  try {
    await ref.read(apiProvider).closeRequest(r.id, outcome: outcome, pickedProviderId: r.picked?.id);
    ref.invalidate(myRequestsProvider);
    showNexoToast('Solicitud cerrada');
  } catch (e) {
    showNexoToast(apiErrorMessage(e));
  }
}

/// `noProScreen` en una hoja: acción que exige perfil de prestador.
Future<void> showNeedProviderSheet(BuildContext context) {
  final router = GoRouter.of(context);
  return showNexoSheet<void>(
    context,
    builder: (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetHeader('Crea tu perfil de prestador',
            subtitle: 'Con tu perfil verás solicitudes de tu zona, podrás responderlas y publicar tus trabajos.'),
        NexoButton(
            label: 'Crear mi perfil',
            onPressed: () {
              Navigator.of(ctx).pop();
              router.push(Routes.proOnboarding);
            }),
      ],
    ),
  );
}
