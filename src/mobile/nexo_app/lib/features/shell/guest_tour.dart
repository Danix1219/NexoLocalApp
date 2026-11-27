import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../core/auth/session_controller.dart';
import '../../core/widgets/nexo_button.dart';
import '../../core/widgets/nexo_icon.dart';
import '../../data/api_provider.dart';
import 'top_bar.dart';

/// Elementos reales de Inicio que la guía señala. Solo se asignan a visitantes.
class TourAnchors {
  TourAnchors._();
  static final location = GlobalKey(debugLabel: 'guia-ubicacion');
  static final search = GlobalKey(debugLabel: 'guia-buscador');
  static final works = GlobalKey(debugLabel: 'guia-trabajos');
  static final firstWork = GlobalKey(debugLabel: 'guia-primer-trabajo');

  /// Perfil de quien publicó el primer trabajo visible.
  static String? firstProviderId;
}

/// Paso actual de la guía de exploración; `null` cuando no se muestra. Empieza
/// cada vez que se entra a «Explorar sin cuenta».
class GuestTour extends Notifier<int?> {
  @override
  int? build() => ref.watch(sessionProvider.select((s) => s.isGuest)) ? 0 : null;

  void next() {
    final step = state;
    if (step != null) state = step + 1 >= kTourSteps.length ? null : step + 1;
  }

  void back() {
    final step = state;
    if (step != null && step > 0) state = step - 1;
  }

  void finish() => state = null;
}

final guestTourProvider = NotifierProvider<GuestTour, int?>(GuestTour.new);

class TourStep {
  const TourStep(this.icon, this.title, this.text, this.action, this.hint);
  final String icon, title, text, action, hint;
}

/// Pasos y textos de la maqueta V1.00.002 («guía contextual para explorar sin
/// cuenta»).
const kTourSteps = [
  TourStep(
    'pin',
    'Primero, elige dónde buscar',
    'Toca tu zona para abrir el mapa y elegir hasta qué distancia buscar.',
    'Elegir ubicación',
    'Toca tu zona',
  ),
  TourStep(
    'search',
    'Busca lo que necesitas',
    'Escribe con tus palabras o usa los filtros. Todo se calcula para la zona que elegiste.',
    'Siguiente',
    'Aquí buscas',
  ),
  TourStep(
    'image',
    'Trabajos reales de tu zona',
    'Mira lo que hacen los prestadores cerca de ti, con fotos y recomendaciones.',
    'Siguiente',
    'Mira los trabajos',
  ),
  TourStep(
    'user',
    'Explora antes de decidir',
    'Toca el nombre para ver su perfil. Para contactar, comparar o guardar te pediremos una cuenta gratis.',
    'Listo, explorar',
    'Toca el nombre',
  ),
];

/// Capa que atenúa la pantalla, ilumina el elemento del paso y explica qué
/// hacer. Tocar lo iluminado hace lo mismo que el botón principal.
class GuestTourOverlay extends ConsumerStatefulWidget {
  const GuestTourOverlay({super.key, required this.step});
  final int step;

  @override
  ConsumerState<GuestTourOverlay> createState() => _GuestTourOverlayState();
}

class _GuestTourOverlayState extends ConsumerState<GuestTourOverlay> with TickerProviderStateMixin {
  /// Sigue al elemento mientras la lista se acomoda.
  late final _follow = AnimationController(vsync: this, duration: const Duration(milliseconds: 650))
    ..addListener(_measureSoon);

  /// Llama la atención sobre lo iluminado; se repite pocas veces.
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  int _pulses = 0;
  Rect? _target;
  bool _opening = false;
  bool _measuring = false;

  @override
  void initState() {
    super.initState();
    _pulse.addStatusListener((status) {
      if (status == AnimationStatus.completed && ++_pulses < 3) _pulse.forward(from: 0);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _enterStep());
  }

  @override
  void didUpdateWidget(GuestTourOverlay old) {
    super.didUpdateWidget(old);
    if (old.step != widget.step) WidgetsBinding.instance.addPostFrameCallback((_) => _enterStep());
  }

  @override
  void dispose() {
    _follow.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _attention() {
    if (!mounted || MediaQuery.disableAnimationsOf(context)) return;
    _pulses = 0;
    _pulse.forward(from: 0);
  }

  void _enterStep() {
    if (!mounted) return;
    final anchor = widget.step >= 2 ? TourAnchors.works.currentContext : null;
    if (anchor != null) {
      // Los trabajos se acercan arriba para que quepan junto a la explicación.
      unawaited(Scrollable.ensureVisible(anchor, alignment: 0, duration: const Duration(milliseconds: 360)));
    }
    _follow.forward(from: 0);
    _attention();
    _measureSoon();
  }

  void _measureSoon() {
    if (_measuring) return;
    _measuring = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measuring = false;
      if (!mounted) return;
      final next = _measure();
      if (next != _target) setState(() => _target = next);
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  Rect? _rectOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    final origin = context.findRenderObject();
    if (box is! RenderBox || origin is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero, ancestor: origin) & box.size;
  }

  Rect? _measure() {
    Rect? rect;
    switch (widget.step) {
      case 0:
        rect = _rectOf(TourAnchors.location)?.inflate(5);
      case 1:
        final search = _rectOf(TourAnchors.search);
        rect = search == null
            ? null
            : Rect.fromLTRB(search.left + 8, search.top + 4, search.right - 8, search.bottom + 4);
      case 2:
        final title = _rectOf(TourAnchors.works);
        final work = _rectOf(TourAnchors.firstWork);
        if (title != null) {
          final bottom = math.min((work ?? title).bottom, title.top + 270);
          rect = Rect.fromLTRB(title.left + 6, title.top, title.right - 6, bottom);
        }
      default:
        final work = _rectOf(TourAnchors.firstWork);
        // Solo la cabecera: ahí está el nombre que abre el perfil.
        if (work != null) rect = Rect.fromLTRB(work.left + 6, work.top + 2, work.right - 6, work.top + 70);
    }
    if (rect == null) return null;
    final size = (context.findRenderObject()! as RenderBox).size;
    final clipped = rect.intersect(Offset.zero & size);
    return clipped.width > 20 && clipped.height > 20 ? clipped : null;
  }

  Future<void> _activate() async {
    if (_opening) return;
    unawaited(HapticFeedback.selectionClick());
    final tour = ref.read(guestTourProvider.notifier);
    switch (widget.step) {
      case 0:
        _opening = true;
        final picked = await openSearchLocation(context, ref, intro: true);
        _opening = false;
        if (picked && mounted) tour.next();
      case 3:
        tour.finish();
      default:
        tour.next();
    }
  }

  /// En el último paso, tocar el nombre abre de verdad ese perfil.
  void _tapTarget() {
    final id = widget.step == 3 ? TourAnchors.firstProviderId : null;
    if (id == null) {
      _activate();
      return;
    }
    final router = GoRouter.of(context);
    ref.read(guestTourProvider.notifier).finish();
    router.push(Routes.provider(id));
  }

  @override
  Widget build(BuildContext context) {
    // Cuando llegan los trabajos cambia lo que hay que señalar.
    ref.listen(feedProvider, (_, __) => _follow.forward(from: 0));
    final step = kTourSteps[widget.step];
    final reduced = MediaQuery.disableAnimationsOf(context);
    final padding = MediaQuery.paddingOf(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final tour = ref.read(guestTourProvider.notifier);
        widget.step > 0 ? tour.back() : tour.finish();
      },
      child: Material(
        type: MaterialType.transparency,
        child: LayoutBuilder(
          builder: (context, box) {
            final target = _target;
            // La explicación se coloca donde no tape lo señalado.
            final cardOnTop = target != null && target.center.dy > box.maxHeight * .55;
            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) => target?.contains(details.localPosition) == true ? _tapTarget() : _attention(),
                    // Sin nada que señalar todavía, solo se atenúa la pantalla.
                    child: target == null
                        ? const CustomPaint(painter: _Spotlight(null, 0))
                        : TweenAnimationBuilder<Rect?>(
                            tween: RectTween(end: target),
                            duration: reduced ? Duration.zero : const Duration(milliseconds: 380),
                            curve: Curves.easeInOutCubic,
                            builder: (_, rect, __) => AnimatedBuilder(
                              animation: _pulse,
                              builder: (_, __) => CustomPaint(painter: _Spotlight(rect, _pulse.value)),
                            ),
                          ),
                  ),
                ),
                if (target != null) _hint(step.hint, target, box.biggest),
                AnimatedAlign(
                  duration: reduced ? Duration.zero : const Duration(milliseconds: 380),
                  curve: Curves.easeInOutCubic,
                  alignment: cardOnTop ? Alignment.topCenter : Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(14, padding.top + 14, 14, padding.bottom + 86),
                    child: _card(step, reduced),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _hint(String text, Rect target, Size screen) {
    final below = target.bottom + 52 < screen.height;
    final right = target.center.dx > screen.width / 2;
    return Positioned(
      top: below ? target.bottom + 10 : target.top - 42,
      left: right ? null : math.max(14, target.left),
      right: right ? math.max(14, screen.width - target.right) : null,
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: Container(
            padding: const EdgeInsets.fromLTRB(11, 7, 13, 7),
            decoration: BoxDecoration(
              color: NexoColors.logoAmber,
              borderRadius: BorderRadius.circular(99),
              boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 12, offset: Offset(0, 4))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  below ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  size: 16,
                  color: NexoColors.ink,
                ),
                const SizedBox(width: 6),
                Text(text, style: NexoText.body(12.5, weight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(TourStep step, bool reduced) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: Semantics(
      container: true,
      liveRegion: true,
      label: 'Guía de exploración, paso ${widget.step + 1} de ${kTourSteps.length}',
      child: GestureDetector(
        // También se avanza y retrocede deslizando la tarjeta.
        onHorizontalDragEnd: (details) {
          final speed = details.primaryVelocity ?? 0;
          final tour = ref.read(guestTourProvider.notifier);
          if (speed < -250 && widget.step > 0 && widget.step < kTourSteps.length - 1) tour.next();
          if (speed > 250) tour.back();
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
          decoration: BoxDecoration(
            color: NexoColors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [BoxShadow(color: Color(0x4A0D1F1B), blurRadius: 40, offset: Offset(0, 16))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  for (var i = 0; i < kTourSteps.length; i++)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        height: 5,
                        margin: EdgeInsets.only(right: i == kTourSteps.length - 1 ? 0 : 5),
                        decoration: BoxDecoration(
                          color: i <= widget.step ? NexoColors.brand : NexoColors.surface2,
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: reduced ? Duration.zero : const Duration(milliseconds: 260),
                layoutBuilder: (current, previous) =>
                    Stack(alignment: Alignment.topCenter, children: [...previous, if (current != null) current]),
                child: Row(
                  key: ValueKey(widget.step),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: NexoColors.brandSoft, borderRadius: BorderRadius.circular(15)),
                      child: NexoIcon(step.icon, size: 22, color: NexoColors.brand),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PASO ${widget.step + 1} DE ${kTourSteps.length}',
                            style: NexoText.body(
                              11,
                              weight: FontWeight.w800,
                              color: NexoColors.brand,
                              letterSpacing: .8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(step.title, style: NexoText.display(17.5, height: 1.2)),
                          const SizedBox(height: 4),
                          Text(step.text, style: NexoText.body(13.5, color: NexoColors.muted, height: 1.45)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  TextButton(
                    onPressed: () => ref.read(guestTourProvider.notifier).finish(),
                    style: TextButton.styleFrom(
                      foregroundColor: NexoColors.muted,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: const Text('Omitir guía'),
                  ),
                  const SizedBox(width: 6),
                  if (widget.step > 0)
                    IconButton(
                      tooltip: 'Paso anterior',
                      onPressed: () => ref.read(guestTourProvider.notifier).back(),
                      icon: const Icon(Icons.arrow_back_rounded, color: NexoColors.ink),
                    ),
                  const SizedBox(width: 4),
                  // El botón principal ocupa el resto: no se desborda con letra grande.
                  Expanded(
                    child: NexoButton(label: step.action, small: true, onPressed: _activate),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Spotlight extends CustomPainter {
  const _Spotlight(this.rect, this.pulse);
  final Rect? rect;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final dim = Paint()..color = const Color(0x99101C19);
    final screen = Path()..addRect(Offset.zero & size);
    final target = rect;
    if (target == null) {
      canvas.drawPath(screen, dim);
      return;
    }
    final hole = RRect.fromRectAndRadius(target, const Radius.circular(18));
    canvas.drawPath(Path.combine(PathOperation.difference, screen, Path()..addRRect(hole)), dim);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = NexoColors.accent2;
    canvas.drawRRect(hole, line);
    if (pulse > 0 && pulse < 1) {
      canvas.drawRRect(
        hole.inflate(12 * pulse),
        line
          ..strokeWidth = 2.5
          ..color = NexoColors.accent2.withValues(alpha: 1 - pulse),
      );
    }
  }

  @override
  bool shouldRepaint(_Spotlight old) => old.rect != rect || old.pulse != pulse;
}
