import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../data/fake/fake_seed.dart';
import '../local/local_store.dart';
import '../network/api_exception.dart';
import 'nexo_button.dart';
import 'nexo_icon.dart';

Color hexColor(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse(h.length == 6 ? 'FF$h' : h, radix: 16));
}

String initialsOf(String name) {
  final w = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (w.isEmpty) return '?';
  return (w[0][0] + (w.length > 1 ? w[1][0] : '')).toUpperCase();
}

String plural(int n, String one, String many) => n == 1 ? one : many;

/// Mensaje para errores de la API fuera de autenticación.
String apiErrorMessage(Object e) {
  if (e is ApiException) {
    if (e.isNetwork) return 'Sin conexión. Revisa tu internet e inténtalo de nuevo.';
    // Moderación de contenido (requisito 16: no se sube lo inapropiado).
    if (e.code == 'content.inappropriate') {
      return 'No pudimos publicarlo: el texto o la foto no cumplen las reglas de la comunidad. Revísalo y vuelve a intentarlo.';
    }
    if (e.code == 'upload.rejected_by_moderation') {
      return 'Esa foto no cumple las reglas de la comunidad. Elige otra.';
    }
    if (e.code == 'content.images_limit') return 'Puedes subir hasta 6 fotos.';
    if (e.code == kQueuedOffline) return 'Sin señal: lo guardamos y se publicará en cuanto vuelva la conexión.';
    if (e.status == 429) return 'Hiciste muchos intentos. Espera un momento.';
    if (e.detail != null && e.detail!.isNotEmpty) return e.detail!;
    if (e.status == 404) return 'Esto ya no existe.';
    if (e.status == 403) return 'No tienes permiso para hacer esto.';
    return 'Algo salió mal. Inténtalo de nuevo.';
  }
  return 'Algo salió mal. Inténtalo de nuevo.';
}

// ------------------------------------------------------------------ imágenes

/// Muestra una URL de la API, un archivo local (`file://`, fotos elegidas en
/// modo de prueba) o una foto de ejemplo (`demo://categoria/n`).
class NexoImage extends StatelessWidget {
  const NexoImage(this.url, {super.key, this.fit = BoxFit.cover});
  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('demo://')) {
      final parts = url.substring(7).split('/');
      return DemoPhoto(cat: parts.first, index: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0);
    }
    if (url.startsWith('file://')) {
      return Image.file(File(url.substring(7)), fit: fit, errorBuilder: (_, __, ___) => const _Broken());
    }
    return Image.network(
      url,
      fit: fit,
      errorBuilder: (_, __, ___) => const _Broken(),
      loadingBuilder: (c, child, p) => p == null ? child : const ColoredBox(color: NexoColors.surface2),
    );
  }
}

class _Broken extends StatelessWidget {
  const _Broken();
  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: NexoColors.surface2,
        child: Center(child: NexoIcon('image', size: 28, color: NexoColors.muted)),
      );
}

/// Mosaico de color de la categoría (`.tile` sin foto).
class DemoPhoto extends StatelessWidget {
  const DemoPhoto({super.key, required this.cat, this.index = 0});
  final String cat;
  final int index;

  @override
  Widget build(BuildContext context) {
    final c = fcat(cat);
    final c2 = hexColor(c.c2);
    final c1 = hexColor(c.c1);
    final shades = [
      Color.lerp(c2, const Color(0xFFF1F2ED), .84)!,
      Color.lerp(c1, const Color(0xFFF1F2ED), .78)!,
      Color.lerp(c2, const Color(0xFFF1F2ED), .70)!,
    ];
    return ColoredBox(
      color: shades[index % shades.length],
      child: Center(
        child: FractionallySizedBox(
          widthFactor: .2,
          child: AspectRatio(
            aspectRatio: 1,
            child: LayoutBuilder(
              builder: (_, k) => NexoIcon(index % 2 == 0 ? c.icon : 'image',
                  size: k.maxWidth, color: c2.withValues(alpha: .6), strokeWidth: 1.4),
            ),
          ),
        ),
      ),
    );
  }
}

/// `.av`: foto o iniciales en círculo.
class NexoAvatar extends StatelessWidget {
  const NexoAvatar({super.key, required this.name, this.url, this.size = 42, this.border = false, this.icon});
  final String name;
  final String? url;
  final double size;
  final bool border;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: NexoColors.brandSoft,
        border: border ? Border.all(color: NexoColors.surface, width: size > 70 ? 4 : 2) : null,
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: url != null && url!.isNotEmpty
          ? SizedBox.expand(child: NexoImage(url!))
          : icon != null
              ? NexoIcon(icon!, size: size * .42, color: NexoColors.brand)
              : Text(initialsOf(name), style: NexoText.display(size * .36, color: NexoColors.brand, letterSpacing: 0)),
    );
  }
}

/// Dos avatares encimados (`avStack`) con palomita opcional.
class AvatarPair extends StatelessWidget {
  const AvatarPair({super.key, required this.a, required this.b, this.ok = false, this.size = 44});
  final (String, String?) a;
  final (String, String?) b;
  final bool ok;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.7,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          NexoAvatar(name: a.$1, url: a.$2, size: size, border: true),
          Positioned(left: size * .7, child: NexoAvatar(name: b.$1, url: b.$2, size: size, border: true)),
          if (ok)
            Positioned(
              left: size * .55,
              bottom: -4,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                    color: NexoColors.ok,
                    shape: BoxShape.circle,
                    border: Border.all(color: NexoColors.surface, width: 2)),
                child: const Center(child: NexoIcon('check', size: 13, color: Colors.white, strokeWidth: 2.6)),
              ),
            ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- estructura

/// Barra de título de pantalla principal (`.topbar` + `.screen-title`).
class ScreenTitleBar extends StatelessWidget {
  const ScreenTitleBar(this.title, {super.key, this.trailing, this.border = true});
  final String title;
  final Widget? trailing;
  final bool border;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: NexoColors.surface,
        border: border ? const Border(bottom: BorderSide(color: NexoColors.line)) : null,
      ),
      child: Row(
        children: [
          Expanded(child: Semantics(header: true, child: Text(title, style: NexoText.display(24)))),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Barra de subpantalla con volver (`.subbar`).
class SubBar extends StatelessWidget {
  const SubBar(this.title, {super.key, this.onBack, this.actions = const []});
  final String title;
  final VoidCallback? onBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: NexoColors.surface,
        border: Border(bottom: BorderSide(color: NexoColors.line)),
      ),
      child: Row(
        children: [
          NexoIconButton(
            icon: 'back',
            label: 'Volver',
            onTap: onBack ?? () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 10),
          Expanded(
              child:
                  Text(title, style: NexoText.display(17, weight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
          ...actions,
        ],
      ),
    );
  }
}

/// Encabezado de sección (`.sect`).
class Sect extends StatelessWidget {
  const Sect(this.title, {super.key, this.trailing, this.onTrailing});
  final String title;
  final String? trailing;
  final VoidCallback? onTrailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child:
                  Text(title, style: NexoText.display(18, weight: FontWeight.w700, height: 1.15, letterSpacing: -.18)),
            ),
          ),
          if (trailing != null)
            onTrailing == null
                ? Text(trailing!, style: NexoText.body(12.5, color: NexoColors.muted))
                : InkWell(
                    onTap: onTrailing,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child:
                          Text(trailing!, style: NexoText.body(13, weight: FontWeight.w700, color: NexoColors.brand)),
                    ),
                  ),
        ],
      ),
    );
  }
}

/// `.empty`: aviso con borde punteado y acción opcional.
class EmptyState extends StatelessWidget {
  const EmptyState(
      {super.key,
      this.icon,
      required this.title,
      this.text,
      this.action,
      this.onAction,
      this.secondary,
      this.onSecondary});
  final String? icon;
  final String title;
  final String? text;
  final String? action;
  final VoidCallback? onAction;
  final String? secondary;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 22, 16, 22),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      decoration: BoxDecoration(
        color: NexoColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: NexoColors.line),
      ),
      child: Column(
        children: [
          if (icon != null) ...[NexoIcon(icon!, size: 34, color: NexoColors.brand), const SizedBox(height: 10)],
          Text(title, textAlign: TextAlign.center, style: NexoText.display(18, weight: FontWeight.w700)),
          if (text != null) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(text!,
                  textAlign: TextAlign.center, style: NexoText.body(14, color: NexoColors.muted, height: 1.45)),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 14),
            NexoButton(label: action!, onPressed: onAction, block: false),
          ],
          if (secondary != null) ...[
            const SizedBox(height: 8),
            NexoButton(label: secondary!, onPressed: onSecondary, block: false, variant: NexoButtonVariant.ghost),
          ],
        ],
      ),
    );
  }
}

enum BadgeTone { plain, ok, warn, brand, hot, ink }

/// `.bdg`: insignia pequeña.
class NBadge extends StatelessWidget {
  const NBadge(this.label, {super.key, this.icon, this.tone = BadgeTone.plain, this.onTap});
  final String label;
  final String? icon;
  final BadgeTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      BadgeTone.ok => (NexoColors.okSoft, NexoColors.ok),
      BadgeTone.warn => (NexoColors.warnSoft, NexoColors.warn),
      BadgeTone.brand => (NexoColors.brandSoft, NexoColors.brand),
      BadgeTone.hot => (NexoColors.accentSoft, NexoColors.accentInk),
      BadgeTone.ink => (NexoColors.surface2, NexoColors.ink),
      BadgeTone.plain => (NexoColors.surface2, NexoColors.muted),
    };
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[NexoIcon(icon!, size: 14, color: fg), const SizedBox(width: 5)],
          // Sin Flexible: la insignia también va en filas de ancho libre.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 230),
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: NexoText.body(12, weight: FontWeight.w600, color: fg)),
          ),
        ],
      ),
    );
    if (onTap == null) return child;
    return Semantics(button: true, child: GestureDetector(onTap: onTap, child: child));
  }
}

/// Fila de datos con ícono (`.facts`).
class Facts extends StatelessWidget {
  const Facts(this.items, {super.key});
  final List<(String icon, String text, bool ok)> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 4,
      children: [
        for (final it in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              NexoIcon(it.$1, size: 15, color: it.$3 ? NexoColors.ok : NexoColors.muted),
              const SizedBox(width: 5),
              Text(it.$2,
                  style: NexoText.body(13,
                      weight: it.$3 ? FontWeight.w700 : FontWeight.w400,
                      color: it.$3 ? NexoColors.ok : NexoColors.muted)),
            ],
          ),
      ],
    );
  }
}

/// `.seg`: dos o más opciones exclusivas.
class SegControl<T> extends StatelessWidget {
  const SegControl(
      {super.key, required this.options, required this.value, required this.onChanged, this.small = false});
  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(small ? 3 : 4),
      decoration: BoxDecoration(color: NexoColors.surface2, borderRadius: BorderRadius.circular(small ? 13 : 14)),
      child: Row(
        children: [
          for (final o in options)
            Expanded(
              child: Semantics(
                button: true,
                selected: o.$1 == value,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(o.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: EdgeInsets.symmetric(vertical: small ? 10 : 10, horizontal: 6),
                    decoration: BoxDecoration(
                      color: o.$1 == value ? NexoColors.surface : Colors.transparent,
                      borderRadius: BorderRadius.circular(small ? 10 : 11),
                      boxShadow: o.$1 == value
                          ? const [BoxShadow(color: Color(0x1F000000), blurRadius: 4, offset: Offset(0, 1))]
                          : null,
                    ),
                    child: Text(
                      o.$2,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: NexoText.body(small ? 13 : 14,
                          weight: FontWeight.w700,
                          color: o.$1 == value ? (small ? NexoColors.brand : NexoColors.ink) : NexoColors.muted,
                          height: 1.15),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// `.fc`: chip que se activa (filtros, intereses, orden).
class ToggleChip extends StatelessWidget {
  const ToggleChip({super.key, required this.label, required this.selected, required this.onTap, this.icon});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? NexoColors.brandDeep : NexoColors.ink;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? NexoColors.brandSoft : NexoColors.surface,
        shape: StadiumBorder(side: BorderSide(color: selected ? NexoColors.brand : NexoColors.line, width: 1.5)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected && icon == null) ...[NexoIcon('check', size: 15, color: fg), const SizedBox(width: 5)],
                if (icon != null) ...[NexoIcon(icon!, size: 16, color: fg), const SizedBox(width: 6)],
                Text(label, style: NexoText.body(13, weight: FontWeight.w700, color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `.card` / `.box`: contenedor blanco con borde y sombra suave.
class NexoCard extends StatelessWidget {
  const NexoCard(
      {super.key,
      required this.child,
      this.margin = const EdgeInsets.fromLTRB(12, 10, 12, 0),
      this.padding = const EdgeInsets.all(14),
      this.onTap,
      this.title});
  final Widget child;
  final EdgeInsets margin;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(20);
    Widget body = Padding(
      padding: padding,
      child: title == null
          ? child
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title!, style: NexoText.display(16, weight: FontWeight.w700)),
                const SizedBox(height: 10),
                child,
              ],
            ),
    );
    if (onTap != null) body = InkWell(customBorder: RoundedRectangleBorder(borderRadius: r), onTap: onTap, child: body);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: NexoColors.surface,
        borderRadius: r,
        border: Border.all(color: NexoColors.line),
        boxShadow: const [BoxShadow(color: Color(0x0B1F302B), blurRadius: 18, offset: Offset(0, 5))],
      ),
      child: Material(type: MaterialType.transparency, child: body),
    );
  }
}

/// `.stats`: tres cifras en cajas.
class StatsRow extends StatelessWidget {
  const StatsRow(this.items, {super.key});
  final List<(String value, String label)> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              decoration: BoxDecoration(
                color: NexoColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: NexoColors.line),
              ),
              child: Column(
                children: [
                  Text(items[i].$1, style: NexoText.display(18), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(items[i].$2,
                      textAlign: TextAlign.center, style: NexoText.body(12, color: NexoColors.muted, height: 1.2)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Fila etiqueta/valor (`.frow` / `.qt`).
class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key, this.sub, this.highlight = false, this.muted = false});
  final String label;
  final String value;
  final String? sub;
  final bool highlight;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: NexoText.body(13, color: NexoColors.muted))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value,
                    textAlign: TextAlign.right,
                    style: highlight
                        ? NexoText.display(18, color: NexoColors.brandDeep)
                        : NexoText.body(14, weight: FontWeight.w700, color: muted ? NexoColors.muted : NexoColors.ink)),
                if (sub != null)
                  Text(sub!, textAlign: TextAlign.right, style: NexoText.body(12.5, color: NexoColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Estrellas de solo lectura.
class StarsView extends StatelessWidget {
  const StarsView(this.stars, {super.key, this.size = 16});
  final num stars;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: NexoIcon('star',
                size: size,
                color: i <= stars.round() ? NexoColors.accent2 : NexoColors.line,
                fillColor: i <= stars.round() ? NexoColors.accent2 : null),
          ),
      ],
    );
  }
}

/// Selector de estrellas (`.starpick`).
class StarPicker extends StatelessWidget {
  const StarPicker({super.key, required this.value, required this.onChanged, this.size = 38});
  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Semantics(
            button: true,
            label: '$i ${plural(i, 'estrella', 'estrellas')}',
            selected: i <= value,
            child: InkResponse(
              onTap: () => onChanged(i),
              radius: size * .7,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: NexoIcon('star',
                    size: size,
                    color: i <= value ? NexoColors.accent2 : NexoColors.muted,
                    fillColor: i <= value ? NexoColors.accent2 : null),
              ),
            ),
          ),
      ],
    );
  }
}

/// `.notice`: aviso gris con ícono.
class Notice extends StatelessWidget {
  const Notice(this.text, {super.key, this.icon = 'info', this.tone = BadgeTone.plain});
  final String text;
  final String icon;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      BadgeTone.ok => (NexoColors.okSoft, NexoColors.ok),
      BadgeTone.warn => (NexoColors.warnSoft, NexoColors.warn),
      BadgeTone.brand => (NexoColors.brandSoft, NexoColors.brandDeep),
      BadgeTone.hot => (NexoColors.accentSoft, NexoColors.accentInk),
      _ => (NexoColors.surface2, NexoColors.muted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NexoIcon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: NexoText.body(13.5, weight: FontWeight.w600, color: fg, height: 1.4))),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------- asíncrono

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.padding = 48});
  final double padding;
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.all(padding),
        child: const Center(
          child: SizedBox(
              width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.6, color: NexoColors.brand)),
        ),
      );
}

class ErrorView extends StatelessWidget {
  const ErrorView(this.error, {super.key, this.onRetry});
  final Object error;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => EmptyState(
        icon: 'info',
        title: 'No pudimos cargar esto',
        text: apiErrorMessage(error),
        action: onRetry == null ? null : 'Reintentar',
        onAction: onRetry,
      );
}

/// Pinta un `AsyncValue` con carga y error con reintento.
Widget asyncView<T>(AsyncValue<T> v, Widget Function(T data) data, {VoidCallback? onRetry, double loadingPad = 48}) {
  return v.when(
    data: data,
    loading: () => LoadingView(padding: loadingPad),
    error: (e, _) => ErrorView(e, onRetry: onRetry),
    skipLoadingOnRefresh: true,
    skipLoadingOnReload: true,
  );
}

/// Contenedor de pantalla con fondo de la app.
class NexoPage extends StatelessWidget {
  const NexoPage({super.key, required this.child, this.bottom, this.background = NexoColors.bg});
  final Widget child;
  final Widget? bottom;
  final Color background;
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: background,
        body: SafeArea(bottom: bottom == null, child: child),
        bottomNavigationBar: bottom,
      );
}
