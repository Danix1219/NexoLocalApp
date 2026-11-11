import 'package:flutter/material.dart';

import '../../app/theme/typography.dart';
import '../../core/widgets/ui.dart';
import '../../data/models.dart';

/// Carrusel de fotos estilo Instagram (`carouselHTML`): se desliza, muestra
/// "2/3" que se actualiza al deslizar y la etiqueta del trabajo.
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
  void didUpdateWidget(PhotoCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.images.length != oldWidget.images.length ||
        widget.images.map((i) => i.url).join('|') != oldWidget.images.map((i) => i.url).join('|')) {
      _i = 0;
      if (_c.hasClients) _c.jumpToPage(0);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) return const SizedBox.shrink();
    final imgs = widget.images;
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
          ],
        ],
      ),
    );
  }
}
