import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../core/widgets/nexo_button.dart';
import '../../core/widgets/nexo_field.dart';
import '../../core/widgets/nexo_icon.dart';
import '../../core/widgets/nexo_motion.dart';
import '../../core/widgets/nexo_sheet.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/ui.dart';
import '../../core/widgets/photo_feedback.dart';
import '../../data/api_provider.dart';
import '../../core/widgets/catalog_status.dart';
import '../../data/models.dart';
import '../../core/widgets/pick_image.dart';
import '../../data/provider_contract.dart';
import '../account/phone_sheet.dart';
import '../location/location_picker_page.dart';
import 'hours_sheet.dart';

/// Guarda una sección del perfil (`PATCH /providers/me/{seccion}`).
Future<bool> _patch(WidgetRef ref, String section, Json body) async {
  try {
    await ref.read(apiProvider).patchProvider(section, body);
    ref.invalidate(myProviderProvider);
    ref.invalidate(providerProfileProvider);
    ref.invalidate(accountProvider);
    ref.invalidate(compareResultProvider);
    showNexoToast('Perfil actualizado');
    return true;
  } catch (e) {
    showNexoToast(apiErrorMessage(e));
    return false;
  }
}

Widget _lbl(String t) => Padding(
  padding: const EdgeInsets.only(top: 14, bottom: 8),
  child: Text(t, style: NexoText.body(14, weight: FontWeight.w800)),
);

/// Atajos de "Completa tu perfil".
Future<void> openTodo(BuildContext context, WidgetRef ref, String key, MyProvider me) async {
  final p = me.profile;
  switch (key) {
    case 'photo':
      return showBasicSheet(context, ref, p);
    case 'cover':
      return showBasicSheet(context, ref, p);
    case 'bio':
      return showServicesSheet(context, ref, p);
    case 'schedule':
    case 'hours':
      return showHoursSheet(context, ref, p);
    case 'prices':
      return showPricesSheet(context, ref, p);
    case 'terms':
      return showTermsEditSheet(context, ref, p);
    case 'phone':
      await showPhoneSheet(context, ref);
      ref.invalidate(myProviderProvider);
      return;
    case 'works':
      context.go(Routes.publish);
      return;
    default:
      return showBasicSheet(context, ref, p);
  }
}

Future<void> deleteWork(BuildContext context, WidgetRef ref, Work w, String providerId) async {
  final ok = await confirmSheet(
    context,
    title: '¿Borrar este trabajo?',
    subtitle: '«${w.title}» dejará de verse en tu perfil y en el inicio.',
    confirmLabel: 'Borrar trabajo',
  );
  if (ok != true) return;
  try {
    await ref.read(apiProvider).deleteWork(w.id);
    ref.invalidate(providerWorksProvider(providerId));
    ref.invalidate(feedProvider);
    ref.invalidate(myProviderProvider);
    showNexoToast('Trabajo borrado');
  } catch (e) {
    showNexoToast(apiErrorMessage(e));
  }
}

// ------------------------------------------------------------------ básico

Future<void> showBasicSheet(BuildContext context, WidgetRef ref, ProviderProfile p) =>
    showNexoSheet<void>(context, builder: (_) => _BasicSheet(p: p));

class _BasicSheet extends ConsumerStatefulWidget {
  const _BasicSheet({required this.p});
  final ProviderProfile p;
  @override
  ConsumerState<_BasicSheet> createState() => _BasicSheetState();
}

class _BasicSheetState extends ConsumerState<_BasicSheet> {
  late final _name = TextEditingController(text: widget.p.name);
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String? _photoLocal;
  String? _coverLocal;
  String? _pendingPhoto;
  bool _loadingCover = false;
  Future<void> _pick({bool cover = false}) async {
    final image = await pickOneImage(context);
    if (image == null || !mounted) return;
    setState(() {
      _busy = true;
      _loadingCover = cover;
      _pendingPhoto = 'file://${image.path}';
    });
    try {
      final id = await ref.read(apiProvider).upload(image, purpose: cover ? 'cover' : 'avatar');
      final ok = await _patch(ref, 'basic', {cover ? 'coverUploadId' : 'photoUploadId': id});
      if (ok && mounted) {
        setState(() {
          if (cover) {
            _coverLocal = 'file://${image.path}';
          } else {
            _photoLocal = 'file://${image.path}';
          }
        });
      }
      if (ok) showNexoToast(cover ? 'Portada actualizada' : 'Foto actualizada');
    } catch (e) {
      showNexoToast(apiErrorMessage(e));
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _pendingPhoto = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetHeader('Tu perfil', subtitle: 'Así te verán quienes busquen un servicio.'),
        SizedBox(
          height: 110,
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _busy && _loadingCover && _pendingPhoto != null
                      ? NexoImage(_pendingPhoto!)
                      : (_coverLocal ?? widget.p.coverUrl) != null
                      ? NexoImage((_coverLocal ?? widget.p.coverUrl)!)
                      : const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [NexoColors.brandSoft, NexoColors.accentSoft]),
                          ),
                        ),
                ),
              ),
              if (_busy && _loadingCover) const Positioned.fill(child: PhotoProcessingOverlay()),
              Positioned(
                right: 8,
                bottom: 4,
                child: TextButton.icon(
                  onPressed: _busy ? null : () => _pick(cover: true),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text(widget.p.coverUrl == null && _coverLocal == null ? 'Agregar portada' : 'Cambiar portada'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _busy ? null : () => _pick(),
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  children: [
                    NexoAvatar(
                      name: widget.p.name,
                      url: _busy && !_loadingCover ? _pendingPhoto : _photoLocal ?? widget.p.photoUrl,
                      size: 72,
                      icon: widget.p.photoUrl == null ? 'camera' : null,
                    ),
                    if (_busy && !_loadingCover) const Positioned.fill(child: PhotoProcessingOverlay(circular: true)),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.p.photoUrl == null ? 'Agregar foto o logotipo' : 'Cambiar foto',
                  style: NexoText.body(15, weight: FontWeight.w700, color: NexoColors.brand),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        NexoField(label: widget.p.isBusiness ? 'Nombre comercial' : 'Tu nombre', controller: _name, maxLength: 80),
        const SizedBox(height: 8),
        NexoButton(
          label: 'Guardar',
          loading: _busy,
          onPressed: () async {
            setState(() => _busy = true);
            final nav = Navigator.of(context);
            final ok = await _patch(ref, 'basic', {'name': _name.text.trim()});
            if (ok) {
              nav.pop();
            } else if (mounted) {
              setState(() => _busy = false);
            }
          },
        ),
      ],
    );
  }
}

// --------------------------------------------------------------- servicios

Future<void> showServicesSheet(BuildContext context, WidgetRef ref, ProviderProfile p) =>
    showNexoSheet<void>(context, builder: (_) => _ServicesSheet(p: p));

class _ServicesSheet extends ConsumerStatefulWidget {
  const _ServicesSheet({required this.p});
  final ProviderProfile p;
  @override
  ConsumerState<_ServicesSheet> createState() => _ServicesSheetState();
}

class _ServicesSheetState extends ConsumerState<_ServicesSheet> {
  late final Set<String> _cats = widget.p.categories.toSet();
  late final Set<String> _specs = widget.p.specialties
      .map((s) => providerSpecialtyLabel(widget.p.categories, s))
      .toSet();
  late final _bio = TextEditingController(text: widget.p.bio);
  late final _activity = TextEditingController(text: widget.p.activity ?? '');
  @override
  void dispose() {
    _bio.dispose();
    _activity.dispose();
    super.dispose();
  }

  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetHeader('Servicios que ofreces', subtitle: 'Elige hasta 3 categorías y tus especialidades.'),
        NexoField(label: 'Descripción (mínimo 20 caracteres)', controller: _bio, maxLength: 600),
        if (widget.p.isBusiness) NexoField(label: 'Actividad del negocio', controller: _activity, maxLength: 80),
        if (widget.p.isBusiness)
          Text('Las categorías se calculan a partir de tu actividad y descripción.', style: NexoText.body(14)),
        if (!widget.p.isBusiness) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              const CatalogStatus(),
              for (final c in (ref.watch(catalogProvider).asData?.value ?? []))
                ToggleChip(
                  label: c.name,
                  icon: c.icon,
                  selected: _cats.contains(c.id),
                  onTap: () => setState(() {
                    if (_cats.contains(c.id)) {
                      _cats.remove(c.id);
                      _specs.removeAll(c.specs);
                    } else if (_cats.length < 3) {
                      _cats.add(c.id);
                    } else {
                      showNexoToast('Máximo 3 categorías');
                    }
                  }),
                ),
            ],
          ),
          for (final c in (ref.watch(catalogProvider).asData?.value ?? []).where(
            (c) => _cats.contains(c.id) && c.specs.isNotEmpty,
          )) ...[
            _lbl('Especialidades en ${c.name.toLowerCase()}'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in c.specs)
                  ToggleChip(
                    label: s,
                    selected: _specs.contains(s),
                    onTap: () => setState(() {
                      if (_specs.contains(s)) {
                        _specs.remove(s);
                      } else if (_specs.length < 5) {
                        _specs.add(s);
                      } else {
                        showNexoToast('Máximo 5 especialidades');
                      }
                    }),
                  ),
              ],
            ),
          ],
        ],
        const SizedBox(height: 18),
        NexoButton(
          label: 'Guardar',
          loading: _busy,
          onPressed: _cats.isEmpty
              ? null
              : () async {
                  setState(() => _busy = true);
                  final nav = Navigator.of(context);
                  final ok = await _patch(ref, 'services', {
                    'bio': _bio.text.trim(),
                    if (widget.p.isBusiness) 'activity': _activity.text.trim(),
                    if (!widget.p.isBusiness) 'categories': _cats.toList(),
                    'specialties': widget.p.isBusiness
                        ? <String>[]
                        : providerSpecialtySlugs(_cats.toList(), _specs.toList()),
                  });
                  if (ok) {
                    nav.pop();
                  } else if (mounted) {
                    setState(() => _busy = false);
                  }
                },
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------- zona

Future<void> showZoneSheet(BuildContext context, WidgetRef ref, ProviderProfile p) async {
  final shop = p.attention == 'shop';
  final r = await context.push<LocationPick>(
    Routes.location,
    extra: LocationPickerArgs(
      title: shop ? 'Tu local' : 'Tu zona de atención',
      subtitle: shop
          ? 'Mueve el mapa hasta la entrada de tu local. Los clientes verán cómo llegar.'
          : 'Mueve el punto base y elige hasta dónde llegas. Verás solicitudes dentro de ese radio.',
      initial:
          ref.read(myProviderProvider).asData?.value?.location ??
          p.shopLocation ??
          ref.read(searchLocationProvider).point,
      radiusKm: p.radiusKm == 0 ? 5 : p.radiusKm,
      showRadius: !shop,
      button: 'Guardar zona',
    ),
  );
  if (r == null) return;
  try {
    await ref
        .read(searchLocationProvider.notifier)
        .set(r.point, r.radiusKm == 0 ? 5 : r.radiusKm, source: r.source, zoneLabel: r.zoneLabel);
  } catch (e) {
    showNexoToast(apiErrorMessage(e));
    return;
  }
  await _patch(ref, 'zone', {
    'location': r.point.toJson(),
    'radiusKm': shop ? 0 : r.radiusKm,
    'attention': p.attention,
  });
}

// ----------------------------------------------------------------- horario

Future<void> showHoursSheet(BuildContext context, WidgetRef ref, ProviderProfile p) {
  // Sin horario guardado se propone lunes a sábado de 9 a 18.
  final empty = p.days.every((e) => e == null);
  final days = List<DayRange?>.generate(7, (i) {
    final x = i < p.days.length ? p.days[i] : null;
    if (x == null) return empty && i < 6 ? (9, 18) : null;
    return (int.tryParse(x.open.split(':').first) ?? 9, int.tryParse(x.close.split(':').first) ?? 18);
  });
  String hh(int h) => '${h.toString().padLeft(2, '0')}:00';
  return showNexoSheet<void>(
    context,
    builder: (sheet) => HoursEditor(
      initialDays: days,
      initialUrgent: p.urgent,
      onSave: (days, urgent) async {
        final nav = Navigator.of(sheet);
        final ok = await _patch(ref, 'hours', {
          'schedule': {
            'days': [
              for (final d in days) d == null ? null : {'open': hh(d.$1), 'close': hh(d.$2)},
            ],
            'urgent': urgent,
          },
        });
        if (ok) nav.pop();
        return ok;
      },
    ),
  );
}

// ----------------------------------------------------------------- precios

Future<void> showPricesSheet(BuildContext context, WidgetRef ref, ProviderProfile p) =>
    showNexoSheet<void>(context, builder: (_) => _PricesSheet(p: p));

/// Encabezado de un bloque de hoja, con una nota breve a la derecha.
Widget _blockLabel(String title, [String? note]) => Padding(
  padding: const EdgeInsets.only(top: 16, bottom: 8),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Text(title, style: NexoText.body(14, weight: FontWeight.w800)),
      ),
      if (note != null)
        Text(
          note,
          style: NexoText.body(12.5, weight: FontWeight.w600, color: NexoColors.muted),
        ),
    ],
  ),
);

/// Explica cómo quedará lo elegido en el perfil.
Widget _caption(String text) => Padding(
  padding: const EdgeInsets.only(top: 7, left: 2),
  child: Text(text, style: NexoText.body(12.5, color: NexoColors.muted, height: 1.35)),
);

/// Filas relacionadas dentro de un mismo contorno (igual que el horario).
Widget _group(List<Widget> rows) => Material(
  color: NexoColors.surface,
  clipBehavior: Clip.antiAlias,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(18),
    side: const BorderSide(color: NexoColors.line),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < rows.length; i++) ...[if (i > 0) const Divider(height: 1, color: NexoColors.line), rows[i]],
    ],
  ),
);

InputDecoration _moneyDecoration(String hint, {String? error, bool money = true}) =>
    nexoInputDecoration(hint: hint).copyWith(
      errorText: error,
      errorMaxLines: 2,
      // El signo queda visible siempre, no solo al escribir.
      prefixIcon: money
          ? Padding(
              padding: const EdgeInsets.only(left: 14, right: 6),
              child: Text(
                '\$',
                style: NexoText.body(15, weight: FontWeight.w800, color: NexoColors.muted),
              ),
            )
          : null,
      prefixIconConstraints: const BoxConstraints(),
    );

final _moneyInput = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];
const _moneyKeyboard = TextInputType.numberWithOptions(decimal: true);

class _PriceRow {
  _PriceRow(String s, int? cents, this.suffix)
    : service = TextEditingController(text: s),
      amount = TextEditingController(text: cents == null ? '' : centsInput(cents)),
      quote = cents == null && s.isNotEmpty;
  final TextEditingController service;
  final TextEditingController amount;
  final String suffix;
  final key = GlobalKey();
  bool quote;
  String? serviceError;
  String? amountError;

  bool get untouched => service.text.trim().isEmpty && amount.text.trim().isEmpty && !quote;

  void dispose() {
    service.dispose();
    amount.dispose();
  }
}

class _PricesSheet extends ConsumerStatefulWidget {
  const _PricesSheet({required this.p});
  final ProviderProfile p;
  @override
  ConsumerState<_PricesSheet> createState() => _PricesSheetState();
}

class _PricesSheetState extends ConsumerState<_PricesSheet> {
  late String _visit = widget.p.visitMode;
  late final _visitAmt = TextEditingController(
    text: widget.p.visitAmountCents == null ? '' : centsInput(widget.p.visitAmountCents!),
  );
  late final List<_PriceRow> _rows = [
    for (final x in widget.p.prices.take(3)) _PriceRow(x.service, x.fromCents, x.suffix),
    if (widget.p.prices.isEmpty) _PriceRow('', null, ''),
  ];
  final _visitKey = GlobalKey();
  String? _visitError;
  bool _busy = false;

  @override
  void dispose() {
    _visitAmt.dispose();
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  void _remove(_PriceRow row) {
    setState(() {
      _rows.remove(row);
      if (_rows.isEmpty) _rows.add(_PriceRow('', null, ''));
    });
    // El campo sigue montado hasta el siguiente cuadro.
    WidgetsBinding.instance.addPostFrameCallback((_) => row.dispose());
  }

  /// Marca cada error junto a su campo y devuelve el primero que haya.
  GlobalKey? _validate() {
    GlobalKey? first;
    _visitError = _visit == 'paid' && parseProviderMoney(_visitAmt.text) == null
        ? 'Escribe el costo, por ejemplo 150 o 150.50.'
        : null;
    if (_visitError != null) first = _visitKey;
    for (final r in _rows) {
      final named = r.service.text.trim().isNotEmpty;
      r.serviceError = !named && !r.untouched ? 'Escribe qué servicio es.' : null;
      r.amountError = named && !r.quote && parseProviderMoney(r.amount.text) == null
          ? 'Escribe el precio o elige «A cotizar».'
          : null;
      if (r.serviceError != null || r.amountError != null) first ??= r.key;
    }
    return first;
  }

  Future<void> _save() async {
    GlobalKey? invalid;
    setState(() => invalid = _validate());
    if (invalid != null) {
      await WidgetsBinding.instance.endOfFrame;
      final target = invalid!.currentContext;
      if (target != null && target.mounted) {
        await Scrollable.ensureVisible(target, alignment: .2, duration: const Duration(milliseconds: 250));
      }
      return;
    }
    setState(() => _busy = true);
    final nav = Navigator.of(context);
    final prices = [
      for (final r in _rows)
        if (r.service.text.trim().isNotEmpty)
          {
            'service': r.service.text.trim(),
            'fromCents': r.quote ? null : parseProviderMoney(r.amount.text)!,
            'unit': r.quote ? 'quote' : 'from',
            'suffix': r.suffix,
          },
    ];
    final ok = await _patch(ref, 'prices', {
      'visit': {'mode': _visit, if (_visit == 'paid') 'amountCents': parseProviderMoney(_visitAmt.text)!},
      'prices': prices,
    });
    if (ok) {
      nav.pop();
    } else if (mounted) {
      setState(() => _busy = false);
    }
  }

  Widget _serviceRow(_PriceRow r, int index) {
    final removable = _rows.length > 1 || !r.untouched;
    return Padding(
      key: r.key,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: ValueKey('price-service-$index'),
            controller: r.service,
            maxLength: 60,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            style: NexoText.body(15, weight: FontWeight.w700),
            onChanged: (_) => setState(() => r.serviceError = null),
            decoration: nexoInputDecoration(
              hint: 'Ej. Reparación de fuga',
              suffix: removable
                  ? IconButton(
                      tooltip: 'Quitar servicio ${index + 1}',
                      onPressed: _busy ? null : () => _remove(r),
                      icon: const NexoIcon('close', size: 16, color: NexoColors.muted),
                    )
                  : null,
            ).copyWith(errorText: r.serviceError),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  key: ValueKey('price-amount-$index'),
                  controller: r.amount,
                  enabled: !r.quote,
                  keyboardType: _moneyKeyboard,
                  inputFormatters: _moneyInput,
                  style: NexoText.body(15, color: r.quote ? NexoColors.muted : NexoColors.ink),
                  onChanged: (_) => setState(() => r.amountError = null),
                  decoration: _moneyDecoration(
                    r.quote ? 'Sin precio fijo' : 'Precio desde',
                    error: r.amountError,
                    money: !r.quote,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ToggleChip(
                  label: 'A cotizar',
                  selected: r.quote,
                  onTap: () => setState(() {
                    r.quote = !r.quote;
                    r.amountError = null;
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final named = _rows.where((r) => r.service.text.trim().isNotEmpty).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetHeader(
          '¿Cuánto cobras?',
          subtitle: 'Precios de referencia. Ayudan a que te elijan; el precio final lo acuerdas con cada cliente.',
        ),
        _blockLabel('Visita o diagnóstico'),
        SegControl<String>(
          small: true,
          options: const [('hidden', 'No mostrar'), ('free', 'Sin costo'), ('paid', 'Con costo')],
          value: _visit,
          onChanged: (v) => setState(() {
            _visit = v;
            _visitError = null;
          }),
        ),
        AnimatedSize(
          duration: NexoMotion.duration(context, NexoMotion.enter),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _visit == 'paid'
              ? Padding(
                  key: _visitKey,
                  padding: const EdgeInsets.only(top: 8),
                  child: TextField(
                    key: const ValueKey('price-visit'),
                    controller: _visitAmt,
                    keyboardType: _moneyKeyboard,
                    inputFormatters: _moneyInput,
                    style: NexoText.body(15),
                    onChanged: (_) => setState(() => _visitError = null),
                    decoration: _moneyDecoration('Costo de la visita', error: _visitError),
                  ),
                )
              : _caption(
                  _visit == 'free'
                      ? 'En tu perfil dirá que la visita es sin costo.'
                      : 'Tu perfil no mostrará el costo de la visita.',
                ),
        ),
        _blockLabel('Tus servicios', '$named de 3'),
        _group([
          for (var i = 0; i < _rows.length; i++) _serviceRow(_rows[i], i),
          if (_rows.length < 3)
            InkWell(
              onTap: _busy ? null : () => setState(() => _rows.add(_PriceRow('', null, ''))),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const NexoIcon('plus', size: 18, color: NexoColors.brand),
                    const SizedBox(width: 8),
                    Text(
                      'Agregar otro servicio',
                      style: NexoText.body(14, weight: FontWeight.w800, color: NexoColors.brand),
                    ),
                  ],
                ),
              ),
            ),
        ]),
        _caption('Con precio, tu cliente lo verá como «Desde \$…».'),
        const SizedBox(height: 16),
        NexoButton(label: 'Guardar precios', tall: true, loading: _busy, onPressed: _save),
      ],
    );
  }
}

// ------------------------------------------------------------ condiciones

Future<void> showTermsEditSheet(BuildContext context, WidgetRef ref, ProviderProfile p) =>
    showNexoSheet<void>(context, builder: (_) => _TermsSheet(p: p));

/// Casilla de ancho fijo: al marcarla no se reacomodan las demás.
class _PayTile extends StatelessWidget {
  const _PayTile({required this.icon, required this.label, required this.selected, required this.onTap});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? NexoColors.brandDeep : NexoColors.ink;
    final radius = BorderRadius.circular(14);
    return Semantics(
      button: true,
      checked: selected,
      child: Material(
        color: selected ? NexoColors.brandSoft : NexoColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: selected ? NexoColors.brand : NexoColors.line, width: 1.5),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 50),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: selected ? NexoColors.brand : NexoColors.muted),
                  const SizedBox(width: 7),
                  Expanded(
                    // En pantallas angostas el nombre se ajusta sin partirse.
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        label,
                        style: NexoText.body(13.5, weight: FontWeight.w700, color: fg),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                    size: 19,
                    color: selected ? NexoColors.brand : NexoColors.line,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TermsSheet extends ConsumerStatefulWidget {
  const _TermsSheet({required this.p});
  final ProviderProfile p;
  @override
  ConsumerState<_TermsSheet> createState() => _TermsSheetState();
}

class _TermsSheetState extends ConsumerState<_TermsSheet> {
  static const _payNames = {
    'cash': ('Efectivo', Icons.payments_outlined),
    'transfer': ('Transferencia', Icons.swap_horiz_rounded),
    'card': ('Tarjeta', Icons.credit_card_rounded),
    'deposit': ('Depósito', Icons.account_balance_outlined),
    'other': ('Otro', Icons.more_horiz_rounded),
  };
  static const _resp = [('sameDay', 'Mismo día'), ('h24', '24 h'), ('h48', '48 h'), ('week', 'Semana')];

  late final Set<String> _pay = {
    for (final e in _payNames.entries)
      if (widget.p.payment.contains(e.key) || widget.p.payment.contains(e.value.$1)) e.key,
  };
  // Sin dato no se supone ninguno: solo se publica lo que el prestador elige.
  late String? _response = switch (widget.p.responseTime) {
    null || '' => null,
    'sameDay' || 'Mismo día' || 'Menos de 1 hora' || 'Menos de 30 minutos' => 'sameDay',
    'h48' || 'Menos de 2 días' => 'h48',
    'week' || 'Esta semana' => 'week',
    _ => 'h24',
  };
  late final _warranty = TextEditingController(text: widget.p.warranty ?? '');
  late bool _invoice = widget.p.invoice;
  late bool _call = widget.p.channelCall;
  bool _busy = false;

  @override
  void dispose() {
    _warranty.dispose();
    super.dispose();
  }

  Widget _switchRow(String icon, String title, String detail, bool value, ValueChanged<bool> onChanged) =>
      SwitchListTile(
        contentPadding: const EdgeInsets.fromLTRB(14, 4, 8, 4),
        secondary: NexoIcon(icon, size: 21, color: value ? NexoColors.brand : NexoColors.muted),
        title: Text(title, style: NexoText.body(14.5, weight: FontWeight.w800)),
        subtitle: Text(detail, style: NexoText.body(12.5, color: NexoColors.muted, height: 1.35)),
        activeTrackColor: NexoColors.brand,
        value: value,
        onChanged: _busy ? null : onChanged,
      );

  Future<void> _save() async {
    setState(() => _busy = true);
    final nav = Navigator.of(context);
    final ok = await _patch(ref, 'terms', {
      'payment': _pay.toList(),
      'responseTime': _response,
      'warranty': _warranty.text.trim().isEmpty ? null : _warranty.text.trim(),
      'invoice': _invoice,
      'channels': {'chat': true, 'call': _call},
    });
    if (ok) {
      nav.pop();
    } else if (mounted) {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetHeader('Condiciones', subtitle: 'Lo que el cliente quiere saber antes de escribirte.'),
        _blockLabel(
          'Formas de pago',
          _pay.isEmpty ? 'Elige las que aceptes' : '${_pay.length} ${plural(_pay.length, 'elegida', 'elegidas')}',
        ),
        LayoutBuilder(
          builder: (context, box) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in _payNames.entries)
                SizedBox(
                  width: (box.maxWidth - 8) / 2,
                  child: _PayTile(
                    icon: e.value.$2,
                    label: e.value.$1,
                    selected: _pay.contains(e.key),
                    onTap: () => setState(() => _pay.contains(e.key) ? _pay.remove(e.key) : _pay.add(e.key)),
                  ),
                ),
            ],
          ),
        ),
        _blockLabel('Respondes en', 'Opcional'),
        SegControl<String?>(
          small: true,
          options: _resp,
          value: _response,
          onChanged: (v) => setState(() => _response = _response == v ? null : v),
        ),
        _caption(
          _response == null
              ? 'Sin elegir, tu perfil no promete un tiempo de respuesta.'
              : 'En tu perfil: «Responde: ${responseTimeLabel(_response)}». Toca de nuevo para quitarlo.',
        ),
        _blockLabel('Garantía', 'Opcional'),
        TextField(
          controller: _warranty,
          maxLength: 80,
          textCapitalization: TextCapitalization.sentences,
          style: NexoText.body(15),
          decoration: nexoInputDecoration(hint: 'Ej. 30 días en mano de obra'),
        ),
        _blockLabel(widget.p.isBusiness ? 'Facturación y contacto' : 'Contacto'),
        ListTileTheme.merge(
          horizontalTitleGap: 10,
          minLeadingWidth: 22,
          child: _group([
            if (widget.p.isBusiness)
              _switchRow(
                'check',
                'Emito factura',
                _invoice ? 'Se indicará en tu perfil.' : 'Tu perfil indicará que no.',
                _invoice,
                (v) => setState(() => _invoice = v),
              ),
            _switchRow(
              'phone',
              'Mostrar mi número para llamadas',
              _call ? 'Al contactarte podrán elegir llamarte.' : 'Solo te escribirán por el chat de Nexo.',
              _call,
              (v) => setState(() => _call = v),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        NexoButton(label: 'Guardar', tall: true, loading: _busy, onPressed: _save),
      ],
    );
  }
}
