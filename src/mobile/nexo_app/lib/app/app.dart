import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/local/sync_controller.dart';
import '../core/widgets/toast.dart';
import '../features/push/push_controller.dart';
import 'router.dart';
import 'theme/theme.dart';

class NexoApp extends ConsumerWidget {
  const NexoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Servicios de toda la app: push (spec 050) y sincronización (spec 051).
    ref.watch(pushProvider);
    ref.watch(syncProvider);
    return MaterialApp.router(
      title: 'Nexo Local',
      debugShowCheckedModeBanner: false,
      theme: buildNexoTheme(),
      scaffoldMessengerKey: rootMessengerKey,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
