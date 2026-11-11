import 'package:flutter/material.dart';
import 'nexo_button.dart';
import 'ui.dart';

/// Shimmer sobre la foto elegida mientras el servidor la revisa.
class PhotoProcessingOverlay extends StatefulWidget {
  const PhotoProcessingOverlay({super.key, this.circular = false});
  final bool circular;
  @override
  State<PhotoProcessingOverlay> createState() => _PhotoProcessingOverlayState();
}

class _PhotoProcessingOverlayState extends State<PhotoProcessingOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motion = MediaQuery.disableAnimationsOf(context);
    final shimmer = AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-2 + 3 * (motion ? .5 : _controller.value), -1),
            end: Alignment(-1 + 3 * (motion ? .5 : _controller.value), 1),
            colors: const [Color(0xB8DCEDE7), Color(0xE8FFFFFF), Color(0xB8DCEDE7)],
          ),
        ),
      ),
    );
    return Semantics(
      label: 'Revisando foto',
      liveRegion: true,
      child: IgnorePointer(child: widget.circular ? ClipOval(child: shimmer) : shimmer),
    );
  }
}

Future<void> showPhotoViewer(BuildContext context, String? url, {required String title, VoidCallback? onChange, bool circular = false}) async {
  if (url == null || url.isEmpty) {
    onChange?.call();
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (dialog) => Dialog.fullscreen(
      backgroundColor: const Color(0xFF101B19),
      child: SafeArea(
        child: Column(children: [
          Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Cerrar foto',
                onPressed: () => Navigator.of(dialog).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              )),
          Expanded(child: Center(child: circular
              ? LayoutBuilder(builder: (context, bounds) {
                  final size = (MediaQuery.sizeOf(context).width - 48).clamp(120.0, bounds.maxHeight - 24);
                  return Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4)),
                    child: ClipOval(child: NexoImage(url, fit: BoxFit.cover)),
                  );
                })
              : InteractiveViewer(minScale: 1, maxScale: 4, child: NexoImage(url, fit: BoxFit.contain)))),
          if (onChange != null)
            Padding(
              padding: const EdgeInsets.all(20),
              child: NexoButton(
                  label: title,
                  icon: 'camera',
                  onPressed: () {
                    Navigator.of(dialog).pop();
                    onChange();
                  }),
            ),
        ]),
      ),
    ),
  );
}
