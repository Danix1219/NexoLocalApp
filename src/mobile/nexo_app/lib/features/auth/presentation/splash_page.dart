import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/widgets/nexo_logo.dart';

/// Tiempo mínimo en pantalla para que la animación se vea completa. La sesión
/// se lee en paralelo; si tarda más, el logo espera.
const kSplashDuration = Duration(milliseconds: 1550);

/// Pasa a `true` cuando la presentación terminó; el router espera esta señal.
class SplashGate extends Notifier<bool> {
  @override
  bool build() => false;
  void open() => state = true;
}

final splashDoneProvider = NotifierProvider<SplashGate, bool>(SplashGate.new);

/// Mientras se lee la sesión guardada: solo el logo, en un único movimiento
/// continuo. Sin sesión viaja hasta el lugar que ocupa en la bienvenida, donde
/// la animación propia de esa pantalla toma el relevo con un fundido; con
/// sesión se acerca y se desvanece hacia el inicio.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  static const logoWidth = 136.0;

  /// Ancho de los aros en la bienvenida.
  static double welcomeLogoWidth(MediaQueryData media) => media.size.height < 760 ? 136 : 168;

  /// Altura (centro) de los aros en la bienvenida: el centro del espacio libre
  /// sobre su panel inferior, menos la mitad de lo que ocupan nombre y margen.
  static double welcomeLogoCenterY(MediaQueryData media) {
    final compact = media.size.height < 760;
    final sheet = media.size.height * (compact ? .44 : .46);
    return (media.padding.top + media.size.height - sheet) / 2 - (compact ? 35.5 : 41.5);
  }

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> with SingleTickerProviderStateMixin {
  late final _motion = AnimationController(vsync: this, duration: const Duration(milliseconds: 1450));
  Timer? _hold;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hold != null || ref.read(splashDoneProvider)) return;
    final reduced = MediaQuery.of(context).disableAnimations;
    _hold = Timer(reduced ? Duration.zero : kSplashDuration, () {
      if (mounted) ref.read(splashDoneProvider.notifier).open();
    });
    if (reduced) return;
    // Tras el primer cuadro: el arranque de la app no se come el comienzo.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _motion.forward();
    });
  }

  @override
  void dispose() {
    _hold?.cancel();
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final reduced = media.disableAnimations;
    final status = ref.watch(sessionProvider.select((s) => s.status));
    const appear = Interval(0, .42, curve: Curves.easeOutCubic);
    // Empieza antes de que termine la aparición: nunca se detiene a medias.
    const travel = Interval(.28, 1, curve: Curves.easeInOutCubic);
    const leave = Interval(.62, 1, curve: Curves.easeIn);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: NexoColors.welcomeMid,
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
            child: AnimatedBuilder(
              animation: _motion,
              // El dibujo no se repinta: cada cuadro solo lo mueve y escala.
              child: RepaintBoundary(
                child: SizedBox(
                  width: SplashPage.logoWidth,
                  height: SplashPage.logoWidth * 40 / 64,
                  child: CustomPaint(painter: NexoRingsPainter()),
                ),
              ),
              builder: (_, child) {
                final t = reduced ? 0.0 : _motion.value;
                final shown = reduced ? 1.0 : appear.transform(t);
                final go = travel.transform(t);
                var opacity = shown;
                var scale = .9 + .1 * shown;
                var lift = 0.0;
                if (status == SessionStatus.signedOut) {
                  scale *= 1 + (SplashPage.welcomeLogoWidth(media) / SplashPage.logoWidth - 1) * go;
                  lift = (SplashPage.welcomeLogoCenterY(media) - media.size.height / 2) * go;
                } else if (status != SessionStatus.unknown) {
                  scale *= 1 + .16 * go;
                  if (!reduced) opacity *= 1 - leave.transform(t);
                }
                return Transform.translate(
                  offset: Offset(0, lift),
                  child: Transform.scale(
                    scale: scale,
                    child: Opacity(opacity: opacity.clamp(0.0, 1.0), child: child),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
