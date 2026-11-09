import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';

/// Los dos aros entrelazados del logo (viewBox 64×40 de la bienvenida).
/// [t] va de 0 a 1: los aros se acercan desde los lados y aparecen.
class NexoRingsPainter extends CustomPainter {
  NexoRingsPainter({
    this.t = 1,
    this.left = Colors.white,
    this.right = NexoColors.logoAmber,
  });

  final double t;
  final Color left;
  final Color right;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 64;
    final slide = 14 * (1 - t);
    Paint ring(Color c) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 * s
      ..color = c.withValues(alpha: c.a * t);
    canvas.drawCircle(Offset(23 * s - slide, 20 * s), 14 * s, ring(left));
    canvas.drawCircle(Offset(41 * s + slide, 20 * s), 14 * s, ring(right));
  }

  @override
  bool shouldRepaint(NexoRingsPainter old) => old.t != t || old.left != left || old.right != right;
}

/// Logo pequeño de la barra superior (viewBox 32×32, aros de radio 7).
class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 32;
    Paint ring(Color c) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * s
      ..color = c;
    canvas.drawCircle(Offset(11 * s, 16 * s), 7 * s, ring(NexoColors.ink));
    canvas.drawCircle(Offset(21 * s, 16 * s), 7 * s, ring(NexoColors.accent));
  }

  @override
  bool shouldRepaint(_MarkPainter old) => false;
}

/// "nexo" en negritas + "local" ligero, como en la maqueta.
class NexoWordmark extends StatelessWidget {
  const NexoWordmark({
    super.key,
    this.size = 19,
    this.nexoColor = NexoColors.ink,
    this.localColor = NexoColors.brand,
  });

  final double size;
  final Color nexoColor;
  final Color localColor;

  @override
  Widget build(BuildContext context) {
    final ls = -0.045 * size;
    return Text.rich(
      TextSpan(children: [
        TextSpan(
          text: 'nexo',
          style: NexoText.display(size, color: nexoColor, letterSpacing: ls),
        ),
        TextSpan(
          text: 'local',
          style: NexoText.display(size, weight: FontWeight.w500, color: localColor, letterSpacing: ls),
        ),
      ]),
      semanticsLabel: 'Nexo Local',
    );
  }
}

class NexoLogo extends StatelessWidget {
  const NexoLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 25, height: 25, child: CustomPaint(painter: _MarkPainter())),
        const SizedBox(width: 7),
        const NexoWordmark(),
      ],
    );
  }
}
