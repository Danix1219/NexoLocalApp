import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/api_provider.dart';
import 'ui.dart';

class CatalogStatus extends ConsumerWidget {
  const CatalogStatus({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);
    if (catalog.hasError) {
      return SizedBox(width: 280, child: ErrorView(catalog.error!, onRetry: () => ref.invalidate(catalogProvider)));
    }
    if (catalog.isLoading) return const SizedBox(width: 220, child: LinearProgressIndicator());
    return const SizedBox.shrink();
  }
}
