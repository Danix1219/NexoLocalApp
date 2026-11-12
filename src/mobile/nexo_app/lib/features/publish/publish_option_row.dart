import 'package:flutter/material.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../core/widgets/nexo_icon.dart';

/// Shared columns keep all selected values aligned, independently of their length.
class PublishOptionRow extends StatelessWidget {
  const PublishOptionRow(
      {super.key,
      required this.icon,
      required this.label,
      required this.value,
      required this.onTap,
      this.empty = false});
  final String icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool empty;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '$label: $value',
        child: InkWell(
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 62),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: NexoColors.line))),
              child: Row(children: [
                Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: NexoColors.brandSoft, borderRadius: BorderRadius.circular(11)),
                    child: Center(child: NexoIcon(icon, size: 18, color: NexoColors.brand))),
                const SizedBox(width: 12),
                Expanded(
                    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Expanded(flex: 5, child: Text(label, style: NexoText.body(14, weight: FontWeight.w700))),
                  const SizedBox(width: 12),
                  Expanded(
                      flex: 5,
                      child: Text(value,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.left,
                          style: NexoText.body(13.5,
                              weight: empty ? FontWeight.w700 : FontWeight.w500,
                              color: empty ? NexoColors.accent : NexoColors.brandDeep))),
                ])),
                const SizedBox(width: 10),
                const NexoIcon('chevron', size: 16, color: NexoColors.muted),
              ]),
            )),
      );
}
