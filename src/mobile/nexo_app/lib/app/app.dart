import 'package:flutter/services.dart';
import '../core/auth/session_controller.dart';
import '../data/api_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/local/sync_controller.dart';
import '../core/widgets/toast.dart';
import '../features/push/push_controller.dart';
import 'router.dart';
import 'theme/theme.dart';

final appLinksProvider = Provider<void>((ref) {
  const links = MethodChannel('mx.nexolocal/links');
  var disposed = false;
  String? pending;
  void open(String? link) {
    if (disposed) return;
    final path = Routes.fromDeepLink(link);
    if (path == null) return;
    final session = ref.read(sessionProvider);
    if (session.status == SessionStatus.unknown || !session.isSignedIn && session.status != SessionStatus.guest) {
      pending = path;
      return;
    }
    ref.read(routerProvider).go(path);
  }

  links.setMethodCallHandler((call) async {
    if (call.method == 'open') open(call.arguments as String?);
  });
  links.invokeMethod<String>('initial').then(open).catchError((Object _) {});
  ref.listen(sessionProvider.select((s) => s.status), (_, status) {
    if (pending != null && [SessionStatus.signedIn, SessionStatus.guest].contains(status)) {
      final path = pending;
      pending = null;
      Future.microtask(() => open(path));
    }
  });
  ref.onDispose(() {
    disposed = true;
    links.setMethodCallHandler(null);
  });
});

class NexoApp extends ConsumerWidget {
  const NexoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Servicios de toda la app: push (spec 050) y sincronización (spec 051).
    ref.watch(appLinksProvider);
    ref.watch(pushProvider);
    ref.watch(privateChatBootstrapProvider);
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
