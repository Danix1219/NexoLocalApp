import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/widgets/nexo_button.dart';
import '../../../core/widgets/nexo_icon.dart';
import '../../../core/widgets/nexo_logo.dart';
import 'signup_sheet.dart';

/// 7.1 Bienvenida (`welcome()`): logo de dos aros centrado sobre verde, nombre
/// debajo y hoja inferior con el titular y las tres acciones.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final compact = h < 760;
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
          child: Stack(
            children: [
              // Brillo verde de la esquina superior derecha (radial-gradient de .wv-top).
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(.7, -1),
                      radius: 1.1,
                      colors: [
                        NexoColors.welcomeGlow,
                        NexoColors.welcomeGlow.withValues(alpha: 0),
                      ],
                      stops: const [0, .6],
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  Expanded(
                    child: SafeArea(
                      bottom: false,
                      child: Center(child: _Hero(compact: compact)),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(minHeight: h * (compact ? .44 : .46)),
                    child: const _Sheet(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatefulWidget {
  const _Hero({required this.compact});
  final bool compact;

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // prefers-reduced-motion
    if (MediaQuery.of(context).disableAnimations) {
      _c.value = 1;
    } else if (!_c.isAnimating && _c.value == 0) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.compact ? 136.0 : 168.0;
    // Aros: 0.1–0.8 s; nombre: 0.35–0.95 s (como las animaciones CSS).
    final rings = CurvedAnimation(parent: _c, curve: const Interval(.1, .8, curve: Cubic(.2, .8, .2, 1)));
    final brand = CurvedAnimation(parent: _c, curve: const Interval(.35, .95, curve: Curves.easeOut));
    return Stack(
      alignment: Alignment.center,
      children: [
        // Halo ámbar detrás del logo.
        Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                NexoColors.logoAmber.withValues(alpha: .22),
                NexoColors.logoAmber.withValues(alpha: 0),
              ],
              stops: const [0, .65],
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: rings,
              builder: (_, __) => SizedBox(
                width: w,
                height: w * 40 / 64,
                child: CustomPaint(painter: NexoRingsPainter(t: rings.value)),
              ),
            ),
            const SizedBox(height: 14),
            AnimatedBuilder(
              animation: brand,
              builder: (_, child) => Opacity(
                opacity: brand.value,
                child: Transform.translate(offset: Offset(0, 10 * (1 - brand.value)), child: child),
              ),
              child: NexoWordmark(
                size: widget.compact ? 40 : 48,
                nexoColor: Colors.white,
                localColor: NexoColors.logoAmber,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet();

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 760;
    return Container(
      decoration: const BoxDecoration(
        color: NexoColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Color(0x2E031E1B), blurRadius: 30, offset: Offset(0, -10)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 34, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Encuentra a quien sabe hacerlo, cerca de ti.',
                  style: NexoText.display(compact ? 27 : 31, height: 1.08, letterSpacing: -0.045 * (compact ? 27 : 31)),
                ),
              ),
              const SizedBox(height: 22),
              NexoButton(
                label: 'Crear cuenta',
                onPressed: () => showSignupSheet(context),
              ),
              const SizedBox(height: 12),
              NexoButton(
                label: 'Iniciar sesión',
                variant: NexoButtonVariant.line,
                onPressed: () => context.push(Routes.login),
              ),
              const SizedBox(height: 12),
              Semantics(
                button: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  // Modo visitante (7.14): ve inicio y búsqueda sin cuenta.
                  onTap: () {
                    ProviderScope.containerOf(context).read(sessionProvider.notifier).enterGuest();
                    context.go(Routes.home);
                  },
                  child: SizedBox(
                    height: 48,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Explorar sin cuenta',
                            style: NexoText.body(14, weight: FontWeight.w800, color: NexoColors.brandDeep)),
                        const SizedBox(width: 5),
                        const NexoIcon('chevron', size: 17, color: NexoColors.brandDeep),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
