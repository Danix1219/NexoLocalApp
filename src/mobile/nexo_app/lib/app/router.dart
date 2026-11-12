import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/session_controller.dart';
import '../features/account/account_page.dart';
import '../features/account/my_profile_page.dart';
import '../data/models.dart' show AccountScreen, ServiceRequest;
import '../features/account/saved_page.dart';
import '../features/auth/application/email_flow.dart';
import '../features/auth/presentation/code_page.dart';
import '../features/auth/presentation/forgot_page.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/new_password_page.dart';
import '../features/auth/presentation/password_done_page.dart';
import '../features/auth/presentation/register_account_page.dart';
import '../features/auth/presentation/register_done_page.dart';
import '../features/auth/presentation/register_email_page.dart';
import '../features/auth/presentation/splash_page.dart';
import '../features/auth/presentation/welcome_page.dart';
import '../features/home/home_page.dart';
import '../features/location/location_picker_page.dart';
import '../features/messages/chat_page.dart';
import '../features/messages/inbox_page.dart';
import '../features/onboarding/provider_onboarding_page.dart';
import '../features/orders/order_page.dart';
import '../features/provider/compare_page.dart';
import '../features/provider/provider_page.dart';
import '../features/publish/publish_page.dart';
import '../features/requests/interested_page.dart';
import '../features/requests/request_author_page.dart';
import '../features/search/search_page.dart';
import '../features/shell/shell_page.dart';

class Routes {
  Routes._();
  static const splash = '/splash';
  static const welcome = '/';
  static const login = '/login';
  static const forgot = '/forgot';
  static const forgotCode = '/forgot/code';
  static const forgotNew = '/forgot/new';
  static const forgotDone = '/forgot/done';
  static const registerEmail = '/register/email';
  static const registerCode = '/register/code';
  static const registerAccount = '/register/account';
  static const registerDone = '/register/done';

  // App (barra inferior)
  static const home = '/home';
  static const search = '/search';
  static const publish = '/publish';
  static const inbox = '/inbox';
  static const account = '/account';

  // Subpantallas
  static String provider(String id) => '/provider/$id';
  static const compare = '/compare';
  static String interested(String requestId) => '/requests/$requestId/interested';
  static String requestAuthor(String requestId) => '/requests/$requestId/author';
  static String order(String id) => '/orders/$id';
  static String chat(String id) => '/chat/$id';
  static const saved = '/saved';
  static const myProfile = '/my-profile';
  static const proOnboarding = '/pro/new';
  static const location = '/location';

  /// Rutas del flujo de entrada (sin sesión).
  static const authPaths = {
    welcome,
    login,
    forgot,
    forgotCode,
    forgotNew,
    forgotDone,
    registerEmail,
    registerCode,
    registerAccount,
  };

  /// Secciones a las que puede llevar un aviso o enlace (spec 043/046).
  static const deepLinkSections = {'orders', 'requests', 'chat', 'provider', 'saved'};

  /// `nexolocal://orders/123` → `/orders/123`. Solo acepta el esquema propio
  /// (o una ruta interna) hacia secciones conocidas; cualquier otra cosa
  /// (https://…, rutas con `..`, caracteres raros) se ignora.
  static String? fromDeepLink(String? link) {
    if (link == null || link.isEmpty || link.length > 200) return null;
    String path;
    if (link.startsWith('nexolocal://')) {
      path = '/${link.substring('nexolocal://'.length)}';
    } else if (link.startsWith('/') && !link.startsWith('//')) {
      path = link;
    } else {
      return null;
    }
    final parts = path.substring(1).split('/');
    if (parts.isEmpty || !deepLinkSections.contains(parts.first)) return null;
    if (parts.any((p) => p.isEmpty || p == '.' || p == '..' || !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(p))) return null;
    return path;
  }
}

/// Avisa a go_router cuando cambia la sesión para re-evaluar redirect.
class _SessionRefresh extends ChangeNotifier {
  _SessionRefresh(Ref ref) {
    ref.listen<SessionState>(sessionProvider, (_, __) => notifyListeners());
    ref.listen(signupFlowProvider.select((s) => s.createdName), (_, __) => notifyListeners());
  }
}

final _rootKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _SessionRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final status = ref.read(sessionProvider).status;
      final loc = state.matchedLocation;

      if (status == SessionStatus.unknown) {
        return loc == Routes.splash ? null : Routes.splash;
      }
      final signedIn = status == SessionStatus.signedIn;
      final guest = status == SessionStatus.guest;
      if (loc == Routes.splash) return signedIn || guest ? Routes.home : Routes.welcome;

      if (signedIn) {
        if (ref.read(sessionProvider).recoveryOnly && loc != Routes.account) return Routes.account;
        // The successful account remains visible until the user continues.
        if (ref.read(signupFlowProvider).createdName != null && loc != Routes.registerDone) return Routes.registerDone;
        if (Routes.authPaths.contains(loc)) return Routes.home;
        return null;
      }
      if (guest) return loc == Routes.registerDone ? Routes.home : null;
      // El registro permite elegir ubicacion antes de crear la cuenta.
      if (loc == Routes.location) return null;
      if (loc == Routes.registerDone && ref.read(signupFlowProvider).createdName != null) return null;
      // Sin sesión: solo el flujo de entrada.
      if (Routes.authPaths.contains(loc)) return null;
      return Routes.welcome;
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, __) => const SplashPage()),
      GoRoute(path: Routes.welcome, builder: (_, __) => const WelcomePage()),
      GoRoute(path: Routes.login, builder: (_, s) => LoginPage(initialEmail: s.extra as String?)),
      GoRoute(path: Routes.forgot, builder: (_, s) => ForgotPage(initialEmail: s.extra as String?)),
      GoRoute(
        path: Routes.forgotCode,
        builder: (_, __) => const CodePage(purpose: EmailPurpose.resetPassword),
      ),
      GoRoute(path: Routes.forgotNew, builder: (_, __) => const NewPasswordPage()),
      GoRoute(path: Routes.forgotDone, builder: (_, s) => PasswordDonePage(email: s.extra as String?)),
      GoRoute(path: Routes.registerEmail, builder: (_, __) => const RegisterEmailPage()),
      GoRoute(path: Routes.registerCode, builder: (_, __) => const CodePage(purpose: EmailPurpose.signup)),
      GoRoute(path: Routes.registerAccount, builder: (_, __) => const RegisterAccountPage()),
      GoRoute(path: Routes.registerDone, builder: (_, __) => const RegisterDonePage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => ShellPage(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: Routes.home, builder: (_, __) => const HomePage())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.search, builder: (_, __) => const SearchPage())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.publish, builder: (_, __) => const PublishPage())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.inbox, builder: (_, __) => const InboxPage())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.account, builder: (_, __) => const AccountPage())]),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/provider/:id',
        builder: (_, s) => ProviderPage(id: s.pathParameters['id']!),
      ),
      GoRoute(parentNavigatorKey: _rootKey, path: Routes.compare, builder: (_, __) => const ComparePage()),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/requests/:id/author',
        builder: (_, s) => s.extra is ServiceRequest
            ? RequestAuthorPage(request: s.extra! as ServiceRequest)
            : const Scaffold(body: Center(child: Text('Abre el perfil desde una solicitud.'))),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/requests/:id/interested',
        builder: (_, s) => InterestedPage(requestId: s.pathParameters['id']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/orders/:id',
        builder: (_, s) => OrderPage(id: s.pathParameters['id']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/chat/:id',
        builder: (_, s) => ChatPage(id: s.pathParameters['id']!),
      ),
      GoRoute(parentNavigatorKey: _rootKey, path: Routes.saved, builder: (_, __) => const SavedPage()),
      GoRoute(
          parentNavigatorKey: _rootKey,
          path: Routes.myProfile,
          builder: (context, state) => MyProfilePage(
                initial: state.extra is AccountScreen ? state.extra as AccountScreen : const AccountScreen(name: ''),
                onEdit: (account) => showAccountEditSheet(context, account),
              )),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: Routes.proOnboarding,
        builder: (_, __) => const ProviderOnboardingPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: Routes.location,
        pageBuilder: (context, s) => CustomTransitionPage<LocationPick>(
          key: s.pageKey,
          opaque: false,
          barrierDismissible: true,
          barrierColor: const Color(0x660F201B),
          barrierLabel: 'Cerrar ubicación',
          transitionDuration: const Duration(milliseconds: 240),
          reverseTransitionDuration: const Duration(milliseconds: 180),
          transitionsBuilder: (context, animation, secondaryAnimation, child) => MediaQuery.disableAnimationsOf(context)
              ? child
              : SlideTransition(
                  position: Tween(begin: const Offset(0, 1), end: Offset.zero)
                      .chain(CurveTween(curve: Curves.easeOutCubic))
                      .animate(animation),
                  child: child,
                ),
          child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: .86,
                widthFactor: 1,
                child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    child: MediaQuery.removePadding(
                        context: context,
                        removeTop: true,
                        child: LocationPickerPage(args: s.extra as LocationPickerArgs? ?? const LocationPickerArgs()))),
              )),
        ),
      ),
    ],
  );
});

/// Para pruebas o depuración.
@visibleForTesting
const allRoutes = [
  Routes.splash,
  Routes.welcome,
  Routes.login,
  Routes.forgot,
  Routes.forgotCode,
  Routes.forgotNew,
  Routes.forgotDone,
  Routes.registerEmail,
  Routes.registerCode,
  Routes.registerAccount,
  Routes.registerDone,
  Routes.home,
  Routes.search,
  Routes.publish,
  Routes.inbox,
  Routes.account,
];
