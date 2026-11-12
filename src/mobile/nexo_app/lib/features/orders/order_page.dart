import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../core/auth/session_controller.dart';
import '../../core/network/api_exception.dart';
import '../../core/widgets/map_view.dart';
import '../../core/widgets/nexo_button.dart';
import '../../core/widgets/nexo_field.dart';
import '../../core/widgets/nexo_icon.dart';
import '../../core/widgets/nexo_sheet.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/ui.dart';
import '../../core/widgets/nexo_navigation.dart';
import '../../data/api_provider.dart';
import '../../data/models.dart';
import '../common/actions.dart';
import '../location/location_picker_page.dart';
import '../provider/provider_page.dart' show openDirections;

/// 7.15 Pedido de servicio (`V.match`): acuerdo entre cliente y prestador.
class OrderPage extends ConsumerStatefulWidget {
  const OrderPage({super.key, required this.id});
  final String id;

  @override
  ConsumerState<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends ConsumerState<OrderPage> {
  bool _busy = false;

  /// Ejecuta una acción con If-Match; en conflicto recarga y avisa.
  Future<void> _run(Future<Order> Function() f, String ok) async {
    setState(() => _busy = true);
    try {
      await f();
      refreshActivity(ref);
      ref.invalidate(orderProvider(widget.id));
      showNexoToast(ok);
    } on ApiException catch (e) {
      if (e.status == 412 || e.status == 409) ref.invalidate(orderProvider(widget.id));
      showNexoToast(apiErrorMessage(e));
    } catch (e) {
      showNexoToast(apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = ref.watch(orderProvider(widget.id));
    return NexoPage(
      bottom: const NexoNavigation(current: 3),
      child: Column(children: [
        const SubBar('Pedido'),
        Expanded(
          child: asyncView(v, (o) => _body(o), onRetry: () => ref.invalidate(orderProvider(widget.id))),
        ),
      ]),
    );
  }

  String _title(Order o) {
    final other = o.counterpart.displayName;
    return switch (o.status) {
      'cancelled' => 'Servicio cancelado',
      'rejected' => 'Pedido rechazado',
      'resolved' => 'Servicio resuelto',
      'pending' => o.iAmProvider ? '$other te hizo un pedido' : 'Esperando que $other acepte',
      _ => 'Pedido aceptado',
    };
  }

  Widget _body(Order o) {
    final me = ref.watch(sessionProvider).name ?? 'Tú';
    final client = !o.iAmProvider;
    final step = switch (o.status) { 'pending' => 0, 'accepted' => 1, 'resolved' => 2, _ => -1 };
    final shop = o.attention == 'shop';
    final exact = client || o.status != 'pending';
    final place = o.location ?? ref.read(searchLocationProvider).point;

    String head;
    String line;
    String? cta;
    VoidCallback? act;
    if (shop) {
      head = client ? 'Ve a su local' : '${o.counterpart.displayName} irá a tu local';
      line = client ? 'Local de ${o.counterpart.displayName} · ${o.placeZone}' : 'Tu local · ${o.placeZone}';
      if (client) {
        cta = 'Cómo llegar';
        act = () => openDirections(place);
      }
    } else if (client) {
      head = '${o.counterpart.displayName} irá a tu domicilio';
      line = o.address ?? o.placeZone;
      if (o.can('changeAddress')) {
        cta = 'Cambiar';
        act = () => _changeAddress(o);
      }
    } else if (o.status == 'pending') {
      head = 'Domicilio en ${o.placeZone}';
      line = 'Verás la dirección exacta al aceptar.';
    } else {
      head = 'Ve al domicilio de ${o.counterpart.displayName}';
      line = [o.address, o.addressNote].whereType<String>().where((e) => e.isNotEmpty).join(' · ');
      if (line.isEmpty) line = o.placeZone;
      cta = 'Cómo llegar';
      act = () => openDirections(place);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // ---- héroe y pasos
        Container(
          color: NexoColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
          child: Column(children: [
            AvatarPair(
              a: (me, null),
              b: (o.counterpart.displayName, o.counterpart.photoUrl),
              ok: o.status == 'accepted' || o.status == 'resolved',
              size: 56,
            ),
            const SizedBox(height: 12),
            Text(_title(o), textAlign: TextAlign.center, style: NexoText.display(20)),
            const SizedBox(height: 12),
            if (step < 0)
              Text('Ya no está activo.', style: NexoText.body(14, color: NexoColors.muted))
            else
              _Steps(step: step),
          ]),
        ),
        // ---- dónde
        NexoCard(
          title: head,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MiniMap(
                point: place,
                approximate: !exact && !shop,
                label: shop || exact ? (shop ? o.placeZone : 'Domicilio') : o.placeZone,
                actionLabel: cta,
                onAction: act,
              ),
              const SizedBox(height: 8),
              Text(line, style: NexoText.body(14, weight: FontWeight.w600)),
              if (!client && !shop && o.status == 'pending') ...[
                const SizedBox(height: 6),
                const Notice('Solo verás la dirección exacta cuando aceptes el pedido.', icon: 'shield'),
              ],
            ],
          ),
        ),
        // ---- con quién
        NexoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: o.counterpart.providerId == null
                    ? null
                    : () => context.push(Routes.provider(o.counterpart.providerId!)),
                child: Row(children: [
                  NexoAvatar(name: o.counterpart.displayName, url: o.counterpart.photoUrl),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(o.counterpart.displayName, style: NexoText.body(15, weight: FontWeight.w800)),
                        Text(client ? catInfo(o.category).name : 'Cliente',
                            style: NexoText.body(12.5, color: NexoColors.muted)),
                      ],
                    ),
                  ),
                  if (o.counterpart.providerId != null) const NexoIcon('chevron', size: 18, color: NexoColors.muted),
                ]),
              ),
              if (o.status == 'pending' && !client) ...[
                const SizedBox(height: 10),
                const Notice('¿Dudas? Pregúntale antes de aceptar.'),
              ],
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: NexoButton(
                    label: 'Mensaje',
                    icon: 'chat',
                    variant: o.status == 'pending' && !client ? NexoButtonVariant.line : NexoButtonVariant.primary,
                    onPressed: () => _chat(o),
                  ),
                ),
                if (o.can('copyPhone') || o.counterpart.canCopyPhone) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: NexoButton(
                      label: 'Copiar número',
                      icon: 'copy',
                      variant: NexoButtonVariant.ghost,
                      onPressed: () => _copyPhone(o),
                    ),
                  ),
                ],
              ]),
            ],
          ),
        ),
        // ---- qué acordaron
        NexoCard(
          child: Column(children: [
            InfoRow('Servicio', catInfo(o.category).name),
            if (o.description.isNotEmpty) InfoRow('Lo que se pidió', o.description),
            if (o.agreedPrice != null)
              InfoRow('Precio acordado', o.agreedPrice!.display, sub: o.agreedPrice!.includes, highlight: true)
            else if (o.status == 'accepted' || o.status == 'resolved')
              const InfoRow('Precio acordado', 'Sin precio · lo acuerdan en el chat', muted: true),
            InfoRow(
              'Cómo llegó',
              o.requestId != null
                  ? (client ? 'Se postuló a tu solicitud y le hiciste el pedido' : 'Te postulaste y te hizo el pedido')
                  : (client ? 'Le hiciste el pedido desde su perfil' : 'Te hizo el pedido desde tu perfil'),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _actions(o, client)),
        if (o.timeline.isNotEmpty) ...[
          const Sect('Historial'),
          for (final t in o.timeline)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 16, 4),
              child: Row(children: [
                const NexoIcon('check', size: 15, color: NexoColors.brand),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(t.text.isEmpty ? t.type : t.text, style: NexoText.body(13.5, color: NexoColors.muted))),
              ]),
            ),
        ],
      ],
    );
  }

  Widget _actions(Order o, bool client) {
    Widget two(Widget a, Widget b) => Row(children: [Expanded(child: a), const SizedBox(width: 8), Expanded(child: b)]);
    switch (o.status) {
      case 'pending' when !client:
        return two(
          NexoButton(label: 'Rechazar', variant: NexoButtonVariant.ghost, onPressed: _busy ? null : () => _reject(o)),
          NexoButton(label: 'Aceptar pedido', icon: 'check', loading: _busy, onPressed: () => _accept(o)),
        );
      case 'pending':
        return NexoButton(
            label: 'Cancelar solicitud', variant: NexoButtonVariant.ghost, loading: _busy, onPressed: () => _cancel(o));
      case 'accepted' when !client:
        return two(
          NexoButton(label: 'Cancelar', variant: NexoButtonVariant.ghost, onPressed: _busy ? null : () => _cancel(o)),
          NexoButton(label: 'Marcar como resuelto', icon: 'check', loading: _busy, onPressed: () => _resolve(o)),
        );
      case 'accepted':
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Notice('${o.counterpart.displayName} lo marcará como resuelto al terminar. Después podrás calificarlo.'),
          const SizedBox(height: 10),
          NexoButton(
              label: 'Cancelar servicio',
              variant: NexoButtonVariant.ghost,
              loading: _busy,
              onPressed: () => _cancel(o)),
        ]);
      case 'resolved' when client:
        if (o.myReviewStars != null) {
          return NexoCard(
            margin: EdgeInsets.zero,
            child: Column(children: [
              Text('Tu calificación', style: NexoText.display(16, weight: FontWeight.w700)),
              const SizedBox(height: 8),
              StarsView(o.myReviewStars!, size: 26),
            ]),
          );
        }
        if (!o.canReview) return const SizedBox.shrink();
        return NexoCard(
          margin: EdgeInsets.zero,
          child: Column(children: [
            Text('¿Cómo te fue con ${o.counterpart.displayName}?',
                textAlign: TextAlign.center, style: NexoText.display(17, weight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Toca las estrellas para calificar.', style: NexoText.body(13.5, color: NexoColors.muted)),
            const SizedBox(height: 8),
            StarPicker(value: 0, onChanged: (n) => _review(o, n)),
          ]),
        );
      case 'resolved':
        return Notice('Le pedimos a ${o.counterpart.displayName} que califique el servicio.',
            icon: 'check', tone: BadgeTone.ok);
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _chat(Order o) async {
    if (o.conversationId != null) {
      context.push(Routes.chat(o.conversationId!));
    } else if (o.counterpart.providerId != null) {
      await openChatWithProvider(context, ref, o.counterpart.providerId!, requestId: o.requestId);
    } else if (o.requestId != null) {
      await openChatForRequest(context, ref, o.requestId!);
    } else {
      showNexoToast('Abre el chat desde Mensajes.');
    }
  }

  Future<void> _copyPhone(Order o) async {
    try {
      final r = await ref.read(apiProvider).revealPhone(targetId: o.id, targetType: 'order', context: 'order');
      await Clipboard.setData(ClipboardData(text: r.displayPhone));
      showNexoToast('Número copiado: ${r.displayPhone}');
    } catch (e) {
      showNexoToast(apiErrorMessage(e));
    }
  }

  Future<void> _changeAddress(Order o) async {
    final r = await context.push<LocationPick>(Routes.location,
        extra: LocationPickerArgs(
          title: 'Tu domicilio',
          subtitle: 'Mueve el mapa hasta tu casa.',
          initial: o.location,
          showRadius: false,
          button: 'Usar este punto',
        ));
    if (r == null || !mounted) return;
    final text = await _askText(
      title: 'Calle, número y referencias',
      hint: 'Ej. Hidalgo 24, portón negro',
      initial: o.address ?? '',
      button: 'Guardar dirección',
    );
    if (text == null || text.trim().length < 5) return;
    await _run(
        () => ref.read(apiProvider).updateAddress(o, address: text.trim(), location: r.point), 'Dirección actualizada');
  }

  Future<String?> _askText({required String title, required String hint, String initial = '', required String button}) {
    final c = TextEditingController(text: initial);
    return showNexoSheet<String>(
      context,
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title),
          TextField(
            controller: c,
            autofocus: true,
            maxLength: 120,
            style: NexoText.body(15),
            decoration: nexoInputDecoration(hint: hint),
          ),
          const SizedBox(height: 8),
          NexoButton(label: button, onPressed: () => Navigator.of(ctx).pop(c.text)),
        ],
      ),
    );
  }

  Future<void> _accept(Order o) async {
    final res = await showNexoSheet<(int?, String?)>(context, builder: (_) => const _AcceptSheet());
    if (res == null) return;
    await _run(
        () => ref.read(apiProvider).acceptOrder(o, amountCents: res.$1, includes: res.$2), 'Aceptaste el pedido');
  }

  Future<void> _reject(Order o) async {
    const reasons = [
      ('noAvailability', 'No tengo disponibilidad'),
      ('outOfArea', 'Está fuera de mi zona'),
      ('notMyService', 'No es un servicio que ofrezco'),
      ('priceDisagreement', 'No llegamos a un acuerdo de precio'),
      ('other', 'Otro motivo'),
    ];
    final reason = await showNexoSheet<String>(
      context,
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHeader('Rechazar pedido', subtitle: 'Le avisaremos con amabilidad. Elige el motivo.'),
          for (final r in reasons) ...[
            OptRow(icon: 'close', label: r.$2, onTap: () => Navigator.of(ctx).pop(r.$1)),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
    if (reason == null) return;
    await _run(() => ref.read(apiProvider).rejectOrder(o, reason: reason), 'Rechazaste el pedido');
  }

  Future<void> _cancel(Order o) async {
    final ok = await confirmSheet(context,
        title: o.status == 'pending' ? '¿Cancelar tu solicitud?' : '¿Cancelar el servicio?',
        subtitle: 'Le avisaremos a ${o.counterpart.displayName}. Esta acción no se puede deshacer.',
        confirmLabel: 'Sí, cancelar',
        cancelLabel: 'Volver');
    if (ok != true) return;
    await _run(
        () => ref
            .read(apiProvider)
            .cancelOrder(o, reason: o.iAmProvider ? 'No tengo disponibilidad' : 'Ya no lo necesito'),
        'Pedido cancelado');
  }

  Future<void> _resolve(Order o) async {
    final res = await showNexoSheet<(int?, String?)>(context,
        builder: (_) => _AcceptSheet(resolve: true, initialCents: o.agreedPrice?.amountCents));
    if (res == null) return;
    await _run(() => ref.read(apiProvider).resolveOrder(o, finalPriceCents: res.$1, note: res.$2),
        'Servicio marcado como resuelto');
  }

  Future<void> _review(Order o, int stars) async {
    final res = await showNexoSheet<(int, String, bool)>(context,
        builder: (_) => _ReviewSheet(stars: stars, name: o.counterpart.displayName));
    if (res == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(apiProvider).review(orderId: o.id, stars: res.$1, text: res.$2, recommend: res.$3);
      ref.invalidate(orderProvider(o.id));
      refreshActivity(ref);
      if (o.counterpart.providerId != null) ref.invalidate(reviewsProvider(o.counterpart.providerId!));
      showNexoToast('¡Gracias! Tu calificación ayuda a otras personas a decidir.');
    } catch (e) {
      showNexoToast(apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _Steps extends StatelessWidget {
  const _Steps({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    const labels = ['Pedido', 'Aceptado', 'Resuelto'];
    return Semantics(
      label: 'Estado: ${labels[step]}',
      child: Row(
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) Expanded(child: Container(height: 2, color: i <= step ? NexoColors.brand : NexoColors.line)),
            Column(children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < step ? NexoColors.brand : (i == step ? NexoColors.brandSoft : NexoColors.surface2),
                  border: Border.all(color: i <= step ? NexoColors.brand : NexoColors.line, width: 1.5),
                ),
                child: Center(
                  child: i < step
                      ? const NexoIcon('check', size: 15, color: Colors.white, strokeWidth: 2.4)
                      : Text('${i + 1}',
                          style: NexoText.body(13,
                              weight: FontWeight.w800, color: i == step ? NexoColors.brand : NexoColors.muted)),
                ),
              ),
              const SizedBox(height: 4),
              Text(labels[i],
                  style: NexoText.body(12,
                      weight: i == step ? FontWeight.w800 : FontWeight.w600,
                      color: i <= step ? NexoColors.ink : NexoColors.muted)),
            ]),
          ],
        ],
      ),
    );
  }
}

/// Aceptar con precio acordado (opcional) o marcar resuelto con precio final.
class _AcceptSheet extends StatefulWidget {
  const _AcceptSheet({this.resolve = false, this.initialCents});
  final bool resolve;
  final int? initialCents;
  @override
  State<_AcceptSheet> createState() => _AcceptSheetState();
}

class _AcceptSheetState extends State<_AcceptSheet> {
  late final _amt = TextEditingController(text: widget.initialCents == null ? '' : '${widget.initialCents! ~/ 100}');
  final _note = TextEditingController();

  @override
  void dispose() {
    _amt.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader(widget.resolve ? 'Marcar como resuelto' : 'Aceptar pedido',
            subtitle: widget.resolve
                ? 'Confirma el precio final (opcional). Le pediremos al cliente que te califique.'
                : 'Si ya acordaron el precio, escríbelo. Si no, lo acuerdan en el chat.'),
        TextField(
          controller: _amt,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: NexoText.body(16, weight: FontWeight.w700),
          decoration:
              nexoInputDecoration(hint: widget.resolve ? 'Precio final (opcional)' : 'Precio acordado (opcional)')
                  .copyWith(prefixText: '\$ '),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _note,
          maxLength: 100,
          style: NexoText.body(15),
          decoration: nexoInputDecoration(
              hint: widget.resolve ? 'Nota (opcional)' : '¿Qué incluye? Ej. Material y mano de obra'),
        ),
        const SizedBox(height: 6),
        NexoButton(
          label: widget.resolve ? 'Marcar como resuelto' : 'Aceptar pedido',
          icon: 'check',
          onPressed: () {
            final n = int.tryParse(_amt.text);
            Navigator.of(context)
                .pop((n == null ? null : n * 100, _note.text.trim().isEmpty ? null : _note.text.trim()));
          },
        ),
      ],
    );
  }
}

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet({required this.stars, required this.name});
  final int stars;
  final String name;
  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  late int _stars = widget.stars;
  bool _rec = true;
  final _text = TextEditingController();

  @override
  void initState() {
    super.initState();
    _rec = widget.stars >= 4;
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader('Califica a ${widget.name}', subtitle: 'Tu opinión se publica en su perfil con tu nombre corto.'),
        Center(child: StarPicker(value: _stars, onChanged: (n) => setState(() => _stars = n))),
        const SizedBox(height: 12),
        TextField(
          controller: _text,
          maxLines: 3,
          maxLength: 280,
          style: NexoText.body(15),
          decoration: nexoInputDecoration(hint: '¿Cómo te fue? (opcional)'),
        ),
        Text('¿Lo recomiendas?', style: NexoText.body(14, weight: FontWeight.w800)),
        const SizedBox(height: 8),
        SegControl<bool>(
          small: true,
          options: const [(true, 'Sí'), (false, 'No')],
          value: _rec,
          onChanged: (v) => setState(() => _rec = v),
        ),
        const SizedBox(height: 14),
        NexoButton(
          label: 'Publicar calificación',
          icon: 'star',
          onPressed: () => Navigator.of(context).pop((_stars, _text.text.trim(), _rec)),
        ),
      ],
    );
  }
}
