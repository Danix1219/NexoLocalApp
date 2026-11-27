import 'dart:async';
import '../../core/network/api_exception.dart';
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
import '../../core/widgets/photo_feedback.dart';
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
Future<void> showContactSheet(
  BuildContext context,
  WidgetRef ref,
  ProviderMini p, {
  String? responseTime,
  bool canCall = true,
  String? requestId,
}) async {
  if (!requireAccount(context, ref, why: 'Con una cuenta puedes escribirle a ${p.name} y acordar todo en un chat.')) {
    return;
  }
  await showNexoSheet<void>(
    context,
    builder: (ctx) =>
        _ContactSheet(p: p, responseTime: responseTime, canCall: canCall, requestId: requestId, outer: context),
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
      final r = await ref
          .read(apiProvider)
          .revealPhone(targetId: widget.p.id, targetType: 'provider', context: 'profile');
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
                    Row(
                      children: [
                        const NexoIcon('clock', size: 14, color: NexoColors.muted),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            'Suele responder ${(widget.responseTime ?? 'el mismo día').toLowerCase().startsWith('menos') ? 'en ' : ''}${(widget.responseTime ?? 'el mismo día').toLowerCase()}',
                            style: NexoText.body(13, color: NexoColors.muted),
                          ),
                        ),
                      ],
                    ),
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
              child: Text(
                'Tu número no se comparte. Acuerden precio, fecha y lugar en el chat.',
                style: NexoText.body(13, color: NexoColors.muted),
              ),
            ),
          ],
        ),
        if (widget.canCall) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(child: Divider(color: NexoColors.line)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('¿Prefieres llamar?', style: NexoText.body(12.5, color: NexoColors.muted)),
              ),
              const Expanded(child: Divider(color: NexoColors.line)),
            ],
          ),
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
                      Text(
                        _phone ?? '••• ••• ••••',
                        style: NexoText.display(17, weight: FontWeight.w700, letterSpacing: .5),
                      ),
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
Future<void> showReportSheet(
  BuildContext context,
  WidgetRef ref, {
  required String targetType,
  required String targetId,
}) async {
  if (!requireAccount(context, ref)) return;
  await showNexoSheet<void>(
    context,
    builder: (_) => _ReportSheet(targetType: targetType, targetId: targetId),
  );
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
      final msg = await ref
          .read(apiProvider)
          .report(targetType: widget.targetType, targetId: widget.targetId, category: _cat!, reason: _text.text.trim());
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
        tier(
          'shield',
          'Correo verificado',
          'Nexo Local comprobó el acceso al correo de la cuenta. No confirma la propiedad del celular ni certifica su capacidad técnica.',
        ),
        tier(
          'thumb',
          'Recomendaciones',
          'Opiniones de otros usuarios. Ayudan a decidir, pero no garantizan el resultado.',
        ),
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

/// Enlaces de la aplicacion instalada; no se inventa un dominio web.
String? shareableAppLink(String path) {
  final normalized = path.startsWith('/p/') ? '/provider/${path.substring(3)}' : path;
  if (Routes.fromDeepLink(normalized) == null) return null;
  return 'nexolocal:/$normalized';
}

void shareLink(String path, String what) {
  final link = shareableAppLink(path);
  if (link == null) {
    showNexoToast('Este contenido no tiene un enlace disponible');
    return;
  }
  Clipboard.setData(ClipboardData(text: link));
  showNexoToast('Enlace de $what copiado');
}

/// Opening options never transmits data.
Future<void> showProfileShareSheet(
  BuildContext context, {
  required String id,
  required String name,
  String? photoUrl,
}) async {
  final link = shareableAppLink('/provider/$id');
  if (link == null) {
    showNexoToast('Este perfil no tiene un enlace disponible');
    return;
  }
  final action = await showNexoSheet<String>(
    context,
    builder: (sheet) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader('Compartir perfil', subtitle: 'Elige c\u00f3mo compartir el perfil de $name.'),
        NexoButton(label: 'Compartir', icon: 'share', onPressed: () => Navigator.of(sheet).pop('share')),
        const SizedBox(height: 8),
        NexoButton(
          label: 'Copiar enlace',
          icon: 'link',
          variant: NexoButtonVariant.ghost,
          onPressed: () => Navigator.of(sheet).pop('copy'),
        ),
        const SizedBox(height: 8),
        NexoButton(
          label: 'Ver c\u00f3digo QR',
          variant: NexoButtonVariant.ghost,
          onPressed: () => Navigator.of(sheet).pop('qr'),
        ),
        const SizedBox(height: 12),
        Text(
          'El enlace abre Nexo Local si la app est\u00e1 instalada.',
          style: NexoText.body(14, color: NexoColors.muted),
        ),
      ],
    ),
  );
  if (!context.mounted || action == null) return;
  try {
    switch (action) {
      case 'share':
        await const MethodChannel(
          'mx.nexolocal/share',
        ).invokeMethod('share', {'text': link, 'title': 'Perfil de $name'});
      case 'copy':
        await Clipboard.setData(ClipboardData(text: link));
        showNexoToast('Enlace de perfil copiado');
      case 'qr':
        await showDialog<void>(
          context: context,
          builder: (_) => ProfileQrCard(name: name, photoUrl: photoUrl, link: link),
        );
    }
  } on PlatformException {
    showNexoToast('No pudimos abrir las opciones para compartir. Intenta copiar el enlace.');
  } on MissingPluginException {
    showNexoToast('Compartir no est\u00e1 disponible aqu\u00ed. Puedes copiar el enlace.');
  }
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

/// Mensaje del fallo al crear un pedido. Reintentar usa la misma llave de
/// idempotencia, así que no crea un pedido repetido.
String orderSendErrorMessage(Object error) {
  if (error is ApiException) {
    if (error.isNetwork) {
      return 'No recibimos respuesta del servidor. Revisa tu conexión y reintenta; no se duplicará.';
    }
    if (error.code == 'server.dependency_unavailable' || (error.status ?? 0) >= 500) {
      return 'El servidor no pudo proteger o guardar tu pedido en este momento. Tus datos siguen aquí; reintenta.';
    }
  }
  return apiErrorMessage(error);
}

/// `agSheet`: "Pedir servicio" → `POST /v1/engagement/orders`.
Future<void> showRequestServiceSheet(
  BuildContext context,
  WidgetRef ref,
  ProviderProfile p, {
  ServiceRequest? request,
}) async {
  if (!requireAccount(context, ref)) return;
  if (ref.read(sessionProvider).isProviderMode) {
    showNexoToast('Cambia a modo cliente en Cuenta para pedir un servicio.');
    return;
  }
  await showNexoSheet<void>(
    context,
    builder: (_) => _OrderSheet(p: p, request: request, outer: context),
  );
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
  final _desc = TextEditingController();
  final _addr = TextEditingController();
  late GeoPoint _place = ref.read(searchLocationProvider).point;
  bool _sending = false;
  final _idem = _uuid.v4();
  Order? _sent;
  String? _failure;
  final _feedback = GlobalKey();

  @override
  void dispose() {
    _desc.dispose();
    _addr.dispose();
    super.dispose();
  }

  bool get _ok => _missing == null;

  /// Qué falta para poder enviar; se muestra junto al botón.
  String? get _missing {
    if (_desc.text.trim().length < 10) return 'Describe lo que necesitas (mínimo 10 caracteres).';
    if (_att != 'shop' && _addr.text.trim().length < 5) return 'Escribe la calle y el número de tu domicilio.';
    return null;
  }

  Future<void> _pickPlace() async {
    final r = await GoRouter.of(context).push<LocationPick>(
      Routes.location,
      extra: LocationPickerArgs(
        title: 'Tu domicilio',
        subtitle: 'Mueve el mapa hasta tu casa. Solo el prestador lo verá y solo al aceptar.',
        initial: _place,
        showRadius: false,
        button: 'Usar este punto',
      ),
    );
    if (r != null && mounted) {
      setState(() {
        _place = r.point;
        if (_addr.text.trim().isEmpty && r.label != null) {
          _addr.text = r.label!.length > 80 ? r.label!.substring(0, 80) : r.label!;
        }
      });
    }
  }

  Future<void> _send() async {
    if (_sending) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _sending = true;
      _failure = null;
    });
    try {
      final o = await ref
          .read(apiProvider)
          .createOrder(
            providerId: widget.p.id,
            requestId: widget.request?.id,
            category: _cat,
            description: _desc.text.trim(),
            attention: _att,
            address: _att == 'shop' ? null : _addr.text.trim(),
            location: _att == 'shop' ? null : _place,
            idempotencyKey: _idem,
          );
      if (!mounted) return;
      refreshActivity(ref);
      unawaited(HapticFeedback.mediumImpact());
      setState(() {
        _sent = o;
        _sending = false;
      });
    } catch (e) {
      if (!mounted) return;
      unawaited(HapticFeedback.heavyImpact());
      setState(() {
        _failure = orderSendErrorMessage(e);
        _sending = false;
      });
      // El aviso queda a la vista aunque la hoja sea larga.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = _feedback.currentContext;
        if (target != null) {
          Scrollable.ensureVisible(target, alignment: .5, duration: const Duration(milliseconds: 220));
        }
      });
    }
  }

  /// Confirmación dentro de la hoja: un aviso flotante quedaría tapado.
  Widget _success(Order order) {
    final router = GoRouter.of(context);
    final nav = Navigator.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 18),
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: .4, end: 1),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutBack,
            builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
            child: Container(
              width: 86,
              height: 86,
              decoration: const BoxDecoration(color: NexoColors.okSoft, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, size: 46, color: NexoColors.ok),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Semantics(
          liveRegion: true,
          child: Text('¡Pedido enviado!', textAlign: TextAlign.center, style: NexoText.display(24)),
        ),
        const SizedBox(height: 8),
        Text(
          '${widget.p.name} recibirá tu pedido. Está esperando su respuesta y te avisaremos cuando lo acepte o rechace.',
          textAlign: TextAlign.center,
          style: NexoText.body(14.5, color: NexoColors.muted, height: 1.5),
        ),
        const SizedBox(height: 26),
        NexoButton(
          label: 'Ver mi pedido',
          onPressed: () {
            nav.pop();
            router.push(Routes.order(order.id));
          },
        ),
        const SizedBox(height: 8),
        NexoButton(label: 'Listo', variant: NexoButtonVariant.ghost, onPressed: nav.pop),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_sent case final order?) return _success(order);
    final p = widget.p;
    final me = ref.watch(sessionProvider).name ?? 'Tú';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader(
          'Pedir servicio',
          subtitle:
              'Le enviaremos tu pedido a ${p.name}. Puede aceptarlo o rechazarlo y, si ya lo acordaron, indicar el precio.',
        ),
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in p.categories)
                ToggleChip(
                  label: catInfo(c).name,
                  icon: catInfo(c).icon,
                  selected: _cat == c,
                  onTap: () => setState(() => _cat = c),
                ),
            ],
          ),
          const SizedBox(height: 14),
        ],
        Text('¿Qué necesitas?', style: NexoText.body(14, weight: FontWeight.w700)),
        const SizedBox(height: 7),
        TextField(
          controller: _desc,
          minLines: 2,
          maxLines: 5,
          maxLength: 600,
          onChanged: (_) => setState(() {}),
          style: NexoText.body(15),
          textCapitalization: TextCapitalization.sentences,
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
          Text(
            'Irás a su local · ${p.distanceText.replaceFirst('a ', 'a ')}',
            style: NexoText.body(13, color: NexoColors.muted),
          ),
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
          Row(
            children: [
              const NexoIcon('shield', size: 15, color: NexoColors.ok),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Solo ${p.name} verá tu dirección, y solo al confirmar.',
                  style: NexoText.body(12.5, color: NexoColors.muted),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        if (_missing case final missing?)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              missing,
              textAlign: TextAlign.center,
              style: NexoText.body(12.5, weight: FontWeight.w600, color: NexoColors.warn),
            ),
          ),
        if (_failure case final failure?)
          Container(
            key: _feedback,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: NexoColors.danger.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: NexoColors.danger.withValues(alpha: .3)),
            ),
            child: Semantics(
              liveRegion: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline_rounded, color: NexoColors.danger, size: 21),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No se envió tu pedido',
                          style: NexoText.body(14, weight: FontWeight.w800, color: NexoColors.danger),
                        ),
                        const SizedBox(height: 2),
                        Text(failure, style: NexoText.body(13, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_sending)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Semantics(
              liveRegion: true,
              child: Text(
                'Enviando tu pedido… puede tardar unos segundos.',
                textAlign: TextAlign.center,
                style: NexoText.body(12.5, weight: FontWeight.w600, color: NexoColors.brand),
              ),
            ),
          ),
        NexoButton(
          label: _failure == null ? 'Enviar pedido' : 'Reintentar envío',
          icon: 'check',
          loading: _sending,
          onPressed: _ok ? _send : null,
        ),
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
    if (!context.mounted) return;
    ref.invalidate(opportunitiesProvider);
    ref.invalidate(myRequestsProvider);
    ref.invalidate(interestedProvider);
    ref.invalidate(feedProvider);
    ref.invalidate(accountProvider);
    showNexoToast(on ? 'Interés enviado. El solicitante podrá ver tu perfil.' : 'Retiraste tu interés');
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
        OptRow(
          icon: 'check',
          label: 'Lo resolví con alguien de Nexo',
          onTap: () => Navigator.of(ctx).pop('solvedHere'),
        ),
        const SizedBox(height: 8),
        OptRow(icon: 'out', label: 'Lo resolví por otro lado', onTap: () => Navigator.of(ctx).pop('solvedElsewhere')),
        const SizedBox(height: 8),
        OptRow(icon: 'close', label: 'Ya no lo necesito', onTap: () => Navigator.of(ctx).pop('noLongerNeeded')),
      ],
    ),
  );
  if (outcome == null) return;
  try {
    await ref
        .read(apiProvider)
        .closeRequest(r.id, outcome: outcome, pickedProviderId: outcome == 'solvedHere' ? r.picked?.id : null);
    refreshActivity(ref);
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
        const SheetHeader(
          'Crea tu perfil de prestador',
          subtitle: 'Con tu perfil verás solicitudes de tu zona, podrás responderlas y publicar tus trabajos.',
        ),
        NexoButton(
          label: 'Crear mi perfil',
          onPressed: () {
            Navigator.of(ctx).pop();
            router.push(Routes.proOnboarding);
          },
        ),
      ],
    ),
  );
}

/// Reviews are tied to a real completed order, not free-form endorsements.
Future<void> showReviewableOrders(BuildContext context, WidgetRef ref) async {
  if (!requireAccount(context, ref)) return;
  final router = GoRouter.of(context);
  final id = await showNexoSheet<String>(
    context,
    builder: (sheet) => Consumer(
      builder: (context, ref, _) {
        final orders = ref.watch(ordersProvider('client'));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHeader('Comparte tu experiencia', subtitle: 'Elige el servicio que quieres calificar.'),
            asyncView(orders, (page) {
              final eligible = page.items.where((o) => o.canReview && !o.iAmProvider).toList();
              if (eligible.isEmpty) {
                return const OneNote(
                  icon: 'thumb',
                  text:
                      'Podrás compartir tu experiencia cuando completes un pedido. Las opiniones corresponden a servicios reales.',
                );
              }
              return Column(
                children: [
                  for (final order in eligible)
                    OptRow(
                      icon: 'thumb',
                      label: order.counterpart.displayName,
                      onTap: () => Navigator.of(sheet).pop(order.id),
                    ),
                ],
              );
            }, onRetry: () => ref.invalidate(ordersProvider('client'))),
          ],
        );
      },
    ),
  );
  if (id != null && context.mounted) router.push(Routes.order(id));
}
