import 'package:flutter/material.dart';

/// Timings measured from the deployed prototype's final CSS rules.
abstract final class NexoMotion {
  static const enter = Duration(milliseconds: 220);
  static const press = Duration(milliseconds: 140);
  static bool reduced(BuildContext context) => MediaQuery.disableAnimationsOf(context);
  static Duration duration(BuildContext context, Duration value) => reduced(context) ? Duration.zero : value;
}

/// Preserves the subtree (including drafts and scroll positions) when tabs change.
class NexoEnter extends StatefulWidget {
  const NexoEnter(
      {super.key,
      required this.child,
      this.trigger,
      this.duration = NexoMotion.enter,
      this.beginOpacity = .4,
      this.distance = 8});
  final Widget child;
  final Object? trigger;
  final Duration duration;
  final double beginOpacity;
  final double distance;
  @override
  State<NexoEnter> createState() => _NexoEnterState();
}

class _NexoEnterState extends State<NexoEnter> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: widget.duration);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (NexoMotion.reduced(context)) {
      _controller.value = 1;
    } else if (_controller.value == 0 && !_controller.isAnimating) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(NexoEnter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger) {
      if (NexoMotion.reduced(context)) {
        _controller.value = 1;
      } else {
        _controller.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (_, child) {
          final t = Curves.easeOut.transform(_controller.value);
          return Opacity(
              opacity: widget.beginOpacity + (1 - widget.beginOpacity) * t,
              child: Transform.translate(offset: Offset(0, widget.distance * (1 - t)), child: child));
        },
      );
}

/// Pointer feedback is visual only: InkWell retains keyboard, focus and semantics.
class NexoPressFeedback extends StatefulWidget {
  const NexoPressFeedback({super.key, required this.child, this.enabled = true});
  final Widget child;
  final bool enabled;
  @override
  State<NexoPressFeedback> createState() => _NexoPressFeedbackState();
}

class _NexoPressFeedbackState extends State<NexoPressFeedback> {
  bool _pressed = false;
  void _set(bool value) {
    if (_pressed != value && mounted) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: widget.enabled ? (_) => _set(true) : null,
        onPointerUp: (_) => _set(false),
        onPointerCancel: (_) => _set(false),
        child: AnimatedScale(
          scale: widget.enabled && _pressed && !NexoMotion.reduced(context) ? .98 : 1,
          duration: NexoMotion.duration(context, NexoMotion.press),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      );
}

class NexoPageTransitions extends PageTransitionsBuilder {
  const NexoPageTransitions();
  @override
  Duration get transitionDuration => NexoMotion.enter;
  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    if (NexoMotion.reduced(context)) return child;
    final curved = animation.drive(CurveTween(curve: Curves.easeOut));
    return FadeTransition(
        opacity: curved.drive(Tween(begin: .4, end: 1)),
        child: AnimatedBuilder(
            animation: curved,
            child: child,
            builder: (_, child) => Transform.translate(offset: Offset(0, 8 * (1 - curved.value)), child: child)));
  }
}
