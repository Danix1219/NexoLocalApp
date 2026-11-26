import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';

/// Código de 6 dígitos en casillas. Debajo hay un solo campo real: así
/// funcionan el teclado, pegar y el autocompletado del sistema.
class CodeBoxes extends StatefulWidget {
  const CodeBoxes({super.key, required this.controller, this.invalid = false});
  final TextEditingController controller;
  final bool invalid;

  @override
  State<CodeBoxes> createState() => _CodeBoxesState();
}

class _CodeBoxesState extends State<CodeBoxes> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
    _focus.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    _focus.dispose();
    super.dispose();
  }

  Widget _box(int index, String code) {
    final filled = index < code.length;
    final active = _focus.hasFocus && index == code.length.clamp(0, 5);
    final color = widget.invalid
        ? NexoColors.danger
        : active
        ? NexoColors.brand
        : filled
        ? NexoColors.brand.withValues(alpha: .35)
        : Colors.transparent;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active || filled ? NexoColors.surface : NexoColors.field,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color, width: active ? 2 : 1.5),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(filled ? code[index] : '', style: NexoText.display(25, weight: FontWeight.w800)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.controller.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Código de 6 dígitos', style: NexoText.body(14, weight: FontWeight.w700)),
        const SizedBox(height: 9),
        Stack(
          children: [
            ExcludeSemantics(
              child: Row(
                children: [
                  for (var i = 0; i < 6; i++) ...[
                    if (i > 0) SizedBox(width: i == 3 ? 14 : 7),
                    Expanded(child: _box(i, code)),
                  ],
                ],
              ),
            ),
            Positioned.fill(
              child: Semantics(
                label: 'Código de 6 dígitos',
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  autofocus: true,
                  expands: true,
                  maxLines: null,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                  showCursor: false,
                  enableInteractiveSelection: true,
                  style: const TextStyle(color: Colors.transparent, fontSize: 1),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    counterText: '',
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
