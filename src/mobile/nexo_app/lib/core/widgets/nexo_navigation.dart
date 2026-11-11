import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import 'nexo_icon.dart';
import 'nexo_motion.dart';

/// Final .navbar/.nav-icon styles of the reference prototype.
class NexoNavigation extends StatelessWidget {
  const NexoNavigation({super.key, required this.current, this.unread = 0, this.onSelected});
  final int current;
  final int unread;
  final ValueChanged<int>? onSelected;
  static const destinations = [
    ('home', 'Inicio', '/home'),
    ('search', 'Buscar', '/search'),
    ('plus', 'Publicar', '/publish'),
    ('chat', 'Mensajes', '/inbox'),
    ('user', 'Cuenta', '/account'),
  ];
  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
            color: NexoColors.surface,
            border: Border(top: BorderSide(color: NexoColors.line)),
            boxShadow: [BoxShadow(color: Color(0x121F302B), blurRadius: 20, offset: Offset(0, -5))]),
        child: SafeArea(
          top: false,
          child: Padding(
              padding: const EdgeInsets.fromLTRB(7, 7, 7, 12),
              child: Row(children: [
                for (var i = 0; i < destinations.length; i++)
                  Expanded(
                    child: NexoPressFeedback(
                        child: Semantics(
                      button: true,
                      selected: current == i,
                      label: i == 3 && unread > 0 ? 'Mensajes, $unread sin leer' : destinations[i].$2,
                      excludeSemantics: true,
                      onTap: () => onSelected != null ? onSelected!(i) : context.go(destinations[i].$3),
                      child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(13),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(13),
                            onTap: () => onSelected != null ? onSelected!(i) : context.go(destinations[i].$3),
                            child: ConstrainedBox(
                                constraints: const BoxConstraints(minHeight: 56),
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Stack(clipBehavior: Clip.none, children: [
                                        AnimatedContainer(
                                            duration: NexoMotion.duration(context, NexoMotion.press),
                                            width: 38,
                                            height: 30,
                                            decoration: BoxDecoration(
                                                color: current == i ? NexoColors.brandSoft : Colors.transparent,
                                                borderRadius: BorderRadius.circular(11)),
                                            alignment: Alignment.center,
                                            child: NexoIcon(destinations[i].$1,
                                                size: 21,
                                                strokeWidth: 1.9,
                                                color: current == i ? NexoColors.brandDeep : NexoColors.muted)),
                                        if (i == 3 && unread > 0)
                                          Positioned(
                                              top: -4,
                                              right: -4,
                                              child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 5),
                                                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                                  decoration: BoxDecoration(
                                                      color: NexoColors.danger,
                                                      borderRadius: BorderRadius.circular(99),
                                                      border: Border.all(color: NexoColors.surface)),
                                                  alignment: Alignment.center,
                                                  child: Text(unread > 99 ? '99+' : '$unread',
                                                      style: NexoText.body(10,
                                                          color: Colors.white, weight: FontWeight.w800))))
                                      ]),
                                      const SizedBox(height: 2),
                                      Text(destinations[i].$2,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: NexoText.body(10.5,
                                              color: current == i ? NexoColors.brandDeep : NexoColors.muted,
                                              weight: current == i ? FontWeight.w800 : FontWeight.w600)),
                                    ])),
                          )),
                    )),
                  )
              ])),
        ),
      );
}
