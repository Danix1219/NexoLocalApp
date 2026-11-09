import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../core/widgets/nexo_button.dart';
import '../../core/widgets/nexo_icon.dart';
import '../../core/widgets/nexo_sheet.dart';
import '../../core/widgets/ui.dart';
import '../../data/api_provider.dart';
import '../../data/models.dart';

/// `.filtbtn` con contador de filtros activos.
class FilterButton extends StatelessWidget {
  const FilterButton({super.key, required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: count > 0 ? 'Filtros, $count activos' : 'Filtros',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: NexoColors.surface2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: NexoColors.line),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onTap,
              child: const SizedBox(width: 48, height: 48, child: Center(child: NexoIcon('sliders', size: 21))),
            ),
          ),
          if (count > 0)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                constraints: const BoxConstraints(minWidth: 19),
                height: 19,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(color: NexoColors.brand, borderRadius: BorderRadius.circular(99)),
                child: Center(
                  child: Text('$count', style: NexoText.body(11, weight: FontWeight.w800, color: Colors.white, height: 1)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Widget _label(String t) => Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Text(t, style: NexoText.body(14, weight: FontWeight.w800)),
    );

/// `filterSheet` del solicitante.
Future<void> showSearchFiltersSheet(BuildContext context, WidgetRef ref) {
  return showNexoSheet<void>(context, builder: (_) => const _SearchFilters());
}

class _SearchFilters extends ConsumerStatefulWidget {
  const _SearchFilters();
  @override
  ConsumerState<_SearchFilters> createState() => _SearchFiltersState();
}

class _SearchFiltersState extends ConsumerState<_SearchFilters> {
  late SearchFilters f = ref.read(searchFiltersProvider);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetHeader('Filtros', subtitle: 'Ajusta qué prestadores ver en tu zona.'),
        _label('Servicio'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final c in allCats)
            ToggleChip(
              label: c.name,
              icon: c.icon,
              selected: f.cat == c.id,
              onTap: () => setState(() => f = f.copyWith(cat: f.cat == c.id ? null : c.id)),
            ),
        ]),
        _label('Disponibilidad y precio'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ToggleChip(label: 'Abierto ahora', selected: f.open, onTap: () => setState(() => f = f.copyWith(open: !f.open))),
          ToggleChip(label: 'Visita sin costo', selected: f.free, onTap: () => setState(() => f = f.copyWith(free: !f.free))),
          ToggleChip(
              label: 'Con precios publicados', selected: f.prices, onTap: () => setState(() => f = f.copyWith(prices: !f.prices))),
          ToggleChip(label: 'Atiende urgencias', selected: f.urgent, onTap: () => setState(() => f = f.copyWith(urgent: !f.urgent))),
        ]),
        _label('¿Dónde te atienden?'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ToggleChip(
              label: 'A domicilio',
              icon: 'home',
              selected: f.attention == 'home',
              onTap: () => setState(() => f = f.copyWith(attention: f.attention == 'home' ? null : 'home'))),
          ToggleChip(
              label: 'En su local',
              icon: 'pin',
              selected: f.attention == 'shop',
              onTap: () => setState(() => f = f.copyWith(attention: f.attention == 'shop' ? null : 'shop'))),
        ]),
        _label('Ordenar por'),
        SegControl<String>(
          small: true,
          options: const [('relevance', 'Relevancia'), ('near', 'Más cerca'), ('recs', 'Más recomendados')],
          value: f.sort,
          onChanged: (v) => setState(() => f = f.copyWith(sort: v)),
        ),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(
            child: NexoButton(
              label: 'Quitar filtros',
              variant: NexoButtonVariant.ghost,
              onPressed: () => setState(() => f = SearchFilters(q: f.q)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: NexoButton(
              label: 'Ver resultados',
              onPressed: () {
                ref.read(searchFiltersProvider.notifier).set(f);
                Navigator.of(context).pop();
              },
            ),
          ),
        ]),
      ],
    );
  }
}

/// Filtros del prestador sobre solicitudes (`RFL`).
Future<void> showOppFiltersSheet(BuildContext context, WidgetRef ref) {
  return showNexoSheet<void>(context, builder: (_) => const _OppFilters());
}

class _OppFilters extends ConsumerStatefulWidget {
  const _OppFilters();
  @override
  ConsumerState<_OppFilters> createState() => _OppFiltersState();
}

class _OppFiltersState extends ConsumerState<_OppFilters> {
  late OppFilters f = ref.read(oppFiltersProvider);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetHeader('Filtrar solicitudes'),
        OptRow(
            icon: f.inRadius ? 'check' : 'pin',
            label: 'Dentro de mi radio',
            selected: f.inRadius,
            onTap: () => setState(() => f = f.copyWith(inRadius: !f.inRadius))),
        const SizedBox(height: 8),
        OptRow(
            icon: f.myServiceOnly ? 'check' : 'hammer',
            label: 'Coincide con mi servicio',
            selected: f.myServiceOnly,
            onTap: () => setState(() => f = f.copyWith(myServiceOnly: !f.myServiceOnly))),
        const SizedBox(height: 8),
        OptRow(
            icon: f.today ? 'check' : 'bolt',
            label: 'Urgentes (hoy)',
            selected: f.today,
            onTap: () => setState(() => f = f.copyWith(today: !f.today))),
        _label('Categoría'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final c in allCats)
            ToggleChip(
              label: c.name,
              icon: c.icon,
              selected: f.cat == c.id,
              onTap: () => setState(() => f = f.copyWith(cat: f.cat == c.id ? null : c.id)),
            ),
        ]),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(
            child: NexoButton(
                label: 'Quitar filtros', variant: NexoButtonVariant.ghost, onPressed: () => setState(() => f = OppFilters(q: f.q))),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: NexoButton(
              label: 'Aplicar',
              onPressed: () {
                ref.read(oppFiltersProvider.notifier).set(f);
                Navigator.of(context).pop();
              },
            ),
          ),
        ]),
      ],
    );
  }
}
