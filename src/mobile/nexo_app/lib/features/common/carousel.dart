import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../core/widgets/nexo_icon.dart';
import '../../core/widgets/ui.dart';
import '../../data/models.dart';

/// Carrusel de fotos estilo Instagram (`carouselHTML`): se desliza, muestra
/// "2/3", puntos, flechas y la etiqueta del trabajo.
class PhotoCarousel extends StatefulWidget {
  const PhotoCarousel(
      {super.key, required this.images, required this.category, this.tag, this.onTap, this.aspect = 16 / 10});
  final List<Img> images;
  final String category;
  final String? tag;
  final VoidCallback? onTap;
  final double aspect;

  @override
  State<PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<PhotoCarousel> {
  final _c = PageController();
  int _i = 0;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _pill(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(color: const Color(0xA80A1E22), borderRadius: BorderRadius.circular(99)),
        child: Text(t, style: NexoText.body(11, weight: FontWeight.w700, color: Colors.white, letterSpacing: .2)),
      );

  Widget _arrow(String icon, VoidCallback onTap, String label) => Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xE6FFFEFB),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 6)],
            ),
            child: Center(child: NexoIcon(icon, size: 16, color: NexoColors.ink, strokeWidth: 2.2)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final imgs = widget.images.isEmpty ? [Img('demo://${widget.category}/0')] : widget.images;
    final n = imgs.length;
    return AspectRatio(
      aspectRatio: widget.aspect,
      child: Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              controller: _c,
              itemCount: n,
              onPageChanged: (i) => setState(() => _i = i),
              itemBuilder: (_, i) => GestureDetector(
                onTap: widget.onTap,
                child: Semantics(
                  image: true,
                  label: 'Foto ${i + 1} de $n',
                  child: NexoImage(imgs[i].thumbUrl ?? imgs[i].url),
                ),
              ),
            ),
          ),
          if (widget.tag != null) Positioned(left: 10, bottom: 10, child: _pill(widget.tag!)),
          if (n > 1) ...[
            Positioned(right: 10, top: 10, child: _pill('${_i + 1}/$n')),
            if (_i > 0)
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _arrow(
                      'back',
                      () => _c.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
                      'Foto anterior'),
                ),
              ),
            if (_i < n - 1)
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _arrow(
                      'chevron',
                      () => _c.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
                      'Foto siguiente'),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var k = 0; k < n; k++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      width: k == _i ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: k == _i ? Colors.white : Colors.white.withValues(alpha: .6),
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
