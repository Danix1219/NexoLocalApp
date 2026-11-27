import 'package:flutter/material.dart';
import '../../app/theme/tokens.dart';

enum NexoSkeletonKind { feed, account, profile, messages, chat, providers, requests, order, form, notifications }

/// Content-shaped placeholders, excluded from interaction and screen readers.
class ContentSkeleton extends StatefulWidget {
  const ContentSkeleton({super.key, this.kind = NexoSkeletonKind.feed});
  final NexoSkeletonKind kind;
  @override
  State<ContentSkeleton> createState() => _ContentSkeletonState();
}

class _ContentSkeletonState extends State<ContentSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) || !TickerMode.of(context)) {
      _pulse.stop();
      _pulse.value = .5;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Widget block({double height = 12, double? width, bool circle = false}) => Container(
    height: height,
    width: width,
    decoration: BoxDecoration(color: NexoColors.surface2, borderRadius: BorderRadius.circular(circle ? height : 8)),
  );
  Widget line(double fraction) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: FractionallySizedBox(widthFactor: fraction, alignment: Alignment.centerLeft, child: block()),
  );
  Widget identity() => Row(
    children: [
      block(height: 44, width: 44, circle: true),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [line(.65), line(.4)]),
      ),
    ],
  );
  Widget card(List<Widget> children) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: NexoColors.surface, borderRadius: BorderRadius.circular(18)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
  );
  List<Widget> content() {
    switch (widget.kind) {
      case NexoSkeletonKind.account:
        return [
          card([identity()]),
          for (var i = 0; i < 3; i++) card([line(.4), const SizedBox(height: 12), block(height: 44), line(.7)]),
        ];
      case NexoSkeletonKind.profile:
        return [
          card([
            block(height: 148),
            const SizedBox(height: 16),
            identity(),
            line(.85),
            line(.6),
            const SizedBox(height: 18),
            block(height: 44),
          ]),
          card([line(.4), line(.95), line(.8)]),
          card([block(height: 140)]),
        ];
      case NexoSkeletonKind.messages:
      case NexoSkeletonKind.notifications:
        return [
          for (var i = 0; i < 5; i++) card([identity(), line(.85)]),
        ];
      case NexoSkeletonKind.chat:
        return [
          for (var i = 0; i < 6; i++)
            Align(
              alignment: i.isEven ? Alignment.centerLeft : Alignment.centerRight,
              child: FractionallySizedBox(widthFactor: i % 3 == 0 ? .55 : .75, child: card([line(.85), line(.6)])),
            ),
        ];
      case NexoSkeletonKind.providers:
        return [
          for (var i = 0; i < 3; i++)
            card([identity(), line(.9), line(.65), const SizedBox(height: 14), block(height: 32)]),
        ];
      case NexoSkeletonKind.order:
        return [
          card([line(.5), line(.8), const SizedBox(height: 18), identity()]),
          card([line(.4), line(.95), line(.8), const SizedBox(height: 16), block(height: 100)]),
          card([line(.7), line(.55), line(.8)]),
        ];
      case NexoSkeletonKind.form:
        return [
          card([
            line(.55),
            for (var i = 0; i < 3; i++) ...[
              const SizedBox(height: 20),
              line(.35),
              const SizedBox(height: 8),
              block(height: 48),
            ],
          ]),
        ];
      case NexoSkeletonKind.requests:
        return [
          for (var i = 0; i < 3; i++)
            card([identity(), line(.9), line(.75), line(.45), const SizedBox(height: 16), block(height: 32)]),
        ];
      case NexoSkeletonKind.feed:
        return [
          for (var i = 0; i < 2; i++)
            card([
              identity(),
              const SizedBox(height: 16),
              block(height: 170),
              line(.85),
              line(.55),
              const SizedBox(height: 14),
              block(height: 28),
            ]),
        ];
    }
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Cargando contenido',
    container: true,
    child: ExcludeSemantics(
      child: IgnorePointer(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AnimatedBuilder(
            animation: _pulse,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final body = Column(mainAxisSize: MainAxisSize.min, children: content());
                return constraints.hasBoundedHeight ? SingleChildScrollView(child: body) : body;
              },
            ),
            builder: (context, child) => Opacity(opacity: .55 + _pulse.value * .35, child: child),
          ),
        ),
      ),
    ),
  );
}
