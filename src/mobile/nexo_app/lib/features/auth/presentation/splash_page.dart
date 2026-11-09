import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/widgets/nexo_logo.dart';

/// Mientras se lee la sesión guardada.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-.35, -1),
              end: Alignment(.35, 1),
              colors: [NexoColors.welcomeTop, NexoColors.welcomeMid, NexoColors.welcomeBottom],
              stops: [0, .7, 1],
            ),
          ),
          alignment: Alignment.center,
          child: Semantics(
            label: 'Nexo Local, cargando',
            child: SizedBox(
              width: 136,
              height: 85,
              child: CustomPaint(painter: NexoRingsPainter()),
            ),
          ),
        ),
      ),
    );
  }
}
