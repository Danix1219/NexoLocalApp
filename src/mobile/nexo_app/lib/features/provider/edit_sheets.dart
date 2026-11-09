import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../core/widgets/nexo_button.dart';
import '../../core/widgets/nexo_field.dart';
import '../../core/widgets/nexo_sheet.dart';
import '../../core/widgets/pick_image.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/ui.dart';
import '../../data/api_provider.dart';
import '../../data/models.dart';
import '../account/phone_sheet.dart';
import '../location/location_picker_page.dart';

/// Guarda una sección del perfil (`PATCH /providers/me/{seccion}`).
Future<bool> _patch(WidgetRef ref, String section, Json body) async {
  try {
    await ref.read(apiProvider).patchProvider(section, body);
    ref.invalidate(myProviderProvider);
    ref.invalidate(providerProfileProvider);
    ref.invalidate(accountProvider);
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
    case 'bio':
      return showBasicSheet(context, ref, p);
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
  final ok = await confirmSheet(context,
      title: '¿Borrar este trabajo?',
      subtitle: '«${w.title}» dejará de verse en tu perfil y en el inicio.',
      confirmLabel: 'Borrar trabajo');
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
  late final _bio = TextEditingController(text: widget.p.bio);
  String? _photo;
  String? _photoId;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final img = await pickOneImage(context);
    if (img == null) return;
    setState(() => _busy = true);
    try {
      _photoId = await ref.read(apiProvider).upload(img, purpose: 'avatar');
      setState(() => _photo = 'file://${img.path}');
    } catch (e) {
      showNexoToast(apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetHeader('Tu perfil', subtitle: 'Así te verán quienes busquen un servicio.'),
        InkWell(
          onTap: _busy ? null : _pick,
          borderRadius: BorderRadius.circular(16),
          child: Row(children: [
            NexoAvatar(name: widget.p.name, url: _photo ?? widget.p.photoUrl, size: 72, icon: _photo == null && widget.p.photoUrl == null ? 'camera' : null),
            const SizedBox(width: 14),
            Expanded(
              child: Text(widget.p.photoUrl == null && _photo == null ? 'Agregar foto o logotipo' : 'Cambiar foto',
                  style: NexoText.body(15, weight: FontWeight.w700, color: NexoColors.brand)),
            ),
            if (_busy) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          ]),
        ),
        const SizedBox(height: 12),
        NexoField(label: widget.p.isBusiness ? 'Nombre comercial' : 'Tu nombre', controller: _name, maxLength: 80),
        _lbl('Acerca de ti'),
        TextField(
          controller: _bio,
          maxLines: 4,
          maxLength: 500,
          style: NexoText.body(15),
          decoration: nexoInputDecoration(hint: 'Qué haces, cómo trabajas y desde cuándo.'),
        ),
        const SizedBox(height: 8),
        NexoButton(
          label: 'Guardar',
          loading: _busy,
          onPressed: () async {
            setState(() => _busy = true);
            final nav = Navigator.of(context);
            final ok = await _patch(ref, 'basic', {
              'name': _name.text.trim(),
              'bio': _bio.text.trim(),
              if (_photoId != null) 'photoUploadId': _photoId,
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
  late final Set<String> _specs = widget.p.specialties.toSet();
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetHeader('Servicios que ofreces', subtitle: 'Elige hasta 3 categorías y tus especialidades.'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final c in allCats)
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
        ]),
        for (final c in allCats.where((c) => _cats.contains(c.id) && c.specs.isNotEmpty)) ...[
          _lbl('Especialidades en ${c.name.toLowerCase()}'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final s in c.specs)
              ToggleChip(
                label: s,
                selected: _specs.contains(s),
                onTap: () => setState(() => _specs.contains(s) ? _specs.remove(s) : _specs.add(s)),
              ),
          ]),
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
                  final ok = await _patch(ref, 'services', {'categories': _cats.toList(), 'specialties': _specs.toList()});
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
      initial: p.shopLocation ?? p.zonePoint ?? ref.read(searchLocationProvider).point,
      radiusKm: p.radiusKm == 0 ? 5 : p.radiusKm,
      showRadius: !shop,
      button: 'Guardar zona',
    ),
  );
  if (r == null) return;
  await _patch(ref, 'zone', {'location': r.point.toJson(), 'radiusKm': shop ? 0 : r.radiusKm, 'attention': p.attention});
}

// ----------------------------------------------------------------- horario

const _days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
const _dayFull = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

Future<void> showHoursSheet(BuildContext context, WidgetRef ref, ProviderProfile p) =>
    showNexoSheet<void>(context, builder: (_) => _HoursSheet(p: p));

class _HoursSheet extends ConsumerStatefulWidget {
  const _HoursSheet({required this.p});
  final ProviderProfile p;
  @override
  ConsumerState<_HoursSheet> createState() => _HoursSheetState();
}

class _HoursSheetState extends ConsumerState<_HoursSheet> {
  late final List<(int, int)?> _d = List.generate(7, (i) {
    final x = i < widget.p.days.length ? widget.p.days[i] : null;
    if (x == null) return widget.p.days.every((e) => e == null) && i < 6 ? (9, 18) : null;
    return (int.tryParse(x.open.split(':').first) ?? 9, int.tryParse(x.close.split(':').first) ?? 18);
  });
  late bool _urgent = widget.p.urgent;
  bool _busy = false;

  Widget _hour(int v, ValueChanged<int> on, {required int min, required int max}) => DropdownButton<int>(
        value: v.clamp(min, max),
        underline: const SizedBox.shrink(),
        borderRadius: BorderRadius.circular(12),
        style: NexoText.body(14.5, weight: FontWeight.w700),
        items: [for (var h = min; h <= max; h++) DropdownMenuItem(value: h, child: Text('$h:00'))],
        onChanged: (x) {
          if (x != null) on(x);
        },
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetHeader('Horario de atención', subtitle: 'Toca un día para abrirlo o cerrarlo.'),
        Row(children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Semantics(
                  button: true,
                  selected: _d[i] != null,
                  label: _dayFull[i],
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _d[i] = _d[i] == null ? (9, 18) : null),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: _d[i] != null ? NexoColors.brand : NexoColors.surface2,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(_days[i],
                          style: NexoText.body(15,
                              weight: FontWeight.w800, color: _d[i] != null ? Colors.white : NexoColors.muted)),
                    ),
                  ),
                ),
              ),
            ),
        ]),
        const SizedBox(height: 12),
        for (var i = 0; i < 7; i++)
          if (_d[i] != null)
            Row(children: [
              SizedBox(width: 92, child: Text(_dayFull[i], style: NexoText.body(14, weight: FontWeight.w600))),
              _hour(_d[i]!.$1, (v) => setState(() => _d[i] = (v, _d[i]!.$2 <= v ? v + 1 : _d[i]!.$2)), min: 5, max: 22),
              Text('  a  ', style: NexoText.body(14, color: NexoColors.muted)),
              _hour(_d[i]!.$2, (v) => setState(() => _d[i] = (_d[i]!.$1 >= v ? v - 1 : _d[i]!.$1, v)), min: 6, max: 23),
            ]),
        const SizedBox(height: 8),
        OptRow(
          icon: _urgent ? 'check' : 'bolt',
          label: 'Atiendo urgencias fuera de horario',
          selected: _urgent,
          onTap: () => setState(() => _urgent = !_urgent),
        ),
        const SizedBox(height: 14),
        NexoButton(
          label: 'Guardar horario',
          loading: _busy,
          onPressed: () async {
            setState(() => _busy = true);
            final nav = Navigator.of(context);
            String hh(int h) => '${h.toString().padLeft(2, '0')}:00';
            final ok = await _patch(ref, 'hours', {
              'schedule': {
                'days': [for (final d in _d) d == null ? null : {'open': hh(d.$1), 'close': hh(d.$2)}],
                'urgent': _urgent,
              }
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

// ----------------------------------------------------------------- precios

Future<void> showPricesSheet(BuildContext context, WidgetRef ref, ProviderProfile p) =>
    showNexoSheet<void>(context, builder: (_) => _PricesSheet(p: p));

class _PriceRow {
  _PriceRow(String s, int? pesos, this.suffix)
      : service = TextEditingController(text: s),
        amount = TextEditingController(text: pesos == null ? '' : '$pesos'),
        quote = pesos == null && s.isNotEmpty;
  final TextEditingController service;
  final TextEditingController amount;
  final String suffix;
  bool quote;
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
      text: widget.p.visitMode == 'paid' ? (widget.p.visitText ?? '').replaceAll(RegExp(r'[^0-9]'), '') : '');
  late final List<_PriceRow> _rows = [
    for (final x in widget.p.prices.take(3)) _PriceRow(x.service, x.fromCents == null ? null : x.fromCents! ~/ 100, x.suffix),
    if (widget.p.prices.isEmpty) _PriceRow('', null, ''),
  ];
  bool _busy = false;

  @override
  void dispose() {
    _visitAmt.dispose();
    for (final r in _rows) {
      r.service.dispose();
      r.amount.dispose();
    }
    super.dispose();
  }

  InputDecoration _dec(String hint) => nexoInputDecoration(hint: hint);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetHeader('¿Cuánto cobras?',
            subtitle: 'Precios de referencia. Ayudan a que te elijan; el precio final lo acuerdas con cada cliente.'),
        _lbl('Visita o diagnóstico'),
        SegControl<String>(
          small: true,
          options: const [('hidden', 'No mostrar'), ('free', 'Sin costo'), ('paid', 'Con costo')],
          value: _visit,
          onChanged: (v) => setState(() => _visit = v),
        ),
        if (_visit == 'paid') ...[
          const SizedBox(height: 8),
          TextField(
            controller: _visitAmt,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: NexoText.body(15),
            decoration: _dec('Costo de la visita').copyWith(prefixText: '\$ '),
          ),
        ],
        _lbl('Servicios y precios (hasta 3)'),
        for (final r in _rows) ...[
          TextField(controller: r.service, maxLength: 60, style: NexoText.body(15), decoration: _dec('Ej. Reparación de fuga')),
          Row(children: [
            Expanded(
              child: TextField(
                controller: r.amount,
                enabled: !r.quote,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: NexoText.body(15),
                decoration: _dec(r.quote ? 'A cotizar' : 'Desde').copyWith(prefixText: r.quote ? null : '\$ '),
              ),
            ),
            const SizedBox(width: 8),
            ToggleChip(label: 'A cotizar', selected: r.quote, onTap: () => setState(() => r.quote = !r.quote)),
          ]),
          const SizedBox(height: 12),
        ],
        if (_rows.length < 3)
          NexoButton(
            label: 'Agregar otro servicio',
            icon: 'plus',
            variant: NexoButtonVariant.ghost,
            onPressed: () => setState(() => _rows.add(_PriceRow('', null, ''))),
          ),
        const SizedBox(height: 12),
        NexoButton(
          label: 'Guardar precios',
          loading: _busy,
          onPressed: () async {
            setState(() => _busy = true);
            final nav = Navigator.of(context);
            final prices = [
              for (final r in _rows)
                if (r.service.text.trim().isNotEmpty)
                  {
                    'service': r.service.text.trim(),
                    'fromCents': r.quote ? null : (int.tryParse(r.amount.text) ?? 0) * 100,
                    'unit': r.quote ? 'quote' : 'from',
                    'suffix': r.suffix,
                  }
            ];
            final ok = await _patch(ref, 'prices', {
              'visit': {
                'mode': _visit,
                if (_visit == 'paid') 'amountCents': (int.tryParse(_visitAmt.text) ?? 0) * 100,
              },
              'prices': prices,
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

// ------------------------------------------------------------ condiciones

Future<void> showTermsEditSheet(BuildContext context, WidgetRef ref, ProviderProfile p) =>
    showNexoSheet<void>(context, builder: (_) => _TermsSheet(p: p));

class _TermsSheet extends ConsumerStatefulWidget {
  const _TermsSheet({required this.p});
  final ProviderProfile p;
  @override
  ConsumerState<_TermsSheet> createState() => _TermsSheetState();
}

class _TermsSheetState extends ConsumerState<_TermsSheet> {
  static const _payNames = {'cash': 'Efectivo', 'transfer': 'Transferencia', 'card': 'Tarjeta'};
  static const _resp = [('sameDay', 'Mismo día'), ('h24', '24 h'), ('h48', '48 h'), ('week', 'Semana')];

  late final Set<String> _pay = {
    for (final e in _payNames.entries)
      if (widget.p.payment.contains(e.value)) e.key
  };
  late String _response = switch (widget.p.responseTime) {
    'Mismo día' || 'Menos de 1 hora' || 'Menos de 30 minutos' => 'sameDay',
    'Menos de 2 días' => 'h48',
    'Esta semana' => 'week',
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetHeader('Condiciones', subtitle: 'Lo que el cliente quiere saber antes de escribirte.'),
        _lbl('Formas de pago'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final e in _payNames.entries)
            ToggleChip(
              label: e.value,
              selected: _pay.contains(e.key),
              onTap: () => setState(() => _pay.contains(e.key) ? _pay.remove(e.key) : _pay.add(e.key)),
            ),
        ]),
        _lbl('Respondes en'),
        SegControl<String>(small: true, options: _resp, value: _response, onChanged: (v) => setState(() => _response = v)),
        _lbl('Garantía'),
        TextField(
          controller: _warranty,
          maxLength: 80,
          style: NexoText.body(15),
          decoration: nexoInputDecoration(hint: 'Ej. 30 días en mano de obra'),
        ),
        OptRow(
            icon: _invoice ? 'check' : 'info',
            label: 'Emito factura',
            selected: _invoice,
            onTap: () => setState(() => _invoice = !_invoice)),
        const SizedBox(height: 8),
        OptRow(
            icon: _call ? 'check' : 'phone',
            label: 'Mostrar mi número para llamadas',
            selected: _call,
            onTap: () => setState(() => _call = !_call)),
        const SizedBox(height: 14),
        NexoButton(
          label: 'Guardar',
          loading: _busy,
          onPressed: () async {
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
          },
        ),
      ],
    );
  }
}
