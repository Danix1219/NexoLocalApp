import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../validation.dart';
import 'nexo_icon.dart';

OutlineInputBorder _border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: c, width: 1.5),
    );

/// Campo de la maqueta (`.fb input`): relleno #F6F5F0 sin borde; al enfocar,
/// fondo blanco y borde verde.
InputDecoration nexoInputDecoration({String? hint, Widget? suffix}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: NexoText.body(15, color: NexoColors.muted.withValues(alpha: .8)),
    filled: true,
    fillColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.focused) ? NexoColors.surface : NexoColors.field),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
    border: _border(Colors.transparent),
    enabledBorder: _border(Colors.transparent),
    disabledBorder: _border(Colors.transparent),
    focusedBorder: _border(NexoColors.brand),
    suffixIcon: suffix,
    suffixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    counterText: '',
  );
}

class NexoField extends StatelessWidget {
  const NexoField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
    this.inputFormatters,
    this.style,
    this.textAlign = TextAlign.start,
    this.maxLength,
    this.autofocus = false,
    this.capitalization = TextCapitalization.none,
    this.enabled = true,
    this.helper,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final TextStyle? style;
  final TextAlign textAlign;
  final int? maxLength;
  final bool autofocus;
  final TextCapitalization capitalization;
  final bool enabled;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: NexoText.body(14, weight: FontWeight.w700)),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          enableSuggestions: !obscure,
          autocorrect: false,
          autofillHints: autofillHints,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          inputFormatters: [
            if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
            ...?inputFormatters,
          ],
          style: style ?? NexoText.body(16),
          textAlign: textAlign,
          autofocus: autofocus,
          enabled: enabled,
          textCapitalization: capitalization,
          decoration: nexoInputDecoration(hint: hint, suffix: suffix),
        ),
        if (helper != null) ...[
          const SizedBox(height: 7),
          NexoHint(helper!),
        ],
      ],
    );
  }
}

/// Campo de contraseña con botón de mostrar/ocultar (`passField` + `.pwt`).
class NexoPasswordField extends StatefulWidget {
  const NexoPasswordField({
    super.key,
    required this.label,
    required this.controller,
    this.isNew = false,
    this.textInputAction,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final bool isNew;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<NexoPasswordField> createState() => _NexoPasswordFieldState();
}

class _NexoPasswordFieldState extends State<NexoPasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return NexoField(
      label: widget.label,
      controller: widget.controller,
      obscure: _hidden,
      maxLength: 64,
      keyboardType: TextInputType.visiblePassword,
      autofillHints: [widget.isNew ? AutofillHints.newPassword : AutofillHints.password],
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      suffix: Semantics(
        button: true,
        label: _hidden ? 'Mostrar contraseña' : 'Ocultar contraseña',
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _hidden = !_hidden),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: NexoIcon(_hidden ? 'eye' : 'eyeOff', color: NexoColors.muted),
            ),
          ),
        ),
      ),
    );
  }
}

/// Checklist de contraseña en vivo (`pwReqHTML`).
class PasswordRequirements extends StatelessWidget {
  const PasswordRequirements({super.key, required this.password, required this.confirm});

  final String password;
  final String confirm;

  @override
  Widget build(BuildContext context) {
    Widget item(bool ok, String text) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Semantics(
            label: '$text: ${ok ? 'cumple' : 'pendiente'}',
            excludeSemantics: true,
            child: Row(
              children: [
                NexoIcon(ok ? 'check' : 'dots', size: 16, color: ok ? NexoColors.ok : NexoColors.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    style: NexoText.body(13,
                        weight: ok ? FontWeight.w600 : FontWeight.w400, color: ok ? NexoColors.ok : NexoColors.muted),
                  ),
                ),
              ],
            ),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        item(pwHasLength(password), 'Al menos 8 caracteres'),
        item(pwHasLetterAndDigit(password), 'Una letra y un número'),
        item(password.isNotEmpty && password == confirm, 'Las contraseñas coinciden'),
      ],
    );
  }
}

/// Texto de ayuda (`.hint`).
class NexoHint extends StatelessWidget {
  const NexoHint(this.text, {super.key, this.center = false});
  final String text;
  final bool center;

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: NexoText.body(12.5, color: NexoColors.muted, height: 1.45),
      );
}

/// Error en línea (`.err`), anunciado a lectores de pantalla.
class NexoError extends StatelessWidget {
  const NexoError(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: NexoIcon('info', size: 18, color: NexoColors.danger),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: NexoText.body(13.5, weight: FontWeight.w600, color: NexoColors.danger, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
