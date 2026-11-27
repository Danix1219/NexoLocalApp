import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../core/widgets/nexo_button.dart';
import '../../core/widgets/nexo_icon.dart';
import '../../core/widgets/nexo_sheet.dart';
import '../../core/widgets/ui.dart';

/// Horario de un día en horas completas; `null` = cerrado.
typedef DayRange = (int open, int close);

const _dayFull = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
const _firstOpen = 5, _lastOpen = 22, _lastClose = 23;
const DayRange _defaultRange = (9, 18);

String hourLabel(int hour) => '$hour:00';

/// Editor semanal. No guarda nada por sí mismo: entrega el resultado a [onSave],
/// que devuelve `false` si el servidor no confirmó el cambio.
class HoursEditor extends StatefulWidget {
  const HoursEditor({super.key, required this.initialDays, required this.initialUrgent, required this.onSave});
  final List<DayRange?> initialDays;
  final bool initialUrgent;
  final Future<bool> Function(List<DayRange?> days, bool urgent) onSave;

  @override
  State<HoursEditor> createState() => _HoursEditorState();
}

class _HoursEditorState extends State<HoursEditor> {
  late final List<DayRange?> _days = List.of(widget.initialDays);
  late bool _urgent = widget.initialUrgent;
  bool _busy = false;

  int get _openCount => _days.where((d) => d != null).length;

  /// Rango que se copia al abrir días nuevos: el primero ya configurado.
  DayRange get _template => _days.firstWhere((d) => d != null, orElse: () => _defaultRange)!;

  bool _isPreset(int openDays) => List.generate(7, (i) => (_days[i] != null) == (i < openDays)).every((x) => x);

  void _preset(int openDays) {
    final range = _template;
    setState(() {
      for (var i = 0; i < 7; i++) {
        _days[i] = i < openDays ? (_days[i] ?? range) : null;
      }
    });
  }

  Future<void> _edit(int index) async {
    final result = await showNexoSheet<(DayRange, bool)>(
      context,
      builder: (_) => _RangePicker(day: _dayFull[index], initial: _days[index] ?? _defaultRange, openCount: _openCount),
    );
    if (result == null || !mounted) return;
    final (range, all) = result;
    setState(() {
      _days[index] = range;
      if (all) {
        for (var i = 0; i < 7; i++) {
          if (_days[i] != null) _days[i] = range;
        }
      }
    });
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final ok = await widget.onSave(List.of(_days), _urgent);
    if (!ok && mounted) setState(() => _busy = false);
  }

  Widget _dayRow(int i) {
    final range = _days[i];
    return Container(
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_dayFull[i], style: NexoText.body(14.5, weight: FontWeight.w800)),
                if (range == null) Text('Cerrado', style: NexoText.body(12.5, color: NexoColors.muted)),
              ],
            ),
          ),
          if (range != null)
            Semantics(
              button: true,
              label: 'Cambiar horario de ${_dayFull[i]}',
              child: Material(
                color: NexoColors.brandSoft,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _edit(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${hourLabel(range.$1)} – ${hourLabel(range.$2)}',
                          style: NexoText.body(13.5, weight: FontWeight.w800, color: NexoColors.brandDeep),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.edit_outlined, size: 15, color: NexoColors.brandDeep),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(width: 6),
          Semantics(
            label: 'Atender ${_dayFull[i]}',
            child: Switch(
              value: range != null,
              activeTrackColor: NexoColors.brand,
              onChanged: _busy ? null : (on) => setState(() => _days[i] = on ? _template : null),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetHeader(
          'Horario de atención',
          subtitle: 'Activa los días que trabajas y toca el horario para cambiarlo.',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in const [(5, 'Lun a vie'), (6, 'Lun a sáb'), (7, 'Todos los días')])
              ToggleChip(label: preset.$2, selected: _isPreset(preset.$1), onTap: () => _preset(preset.$1)),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: NexoColors.line),
          ),
          child: Column(
            children: [
              for (var i = 0; i < 7; i++) ...[if (i > 0) const Divider(height: 1, color: NexoColors.line), _dayRow(i)],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Material(
          color: NexoColors.accentSoft,
          borderRadius: BorderRadius.circular(18),
          child: SwitchListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            contentPadding: const EdgeInsets.fromLTRB(14, 2, 8, 2),
            secondary: const NexoIcon('bolt', size: 20, color: NexoColors.accentInk),
            title: Text('Atiendo urgencias', style: NexoText.body(14.5, weight: FontWeight.w800)),
            subtitle: Text('También fuera de este horario.', style: NexoText.body(12.5, color: NexoColors.muted)),
            activeTrackColor: NexoColors.brand,
            value: _urgent,
            onChanged: _busy ? null : (value) => setState(() => _urgent = value),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          _openCount == 0
              ? 'Tu perfil aparecerá sin días de atención.'
              : '$_openCount ${plural(_openCount, 'día', 'días')} de atención a la semana',
          textAlign: TextAlign.center,
          style: NexoText.body(12.5, weight: FontWeight.w600, color: NexoColors.muted),
        ),
        const SizedBox(height: 8),
        NexoButton(label: 'Guardar horario', loading: _busy, onPressed: _save),
      ],
    );
  }
}

/// Panel de horas en cuadrícula: evita el menú flotante que tapaba el editor.
class _RangePicker extends StatefulWidget {
  const _RangePicker({required this.day, required this.initial, required this.openCount});
  final String day;
  final DayRange initial;
  final int openCount;

  @override
  State<_RangePicker> createState() => _RangePickerState();
}

class _RangePickerState extends State<_RangePicker> {
  late int _open = widget.initial.$1.clamp(_firstOpen, _lastOpen);
  late int _close = widget.initial.$2.clamp(_open + 1, _lastClose);
  bool _editingOpen = true;
  bool _all = false;

  void _pick(int hour) => setState(() {
    if (_editingOpen) {
      _open = hour;
      if (_close <= hour) _close = hour + 1;
      _editingOpen = false;
    } else {
      _close = hour;
    }
  });

  Widget _end(String label, int hour, bool active, VoidCallback onTap) => Expanded(
    child: Semantics(
      button: true,
      selected: active,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? NexoColors.brandSoft : NexoColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: active ? NexoColors.brand : NexoColors.line, width: active ? 2 : 1),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: NexoText.body(12, weight: FontWeight.w700, color: NexoColors.muted),
              ),
              Text(hourLabel(hour), style: NexoText.display(22)),
            ],
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final first = _editingOpen ? _firstOpen : _open + 1;
    final last = _editingOpen ? _lastOpen : _lastClose;
    final selected = _editingOpen ? _open : _close;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader(widget.day, subtitle: 'Elige a qué hora abres y a qué hora cierras.'),
        Row(
          children: [
            _end('Abre', _open, _editingOpen, () => setState(() => _editingOpen = true)),
            const SizedBox(width: 10),
            _end('Cierra', _close, !_editingOpen, () => setState(() => _editingOpen = false)),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, box) {
            final width = (box.maxWidth - 3 * 8) / 4;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var h = first; h <= last; h++)
                  SizedBox(
                    width: width,
                    child: Semantics(
                      button: true,
                      selected: h == selected,
                      child: Material(
                        color: h == selected ? NexoColors.brand : NexoColors.bg,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          key: ValueKey('hour-$h'),
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _pick(h),
                          child: Container(
                            height: 44,
                            alignment: Alignment.center,
                            child: Text(
                              hourLabel(h),
                              style: NexoText.body(
                                13.5,
                                weight: FontWeight.w800,
                                color: h == selected ? Colors.white : NexoColors.ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        if (widget.openCount > 1)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: NexoColors.brand,
            value: _all,
            onChanged: (value) => setState(() => _all = value ?? false),
            title: Text('Usar este horario en todos los días activos', style: NexoText.body(13.5)),
          ),
        const SizedBox(height: 10),
        NexoButton(label: 'Usar este horario', onPressed: () => Navigator.of(context).pop(((_open, _close), _all))),
      ],
    );
  }
}
