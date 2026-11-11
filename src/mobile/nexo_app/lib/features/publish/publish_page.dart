import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../app/router.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../core/auth/session_controller.dart';
import '../../core/local/local_store.dart';
import '../../core/network/api_exception.dart';
import '../../core/widgets/nexo_button.dart';
import '../../core/widgets/nexo_icon.dart';
import '../../core/widgets/nexo_sheet.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/ui.dart';
import '../../data/api_provider.dart';
import '../../data/models.dart';
import '../../core/widgets/pick_image.dart';
import '../../data/nexo_api.dart';
import '../intelligence/assist_sheet.dart';
import '../intelligence/category_suggester.dart';
import '../location/location_picker_page.dart';
import '../shell/gate.dart';
import 'publish_option_row.dart';

/// Título a partir del texto (`autoTitle`): la primera frase, máx. 90.
String autoTitle(String text) {
  final t = text.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (t.isEmpty) return '';
  final cut = t.split(RegExp(r'[.!?\n]')).first.trim();
  final s = cut.length < 5 ? t : cut;
  return s.length <= 90 ? s : '${s.substring(0, 87).trimRight()}…';
}

Future<bool> _publishedSheet(BuildContext context, {required String title, required String detail}) async =>
    await showNexoSheet<bool>(context, builder: (sheet) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Center(child: Container(
          width: 66, height: 66,
          decoration: const BoxDecoration(color: NexoColors.brandSoft, shape: BoxShape.circle),
          child: const Center(child: NexoIcon('check', size: 30, color: NexoColors.brand)),
        )),
        const SizedBox(height: 16),
        Text(title, textAlign: TextAlign.center, style: NexoText.display(23, weight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(detail, textAlign: TextAlign.center, style: NexoText.body(14, color: NexoColors.muted, height: 1.45)),
        const SizedBox(height: 22),
        NexoButton(label: 'Ver publicación', onPressed: () => Navigator.of(sheet).pop(true)),
        const SizedBox(height: 8),
        NexoButton(label: 'Volver a Inicio', variant: NexoButtonVariant.ghost, onPressed: () => Navigator.of(sheet).pop(false)),
      ],
    )) ?? false;

/// 7.10 Publicar (`V.publish`): "Busco un servicio" y "Mi experiencia" para
/// el cliente; "Publicar un trabajo" para el prestador.
class PublishPage extends ConsumerStatefulWidget {
  const PublishPage({super.key});

  @override
  ConsumerState<PublishPage> createState() => _PublishPageState();
}

class _PublishPageState extends ConsumerState<PublishPage> {
  String _kind = 'req';

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sessionProvider);
    if (s.isGuest) {
      return const GateScreen(
          title: 'Publicar',
          icon: 'plus',
          text: 'Necesitas una cuenta para publicar lo que buscas o los trabajos que realizas.');
    }
    if (s.isProviderMode) {
      final mp = ref.watch(myProviderProvider);
      return mp.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(e, onRetry: () => ref.invalidate(myProviderProvider)),
        data: (me) => me == null ? const NoProviderProfile(title: 'Publicar un trabajo') : _WorkComposer(me: me),
      );
    }
    return _kind == 'req'
        ? _RequestComposer(onKind: (k) => setState(() => _kind = k))
        : _ExperienceComposer(onKind: (k) => setState(() => _kind = k));
  }
}

/// Barra superior del compositor (`compTop`).
class _CompTop extends StatelessWidget {
  const _CompTop({required this.enabled, required this.loading, required this.onPublish});
  final bool enabled;
  final bool loading;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    return ScreenTitleBar(
      'Publicar',
      trailing: NexoButton(
          label: 'Publicar', small: true, block: false, loading: loading, onPressed: enabled ? onPublish : null),
    );
  }
}

class _KindTabs extends StatelessWidget {
  const _KindTabs({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: SegControl<String>(
          options: const [('req', 'Busco un servicio'), ('exp', 'Mi experiencia')],
          value: value,
          onChanged: onChanged,
        ),
      );
}

/// Usuario que publica (`compUser`).
class _CompUser extends StatelessWidget {
  const _CompUser({required this.name, this.photo, required this.sub, this.pills});
  final String name;
  final String? photo;
  final String sub;
  final Widget? pills;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NexoAvatar(name: name, url: photo),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: NexoText.body(15, weight: FontWeight.w800)),
                if (pills != null) ...[const SizedBox(height: 6), pills!] else
                  Text(sub, style: NexoText.body(12.5, color: NexoColors.muted)),
              ],
            ),
          ),
        ],
      );
}

/// Fila de opción del compositor (`optRow` → `.crow`).
Widget _composeBox({required List<Widget> children}) => Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: NexoColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: NexoColors.line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );

TextField _bigText(TextEditingController c, String hint, int max, VoidCallback onChanged) => TextField(
      controller: c,
      minLines: 4,
      maxLines: 8,
      maxLength: max,
      onChanged: (_) => onChanged(),
      textCapitalization: TextCapitalization.sentences,
      style: NexoText.body(17, height: 1.4),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: NexoText.body(17, color: NexoColors.muted),
        border: InputBorder.none,
        counterStyle: NexoText.body(12, color: NexoColors.muted),
      ),
    );

Future<T?> _choose<T>(BuildContext context, String title, List<(T, String, String)> options, T? current) {
  return showNexoSheet<T>(
    context,
    builder: (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader(title),
        for (final o in options) ...[
          OptRow(icon: o.$3, label: o.$2, selected: current == o.$1, onTap: () => Navigator.of(ctx).pop(o.$1)),
          const SizedBox(height: 8),
        ],
      ],
    ),
  );
}

// ======================================================= busco un servicio

class _RequestComposer extends ConsumerStatefulWidget {
  const _RequestComposer({required this.onKind});
  final ValueChanged<String> onKind;
  @override
  ConsumerState<_RequestComposer> createState() => _RequestComposerState();
}

class _RequestComposerState extends ConsumerState<_RequestComposer> {
  final _text = TextEditingController();
  String? _cat;
  String _urg = 'week';
  String _contact = 'chat';
  GeoPoint? _loc;
  String? _zone;
  final List<PickedImage> _imgs = [];
  final Map<PickedImage, String> _uploaded = {};
  bool _busy = false;
  String _idem = const Uuid().v4();
  String? _lastPayload;
  CategoryGuess? _guess;

  Future<void> _assist() async {
    final r = await showAssistSheet(context, kind: 'request', category: _cat!, userText: _text.text);
    if (r != null && mounted) {
      setState(() => _text.text = r);
    }
  }

  static const _urgs = [('today', 'Hoy', 'bolt'), ('week', 'Esta semana', 'clock'), ('noRush', 'Sin prisa', 'info')];

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _ok =>
      !_busy &&
      _cat != null &&
      _text.text.trim().length >= 10 &&
      (_loc != null || ref.read(searchLocationProvider).hasSelection);

  Future<void> _publish() async {
    setState(() => _busy = true);
    final api = ref.read(apiProvider);
    final loc = ref.read(searchLocationProvider);
    if (_loc == null && !loc.hasSelection) {
      setState(() => _busy = false);
      showNexoToast('Elige la ubicación real del servicio antes de publicar.');
      return;
    }
    final payload =
        '$_cat|${_text.text.trim()}|$_urg|$_contact|${(_loc ?? loc.point).lat}|${(_loc ?? loc.point).lng}|${_imgs.map((i) => i.path).join(',')}';
    if (_lastPayload != null && _lastPayload != payload) _idem = const Uuid().v4();
    _lastPayload = payload;
    try {
      final ids = <String>[];
      for (final image in _imgs) {
        _uploaded[image] ??= await api.upload(image, purpose: 'request');
        ids.add(_uploaded[image]!);
      }
      await api.createRequest(
        category: _cat!,
        title: autoTitle(_text.text),
        description: _text.text.trim(),
        urgency: _urg,
        contact: _contact,
        location: _loc ?? loc.point,
        imageUploadIds: ids,
        idempotencyKey: _idem,
      );
      refreshActivity(ref);
      final showPost = mounted && await _publishedSheet(context,
          title: 'Tu solicitud ya está publicada',
          detail: 'Los prestadores de tu zona pueden verla e interesarse. Podrás editarla desde Mis solicitudes.');
      _reset();
      if (mounted) {
        context.go(Routes.home);
        if (showPost) context.push(Routes.myProfile, extra: ref.read(accountProvider).asData?.value);
      }
    } on ApiException catch (e) {
      if (e.code == kQueuedOffline) {
        // Sin señal: quedó en la cola y se publica al volver la conexión.
        showNexoToast(apiErrorMessage(e));
        _reset();
      } else if (e.code == 'server.dependency_unavailable') {
        showNexoToast('No se pudo validar o guardar tu solicitud. Tu texto sigue aquí; inténtalo más tarde.');
      } else {
        showNexoToast(apiErrorMessage(e));
      }
    } catch (e) {
      showNexoToast(apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _reset() => setState(() {
        _text.clear();
        _cat = null;
        _imgs.clear();
        _uploaded.clear();
        _guess = null;
        _idem = const Uuid().v4();
        _lastPayload = null;
      });

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sessionProvider);
    final loc = ref.watch(searchLocationProvider);
    final first = (s.name ?? '').split(' ').first;
    final zone = _zone ?? loc.zoneLabel;
    return PinnedHeaderList(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _CompTop(enabled: _ok, loading: _busy, onPublish: _publish),
        _KindTabs(value: 'req', onChanged: widget.onKind),
        _composeBox(children: [
           _CompUser(name: s.name ?? 'Tú', photo: ref.watch(accountProvider).asData?.value?.photoUrl,
               sub: 'Visible para prestadores de $zone'),
          _bigText(_text, '¿Qué necesitas resolver${first.isEmpty ? '' : ', $first'}?', 600, () => setState(() {})),
          if (_imgs.isNotEmpty)
            SizedBox(
                height: 116,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imgs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => SizedBox(
                      width: 116,
                      child: Stack(children: [
                        ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: SizedBox.expand(child: NexoImage('file://${_imgs[i].path}'))),
                        Positioned(
                            right: 2,
                            top: 2,
                            child: NexoIconButton(
                                icon: 'close',
                                label: 'Quitar foto ${i + 1}',
                                size: 34,
                                circle: true,
                                onTap: () => setState(() => _imgs.removeAt(i)))),
                      ])),
                )),
          if (_imgs.length < 6)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  final images = await pickImages(max: 6 - _imgs.length);
                  if (mounted) setState(() => _imgs.addAll(images));
                },
                icon: const NexoIcon('camera', size: 18, color: NexoColors.brand),
                label: Text('Agregar fotos (${_imgs.length}/6)',
                    style: NexoText.body(14, weight: FontWeight.w700, color: NexoColors.brand)),
              ),
            ),
          if (_guess != null && _cat == null)
            CategoryGuessNotice(
              guess: _guess!,
              name: catInfo(_guess!.category).name,
              onUse: () => setState(() {
                _cat = _guess!.category;
                _guess = null;
              }),
              onDismiss: () => setState(() => _guess = null),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: AssistButton(enabled: _cat != null && _text.text.trim().length >= 10, onTap: _assist),
          ),
        ]),
        Container(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          decoration: BoxDecoration(
            color: NexoColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: NexoColors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            type: MaterialType.transparency,
            child: Column(children: [
              PublishOptionRow(
                icon: _cat == null ? 'hammer' : catInfo(_cat!).icon,
                label: 'Servicio',
                value: _cat == null ? 'Elegir' : catInfo(_cat!).name,
                empty: _cat == null,
                onTap: () async {
                  try {
                    final cats = await ref.read(catalogProvider.future);
                    if (!context.mounted) return;
                    final c = await _choose<String>(
                        context, '¿Qué servicio necesitas?', [for (final c in cats) (c.id, c.name, c.icon)], _cat);
                    if (c != null && mounted) setState(() => _cat = c);
                  } catch (e) {
                    ref.invalidate(catalogProvider);
                    showNexoToast(apiErrorMessage(e));
                  }
                },
              ),
              PublishOptionRow(
                icon: 'pin',
                label: 'Ubicación',
                value: zone,
                onTap: () async {
                  final r = await context.push<LocationPick>(Routes.location,
                      extra: LocationPickerArgs(
                        title: '¿Dónde es el servicio?',
                        subtitle: 'Los prestadores ven la zona aproximada; tu punto exacto no se publica.',
                        initial: _loc ?? loc.point,
                        showRadius: false,
                        button: 'Usar esta ubicación',
                      ));
                  if (r != null) {
                    setState(() {
                      _loc = r.point;
                      _zone = r.zoneLabel;
                    });
                  }
                },
              ),
              PublishOptionRow(
                icon: 'clock',
                label: '¿Para cuándo?',
                value: _urgs.firstWhere((u) => u.$1 == _urg).$2,
                onTap: () async {
                  final u = await _choose<String>(context, '¿Para cuándo lo necesitas?', _urgs, _urg);
                  if (u != null) setState(() => _urg = u);
                },
              ),
              PublishOptionRow(
                icon: 'chat',
                label: 'Te contactan por',
                value: _contact == 'chat' ? 'Solo chat' : 'Chat y llamada',
                onTap: () async {
                  final c = await _choose<String>(
                      context,
                      '¿Cómo quieres que te contacten?',
                      const [
                        ('chat', 'Solo chat (tu número no se muestra)', 'chat'),
                        ('chatCall', 'Chat y llamada', 'phone')
                      ],
                      _contact);
                  if (c != null) setState(() => _contact = c);
                },
              ),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text(
            _ok
                ? 'Listo para publicar. Los prestadores de tu zona podrán interesarse.'
                : 'Escribe al menos 10 caracteres y elige el servicio.',
            style: NexoText.body(13, color: _ok ? NexoColors.ok : NexoColors.muted),
          ),
        ),
      ],
    );
  }
}

// ========================================================== mi experiencia

class _ExperienceComposer extends ConsumerStatefulWidget {
  const _ExperienceComposer({required this.onKind});
  final ValueChanged<String> onKind;
  @override
  ConsumerState<_ExperienceComposer> createState() => _ExperienceComposerState();
}

class _ExperienceComposerState extends ConsumerState<_ExperienceComposer> {
  final _text = TextEditingController();
  Order? _order;
  int _stars = 0;
  bool? _rec;
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _ok => _order != null && _stars > 0 && _rec != null;

  Future<void> _publish() async {
    setState(() => _busy = true);
    try {
      await ref.read(apiProvider).review(orderId: _order!.id, stars: _stars, text: _text.text.trim(), recommend: _rec!);
      refreshActivity(ref);
      ref.invalidate(ordersProvider);
      showNexoToast('Publicado en el perfil de ${_order!.counterpart.displayName}. ¡Gracias!');
      setState(() {
        _text.clear();
        _order = null;
        _stars = 0;
        _rec = null;
      });
    } catch (e) {
      showNexoToast(apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sessionProvider);
    final orders = ref.watch(ordersProvider('client')).asData?.value.items ?? const <Order>[];
    final pending = orders.where((o) => o.status == 'resolved' && o.canReview).toList();
    return PinnedHeaderList(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _CompTop(enabled: _ok, loading: _busy, onPublish: _publish),
        _KindTabs(value: 'exp', onChanged: widget.onKind),
        if (pending.isEmpty)
          const EmptyState(
            icon: 'thumb',
            title: 'Aún no tienes servicios por calificar',
            text:
                'Cuando un prestador marque como resuelto un servicio que le pediste, podrás contar aquí cómo te fue.',
          )
        else ...[
          _composeBox(children: [
            _CompUser(name: s.name ?? 'Tú', sub: 'Se publica en el perfil del prestador'),
            _bigText(
                _text,
                _order == null
                    ? '¿Cómo te fue con el servicio?'
                    : '¿Cómo te fue con ${_order!.counterpart.displayName}?',
                280,
                () => setState(() {})),
          ]),
          Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            decoration: BoxDecoration(
              color: NexoColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: NexoColors.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              type: MaterialType.transparency,
              child: Column(children: [
                PublishOptionRow(
                  icon: 'user',
                  label: 'Prestador',
                  value: _order == null ? 'Etiquetar' : '@${_order!.counterpart.displayName}',
                  empty: _order == null,
                  onTap: () async {
                    final o = await _choose<Order>(
                      context,
                      '¿A quién calificas?',
                      [
                        for (final o in pending)
                          (o, '${o.counterpart.displayName} · ${catInfo(o.category).name}', catInfo(o.category).icon)
                      ],
                      _order,
                    );
                    if (o != null) setState(() => _order = o);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(children: [
                    Text('Calificación', style: NexoText.body(14.5, weight: FontWeight.w600)),
                    const Spacer(),
                    StarPicker(value: _stars, size: 28, onChanged: (n) => setState(() => _stars = n)),
                  ]),
                ),
                const Divider(height: 1, color: NexoColors.line),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(children: [
                    Expanded(child: Text('¿Lo recomiendas?', style: NexoText.body(14.5, weight: FontWeight.w600))),
                    SizedBox(
                      width: 150,
                      child: SegControl<bool?>(
                        small: true,
                        options: const [(true, 'Sí'), (false, 'No')],
                        value: _rec,
                        onChanged: (v) => setState(() => _rec = v),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        ],
      ],
    );
  }
}

// ========================================================= trabajo (pres.)

class _WorkComposer extends ConsumerStatefulWidget {
  const _WorkComposer({required this.me});
  final MyProvider me;
  @override
  ConsumerState<_WorkComposer> createState() => _WorkComposerState();
}

class _WorkComposerState extends ConsumerState<_WorkComposer> {
  final _text = TextEditingController();
  final _tag = TextEditingController();
  late String _cat = widget.me.profile.categories.isEmpty ? 'otros' : widget.me.profile.categories.first;
  final List<PickedImage> _imgs = [];
  final Map<PickedImage, String> _uploaded = {};
  String _idem = const Uuid().v4();
  String? _lastPayload;
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    _tag.dispose();
    super.dispose();
  }

  bool get _ok => !_busy && _text.text.trim().length >= 20 && widget.me.location != null;

  Future<void> _assist() async {
    final r = await showAssistSheet(context, kind: 'work', category: _cat, userText: _text.text);
    if (r != null && mounted) setState(() => _text.text = r);
  }

  String _hint(int len) => len >= 20
      ? 'Listo para publicar'
      : len == 0
          ? 'Cuenta qué hiciste, el problema y cuánto tardaste'
          : 'Escribe ${20 - len} caracteres más';

  Future<void> _publish() async {
    setState(() => _busy = true);
    final api = ref.read(apiProvider);
    final p = widget.me.profile;
    final payload =
        '$_cat|${_text.text.trim()}|${_tag.text.trim()}|${widget.me.location?.lat}|${widget.me.location?.lng}|${_imgs.map((i) => i.path).join(',')}';
    if (_lastPayload != null && _lastPayload != payload) _idem = const Uuid().v4();
    _lastPayload = payload;
    try {
      final ids = <String>[];
      for (final i in _imgs) {
        _uploaded[i] ??= await api.upload(i, purpose: 'work');
        ids.add(_uploaded[i]!);
      }
      await api.createWork(
        category: _cat,
        title: autoTitle(_text.text),
        text: _text.text.trim(),
        tag: _tag.text.trim().isEmpty ? null : _tag.text.trim(),
        location: widget.me.location,
        idempotencyKey: _idem,
        imageUploadIds: ids,
      );
      ref.invalidate(providerWorksProvider(p.id));
      ref.invalidate(myProviderProvider);
      ref.invalidate(feedProvider);
      final showPost = mounted && await _publishedSheet(context,
          title: 'Tu trabajo ya está publicado',
          detail: 'Ya forma parte de tu perfil profesional. Puedes revisarlo y editarlo cuando lo necesites.');
      setState(() {
        _text.clear();
        _tag.clear();
        _imgs.clear();
        _uploaded.clear();
        _idem = const Uuid().v4();
        _lastPayload = null;
      });
      if (mounted) {
        context.go(Routes.home);
        if (showPost) context.push(Routes.provider(p.id));
      }
    } catch (e) {
      showNexoToast(e is ApiException && e.code == 'server.dependency_unavailable'
          ? 'No se pudo validar o guardar el trabajo. Conservamos tu borrador; inténtalo más tarde.'
          : apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.me.profile;
    final first = (p.owner ?? p.name).split(' ').first;
    final len = _text.text.trim().length;
    return PinnedHeaderList(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _CompTop(enabled: _ok, loading: _busy, onPublish: _publish),
        _composeBox(children: [
          _CompUser(
            name: p.name,
            photo: p.photoUrl,
            sub: p.zoneLabel,
            pills: Wrap(spacing: 6, runSpacing: 6, children: [
              for (final c in p.categories)
                ToggleChip(
                    label: catInfo(c).name,
                    icon: catInfo(c).icon,
                    selected: _cat == c,
                    onTap: () => setState(() => _cat = c)),
              NBadge(p.zoneLabel, icon: 'pin', tone: BadgeTone.brand),
            ]),
          ),
          _bigText(_text, '¿Qué trabajo hiciste, $first?', 1000, () => setState(() {})),
          Align(alignment: Alignment.centerLeft, child: AssistButton(enabled: len >= 10, onTap: _assist)),
          if (_imgs.isNotEmpty)
            SizedBox(
              height: 92,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                for (var i = 0; i < _imgs.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(width: 92, height: 92, child: NexoImage('file://${_imgs[i].path}')),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: NexoIconButton(
                            icon: 'close',
                            label: 'Quitar foto ${i + 1}',
                            size: 28,
                            circle: true,
                            onTap: () => setState(() => _imgs.removeAt(i))),
                      ),
                    ]),
                  ),
              ]),
            ),
          const SizedBox(height: 6),
          TextField(
            controller: _tag,
            maxLength: 40,
            style: NexoText.body(14),
            decoration: InputDecoration(
              hintText: 'Etiqueta (opcional): Antes y después, Reparación…',
              hintStyle: NexoText.body(14, color: NexoColors.muted),
              border: InputBorder.none,
              prefixIcon: const Padding(
                  padding: EdgeInsets.only(right: 6), child: NexoIcon('flag', size: 17, color: NexoColors.muted)),
              prefixIconConstraints: const BoxConstraints(minWidth: 26),
            ),
          ),
          const Divider(height: 1, color: NexoColors.line),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(children: [
              if (_imgs.length < 6)
                TextButton.icon(
                  onPressed: () async {
                    final images = await pickImages(max: 6 - _imgs.length);
                    if (mounted) setState(() => _imgs.addAll(images));
                  },
                  icon: const NexoIcon('camera', size: 18, color: NexoColors.brand),
                  label:
                      Text('Agregar fotos', style: NexoText.body(14, weight: FontWeight.w700, color: NexoColors.brand)),
                )
              else
                const NBadge('6 fotos', icon: 'check', tone: BadgeTone.ok),
              const Spacer(),
              Flexible(
                child: Text(_hint(len),
                    textAlign: TextAlign.right,
                    style: NexoText.body(12.5,
                        weight: FontWeight.w600, color: len >= 20 ? NexoColors.ok : NexoColors.muted)),
              ),
            ]),
          ),
        ]),
        if (_imgs.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              const NexoIcon('image', size: 17, color: NexoColors.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Las fotos del antes y después ayudan a que te elijan.',
                    style: NexoText.body(13, color: NexoColors.muted)),
              ),
            ]),
          ),
      ],
    );
  }
}
