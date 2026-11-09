import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/theme/tokens.dart';

String hexOf(Color c) {
  final v = c.toARGB32() & 0xFFFFFF;
  return '#${v.toRadixString(16).padLeft(6, '0')}';
}

/// Trazos copiados del diccionario `IC` de la maqueta (viewBox 24×24, trazo 1.8).
/// `mail`, `eyeOff`, `map`, `locate`, `trash` y `edit` no existen en la maqueta;
/// se dibujan con el mismo estilo.
const Map<String, String> _paths = {
  'camera':
      r'<path d="M4 8h3l1.6-2.2h6.8L17 8h3a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V9a1 1 0 0 1 1-1z"/><circle cx="12" cy="13" r="3.6"/>',
  'home': r'<path d="M3 11l9-8 9 8"/><path d="M5 10v10h14V10"/>',
  'search': r'<circle cx="11" cy="11" r="7"/><path d="M20 20l-4-4"/>',
  'plus': r'<path d="M12 5v14M5 12h14"/>',
  'bookmark': r'<path d="M6 3h12v18l-6-4-6 4z"/>',
  'user': r'<circle cx="12" cy="8" r="4"/><path d="M4 21c1-4 4-6 8-6s7 2 8 6"/>',
  'sliders': r'<path d="M4 7h9M17 7h3M4 17h3M11 17h9"/><circle cx="15" cy="7" r="2"/><circle cx="9" cy="17" r="2"/>',
  'pin': r'<path d="M12 21s7-6.2 7-11a7 7 0 10-14 0c0 4.8 7 11 7 11z"/><circle cx="12" cy="10" r="2.5"/>',
  'shield': r'<path d="M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z"/><path d="M8.5 12l2.5 2.5 4.5-5"/>',
  'phone': r'<path d="M5 4h4l2 5-2.5 1.5a11 11 0 005 5L15 13l5 2v4a2 2 0 01-2 2A16 16 0 013 6a2 2 0 012-2z"/>',
  'chat': r'<path d="M4 5h16v11H9l-5 4z"/>',
  'send': r'<path d="M4 12l16-8-6 16-2.5-6.5z"/><path d="M11.5 13.5L20 4"/>',
  'share':
      r'<circle cx="6" cy="12" r="2.5"/><circle cx="18" cy="6" r="2.5"/><circle cx="18" cy="18" r="2.5"/><path d="M8.2 10.8l7.6-3.6M8.2 13.2l7.6 3.6"/>',
  'flag': r'<path d="M5 21V4h11l-1.5 4L16 12H5"/>',
  'thumb':
      r'<path d="M7 11v9H4v-9z"/><path d="M7 11l4-8c2 0 3 1.5 2.5 3.5L13 9h6a2 2 0 012 2.4l-1.3 6.5a2 2 0 01-2 1.6H7"/>',
  'back': r'<path d="M15 5l-7 7 7 7"/>',
  'close': r'<path d="M6 6l12 12M18 6L6 18"/>',
  'drop': r'<path d="M12 3s6 6.5 6 11a6 6 0 11-12 0c0-4.5 6-11 6-11z"/>',
  'bolt': r'<path d="M13 2L5 14h6l-1 8 8-12h-6z"/>',
  'hammer': r'<path d="M3 21l8-8"/><path d="M9 7l4-4 8 8-4 4z"/>',
  'brush':
      r'<rect x="4" y="3" width="14" height="6" rx="1.5"/><path d="M18 6h2v5H11v4"/><rect x="9" y="15" width="4" height="6" rx="1"/>',
  'leaf': r'<path d="M5 19C5 9 11 4 20 4c0 9-5 15-15 15z"/><path d="M5 19c3-5 6-8 10-10"/>',
  'key': r'<circle cx="8" cy="15" r="4"/><path d="M11 12l9-9M16 7l3 3M14 9l2 2"/>',
  'clock': r'<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
  'copy':
      r'<rect x="8" y="8" width="12" height="12" rx="2"/><path d="M16 8V5a1 1 0 00-1-1H5a1 1 0 00-1 1v10a1 1 0 001 1h3"/>',
  'bell': r'<path d="M6 17V11a6 6 0 1112 0v6l2 2H4z"/><path d="M10 21h4"/>',
  'info': r'<circle cx="12" cy="12" r="9"/><path d="M12 11v5M12 8h.01"/>',
  'image':
      r'<rect x="3" y="4" width="18" height="16" rx="2"/><circle cx="9" cy="10" r="1.7"/><path d="M4 18l5-5 4 4 3-3 4 4"/>',
  'check': r'<path d="M5 12.5l4.5 4.5L19 7"/>',
  'chevron': r'<path d="M9 5l7 7-7 7"/>',
  'dots': r'<circle cx="5" cy="12" r="1.4"/><circle cx="12" cy="12" r="1.4"/><circle cx="19" cy="12" r="1.4"/>',
  'out': r'<path d="M8 16L16 8M9 8h7v7"/>',
  'compare': r'<rect x="3" y="4" width="7" height="16" rx="1.5"/><rect x="14" y="4" width="7" height="16" rx="1.5"/>',
  'menu': r'<path d="M4 7h16M4 12h16M4 17h16"/>',
  'star': r'<path d="M12 3.5l2.6 5.4 5.9.8-4.3 4.1 1 5.9L12 16.9l-5.2 2.8 1-5.9L3.5 9.7l5.9-.8z"/>',
  'eye': r'<path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>',
  'eyeOff':
      r'<path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/><path d="M4 4l16 16"/>',
  'mail': r'<rect x="3" y="5" width="18" height="14" rx="2"/><path d="M3.5 7l8.5 6 8.5-6"/>',
  'map': r'<path d="M9 4L3 6v14l6-2 6 2 6-2V4l-6 2z"/><path d="M9 4v14M15 6v14"/>',
  'locate': r'<circle cx="12" cy="12" r="4"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3"/>',
  'trash': r'<path d="M4 7h16M9 7V4h6v3M6 7l1 13h10l1-13"/>',
  'edit': r'<path d="M4 20h4L19 9l-4-4L4 16z"/><path d="M14 6l4 4"/>',
};

class NexoIcon extends StatelessWidget {
  const NexoIcon(
    this.name, {
    super.key,
    this.size = 20,
    this.color,
    this.strokeWidth = 1.8,
    this.fillColor,
  });

  final String name;
  final double size;
  final Color? color;
  final double strokeWidth;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? NexoColors.ink;
    final fill = fillColor == null ? 'none' : hexOf(fillColor!);
    final svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="$fill" '
        'stroke="${hexOf(c)}" stroke-width="$strokeWidth" stroke-linecap="round" '
        'stroke-linejoin="round">${_paths[name] ?? ''}</svg>';
    return ExcludeSemantics(
      child: SvgPicture.string(svg, width: size, height: size),
    );
  }
}
