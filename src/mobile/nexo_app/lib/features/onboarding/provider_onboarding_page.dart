import '../../core/widgets/pick_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

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
import '../../core/widgets/ob_scaffold.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/ui.dart';
import '../../core/widgets/photo_feedback.dart';
import '../../data/api_provider.dart';
import '../../core/widgets/catalog_status.dart';
import '../../data/nexo_api.dart';
import '../auth/presentation/done_view.dart';
import '../auth/presentation/legal_sheets.dart';
import '../location/location_picker_page.dart';

/// Registro del prestador (`OBSTEPS.pro`): tipo → datos → servicios → zona →
/// listo. Horario, precios y condiciones se completan después desde el perfil.
class ProviderOnboardingPage extends ConsumerStatefulWidget {
  const ProviderOnboardingPage({super.key});

  @override
  ConsumerState<ProviderOnboardingPage> createState() => _ProviderOnboardingPageState();
}

class _ProviderOnboardingPageState extends ConsumerState<ProviderOnboardingPage> {
  static const _steps = ['type', 'basic', 'services', 'zones', 'ready'];
  static const _exps = [
    ('<1', 'Menos de 1 año', 0),
    ('1-3', '1 a 3 años', 2),
    ('4-9', '4 a 9 años', 6),
    ('10+', '10 años o más', 10)
  ];
  static const _sectors = [
    ('servicios', 'Servicios', 'user'),
    ('comercial', 'Comercial', 'home'),
    ('industrial', 'Industrial', 'hammer'),
    ('otro', 'Otro', 'dots'),
  ];

  int _i = 0;
  final _d = ProviderDraft();
  String _idem = const Uuid().v4();
  String? _createdProviderId;
  final _name = TextEditingController();
  final _owner = TextEditingController();
  final _bio = TextEditingController();
  final _activity = TextEditingController();
  String? _exp;
  String? _photoLocal;
  String? _coverLocal;
  String? _pendingImage;
  bool _uploadingCover = false;
  bool _busy = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    final s = ref.read(sessionProvider);
    _owner.text = s.name ?? '';
    final selected = ref.read(searchLocationProvider);
    if (selected.hasSelection) {
      _d.location = selected.point;
      _d.zoneLabel = selected.zoneLabel;
    }
    for (final c in [_name, _owner, _bio, _activity]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _owner, _bio, _activity]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _step => _steps[_i];
  bool get _biz => _d.kind == 'business';

  bool get _valid => switch (_step) {
        'type' => true,
        'basic' => _name.text.trim().length >= 3 &&
            (!_biz || _owner.text.trim().length >= 3) &&
            _exp != null &&
            _bio.text.trim().length >= 20,
        'services' => _biz ? _activity.text.trim().length >= 3 : _d.categories.isNotEmpty,
        'zones' => _d.location != null,
        'ready' => _d.acceptedRules,
        _ => false,
      };

  Future<void> _leave() async {
    final ok = await confirmSheet(context,
        title: '¿Salir sin terminar?',
        subtitle: 'Perderás lo que llevas de tu perfil. Puedes crearlo después desde Cuenta.',
        confirmLabel: 'Salir',
        cancelLabel: 'Seguir con mi perfil',
        confirmFirst: false);
    if (ok == true && mounted) context.pop();
  }

  void _back() {
    if (_i == 0) {
      _leave();
    } else {
      setState(() => _i--);
    }
  }

  Future<void> _next() async {
    if (!_valid) return;
    if (_step != 'ready') {
      setState(() => _i++);
      return;
    }
    setState(() => _busy = true);
    _d
      ..name = _name.text.trim()
      ..owner = _owner.text.trim()
      ..bio = _bio.text.trim()
      ..activity = _activity.text.trim()
      ..experience = _exps.firstWhere((e) => e.$1 == _exp).$3
      ..trades = _biz ? [] : [for (final c in _d.categories) catInfo(c).oficio];
    if (_biz) {
      _d.categories = [];
      _d.specialties = [];
    }
    if (_d.attention == 'shop') _d.radiusKm = 0;
    try {
      final api = ref.read(apiProvider);
      _createdProviderId ??= await api.createProvider(_d, idempotencyKey: _idem);
      final tokens = await api.switchMode('provider');
      await ref.read(sessionProvider.notifier).setMode('provider', tokens: tokens, hasProvider: true);
      ref.invalidate(myProviderProvider);
      refreshActivity(ref);
      if (mounted) setState(() => _done = true);
    } catch (e) {
      if (e is ApiException && e.status != null && e.status! >= 400 && e.status! < 500 && _createdProviderId == null) {
        _idem = const Uuid().v4();
      }
      showNexoToast(apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickPhoto({bool cover = false}) async {
    final image = await pickOneImage(context);
    if (image == null || !mounted) return;
    setState(() {
      _busy = true;
      _uploadingCover = cover;
      _pendingImage = 'file://${image.path}';
    });
    try {
      final id = await ref.read(apiProvider).upload(image, purpose: cover ? 'cover' : 'avatar');
      if (mounted) {
        setState(() {
          if (cover) {
            _d.coverUploadId = id;
            _coverLocal = 'file://${image.path}';
          } else {
            _d.photoUploadId = id;
            _photoLocal = 'file://${image.path}';
          }
        });
      }
    } catch (e) {
      showNexoToast(apiErrorMessage(e));
    } finally {
      if (mounted)
        setState(() {
          _busy = false;
          _pendingImage = null;
        });
    }
  }

  Future<void> _pickZone() async {
    final shop = _d.attention == 'shop';
    final r = await context.push<LocationPick>(Routes.location,
        extra: LocationPickerArgs(
          title: shop ? '¿Dónde está tu local?' : '¿Desde dónde sales?',
          subtitle: shop
              ? 'Mueve el mapa hasta la entrada. Los clientes verán cómo llegar.'
              : 'Mueve el punto base y elige hasta dónde llegas. Tu punto exacto no se publica.',
          initial: _d.location,
          radiusKm: _d.radiusKm,
          showRadius: !shop,
          button: 'Usar esta zona',
        ));
    if (r != null) {
      try {
        await ref.read(searchLocationProvider.notifier).set(r.point, r.radiusKm == 0 ? 5 : r.radiusKm,
            source: r.source, zoneLabel: r.zoneLabel);
      } catch (e) {
        showNexoToast(apiErrorMessage(e));
        return;
      }
      if (!mounted) return;
      setState(() {
        _d.location = r.point;
        _d.radiusKm = r.radiusKm;
        _d.zoneLabel = r.zoneLabel ?? _d.zoneLabel;
      });
    }
  }

  // ---------------------------------------------------------------- pasos
  Widget _choice(String id, String icon, String title, String sub, String current, ValueChanged<String> on) {
    final sel = id == current;
    return Semantics(
      button: true,
      selected: sel,
      child: Material(
        color: sel ? NexoColors.brandSoft : NexoColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: sel ? NexoColors.brand : NexoColors.line, width: 1.5),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          onTap: () => on(id),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: sel ? NexoColors.brand : NexoColors.brandSoft, borderRadius: BorderRadius.circular(14)),
                child: Center(child: NexoIcon(icon, color: sel ? Colors.white : NexoColors.brand)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: NexoText.body(16, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(sub, style: NexoText.body(13.5, color: NexoColors.muted, height: 1.4)),
                ]),
              ),
              if (sel) const NexoIcon('check', size: 20, color: NexoColors.brand),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _lbl(String t) => Text(t, style: NexoText.body(14, weight: FontWeight.w800));

  List<Widget> _content() {
    switch (_step) {
      case 'type':
        return [
          _choice(
              'trade',
              'user',
              'Soy una persona con un oficio',
              'Trabajo por mi cuenta, por ejemplo como plomero, electricista, pintora o carpintero.',
              _d.kind,
              (v) => setState(() {
                    _d.kind = v;
                    _d.attention = 'home';
                  })),
          _choice(
              'business',
              'home',
              'Tengo un negocio de servicios',
              'Tengo un nombre comercial y puede haber más personas en mi equipo.',
              _d.kind,
              (v) => setState(() => _d.kind = v)),
        ];
      case 'basic':
        return [
          SizedBox(
              height: 132,
              child: Stack(children: [
                Positioned.fill(
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: _coverLocal == null
                            ? const ColoredBox(color: NexoColors.brandSoft)
                            : NexoImage(_coverLocal!))),
                if (_busy && _uploadingCover && _pendingImage != null)
                  Positioned.fill(
                      child: ClipRRect(borderRadius: BorderRadius.circular(18), child: NexoImage(_pendingImage!))),
                if (_busy && _uploadingCover)
                  const Positioned.fill(
                      child: ClipRRect(
                          borderRadius: BorderRadius.all(Radius.circular(18)), child: PhotoProcessingOverlay())),
                Positioned(
                    right: 12,
                    bottom: 10,
                    child: TextButton.icon(
                      onPressed: _busy ? null : () => _pickPhoto(cover: true),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: Text(_coverLocal == null ? 'Agregar portada' : 'Cambiar portada'),
                    )),
              ])),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _busy ? null : () => _pickPhoto(),
            child: Row(children: [
              SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(children: [
                    NexoAvatar(
                        name: _name.text.isEmpty ? '?' : _name.text,
                        url: _busy && !_uploadingCover ? _pendingImage : _photoLocal,
                        size: 72,
                        icon: _photoLocal == null ? 'camera' : null),
                    if (_busy && !_uploadingCover) const Positioned.fill(child: PhotoProcessingOverlay(circular: true)),
                  ])),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                      _photoLocal != null
                          ? (_biz ? 'Cambiar logotipo' : 'Cambiar foto')
                          : (_biz ? 'Agregar logotipo o fachada' : 'Agregar foto de perfil'),
                      style: NexoText.body(15, weight: FontWeight.w700, color: NexoColors.brand)),
                  Text(_biz ? 'Opcional. Ayuda a que te reconozcan.' : 'Opcional. Una foto tuya genera más confianza.',
                      style: NexoText.body(13, color: NexoColors.muted)),
                ]),
              ),
            ]),
          ),
          NexoField(
            label: _biz ? 'Nombre comercial' : 'Tu nombre completo',
            controller: _name,
            hint: _biz ? 'Ej. Plomería Hernández' : 'Ej. Luis Ortega',
            maxLength: 80,
            capitalization: TextCapitalization.words,
          ),
          if (_biz)
            NexoField(
              label: 'Responsable del perfil',
              controller: _owner,
              hint: 'Ej. Carlos Hernández',
              maxLength: 80,
              capitalization: TextCapitalization.words,
              helper: 'Quien administra el perfil y atiende los contactos.',
            ),
          if (_biz) ...[
            _lbl('¿Cómo atiendes?'),
            _choice('home', 'home', 'A domicilio', 'Voy al lugar del cliente', _d.attention,
                (v) => setState(() => _d.attention = v)),
            _choice('shop', 'pin', 'En mi local', 'El cliente viene a mí', _d.attention,
                (v) => setState(() => _d.attention = v)),
            _choice('both', 'compare', 'Ambas', 'Local y a domicilio', _d.attention,
                (v) => setState(() => _d.attention = v)),
          ],
          _lbl(_biz ? 'Tiempo en operación' : 'Años en tu oficio'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final e in _exps)
              ToggleChip(label: e.$2, selected: _exp == e.$1, onTap: () => setState(() => _exp = e.$1)),
          ]),
          _lbl(_biz ? 'Tu equipo' : '¿Cómo trabajas?'),
          SegControl<String>(
            small: true,
            options: _biz
                ? const [('alone', 'Solo yo'), ('withHelpers', 'Con ayudantes'), ('team', 'Un equipo')]
                : const [('alone', 'Solo'), ('withHelpers', 'Con ayudantes')],
            value: _d.crew,
            onChanged: (v) => setState(() => _d.crew = v),
          ),
          _lbl('Cuéntanos de ti'),
          TextField(
            controller: _bio,
            minLines: 3,
            maxLines: 5,
            maxLength: 600,
            textCapitalization: TextCapitalization.sentences,
            style: NexoText.body(15),
            decoration:
                nexoInputDecoration(hint: 'Qué haces, cómo trabajas y qué te distingue (mínimo 20 caracteres).'),
          ),
        ];
      case 'services':
        return [
          if (_biz) ...[
            _lbl('Rubro'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final s in _sectors)
                ToggleChip(
                    label: s.$2,
                    icon: s.$3,
                    selected: _d.sector == s.$1,
                    onTap: () => setState(() => _d.sector = s.$1)),
            ]),
            NexoField(
              label: '¿A qué se dedica tu negocio?',
              controller: _activity,
              hint: 'Ej. Plomería y mantenimiento de inmuebles',
              maxLength: 80,
            ),
          ],
          if (_biz)
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('Las categorías se asignarán a partir de tu actividad y descripción.',
                    style: NexoText.body(14))),
          if (!_biz) ...[
            _lbl('¿Qué oficio tienes? (hasta 3)'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              const CatalogStatus(),
              for (final c in (ref.watch(catalogProvider).asData?.value ?? []))
                ToggleChip(
                  label: _biz ? c.name : c.oficio,
                  icon: c.icon,
                  selected: _d.categories.contains(c.id),
                  onTap: () => setState(() {
                    if (_d.categories.contains(c.id)) {
                      _d.categories.remove(c.id);
                      _d.specialties.removeWhere(c.specs.contains);
                    } else if (_d.categories.length < 3) {
                      _d.categories.add(c.id);
                    } else {
                      showNexoToast('Máximo 3');
                    }
                  }),
                ),
            ]),
            for (final c in (ref.watch(catalogProvider).asData?.value ?? [])
                .where((c) => _d.categories.contains(c.id) && c.specs.isNotEmpty)) ...[
              _lbl('Especialidades en ${c.name.toLowerCase()} (opcional)'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final s in c.specs)
                  ToggleChip(
                    label: s,
                    selected: _d.specialties.contains(s),
                    onTap: () => setState(() {
                      if (_d.specialties.contains(s)) {
                        _d.specialties.remove(s);
                      } else if (_d.specialties.length < 5) {
                        _d.specialties.add(s);
                      } else {
                        showNexoToast('Máximo 5 especialidades');
                      }
                    }),
                  ),
              ]),
            ],
          ],
        ];
      case 'zones':
        final shop = _d.attention == 'shop';
        return [
          MiniMap(
            point: _d.location ?? ref.read(searchLocationProvider).point,
            radiusKm: shop ? 0 : _d.radiusKm,
            height: 190,
            label: shop ? 'Tu local' : 'Hasta ${_d.radiusKm} km',
            actionLabel: 'Elegir en el mapa',
            onAction: _pickZone,
          ),
          if (!shop) ...[
            _lbl('¿Hasta dónde llegas?'),
            SegControl<int>(
              small: true,
              options: const [(2, '2 km'), (5, '5 km'), (10, '10 km'), (20, '20 km')],
              value: _d.radiusKm,
              onChanged: (v) => setState(() => _d.radiusKm = v),
            ),
          ],
          OneNote(
              icon: 'shield',
              text: shop || _d.attention == 'both'
                  ? 'La ubicación de tu local será pública para que puedan llegar.'
                  : 'Tu punto exacto no se publica: los clientes ven una zona aproximada.'),
        ];
      default:
        return [
          CheckList(items: [
            (true, _biz ? 'Negocio: ${_name.text.trim()}' : 'Tu nombre: ${_name.text.trim()}'),
            (
              true,
              _biz
                  ? 'Actividad: ${_activity.text.trim()}'
                  : 'Servicios: ${_d.categories.map((c) => catInfo(c).name).join(', ')}'
            ),
            (true, _d.attention == 'shop' ? 'Atención en tu local' : 'Zona: hasta ${_d.radiusKm} km'),
            (false, 'Horario, precios y fotos (después, desde tu perfil)'),
          ]),
          OptRow(
            icon: _d.acceptedRules ? 'check' : 'shield',
            label: 'Me comprometo a publicar información verdadera y a tratar con respeto a los clientes.',
            selected: _d.acceptedRules,
            onTap: () => setState(() => _d.acceptedRules = !_d.acceptedRules),
          ),
          Wrap(spacing: 16, children: [
            NexoLink('Leer Términos', onTap: () => showTermsSheet(context)),
            NexoLink('Leer Aviso de privacidad', onTap: () => showPrivacySheet(context)),
          ]),
        ];
    }
  }

  static const _titles = {
    'type': (
      '¿Cómo vas a ofrecer tus servicios?',
      'Elige la opción que mejor te describa. Podrás ajustarlo después.',
      'hammer'
    ),
    'basic': ('Cuéntanos quién eres', 'Quien busque un servicio querrá saber con quién trata.', 'user'),
    'services': ('¿Qué servicios ofreces?', 'Así te encontrarán quienes buscan justo eso.', 'hammer'),
    'zones': ('¿Dónde atiendes?', 'Verás solicitudes dentro de tu zona y aparecerás cuando alguien busque ahí.', 'pin'),
    'ready': ('Tu perfil está listo', 'Revisa y publícalo. Lo demás lo puedes completar después.', 'check'),
  };

  @override
  Widget build(BuildContext context) {
    if (_done) {
      final first = _name.text.trim().split(' ').first;
      return DoneView(
        title: 'Listo, $first. Ya apareces en Nexo',
        message: 'Tu perfil ya se puede encontrar. Completa horario y precios para aparecer primero.',
        extra: const [
          OneNote(icon: 'search', text: 'Con esta misma cuenta puedes cambiar a Modo Cliente desde Cuenta.'),
        ],
        footer: [
          NexoButton(
            label: 'Completar horario y precios',
            onPressed: () {
              final id = ref.read(myProviderProvider).asData?.value?.profile.id ?? 'me';
              context.go(Routes.home);
              context.push(Routes.provider(id));
            },
          ),
          const SizedBox(height: 8),
          NexoButton(
              label: 'Ver oportunidades', variant: NexoButtonVariant.ghost, onPressed: () => context.go(Routes.home)),
        ],
      );
    }
    final t = _titles[_step]!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: ObScaffold(
        icon: t.$3,
        title: t.$1,
        subtitle: t.$2,
        progress: (_i + 1) / _steps.length,
        stepLabel: 'Tu perfil · paso ${_i + 1} de ${_steps.length}',
        onBack: _back,
        onClose: _leave,
        content: _content(),
        footer: [
          NexoButton(
            label: _step == 'ready' ? 'Publicar mi perfil' : 'Continuar',
            loading: _busy,
            onPressed: _valid ? _next : null,
          ),
        ],
      ),
    );
  }
}
