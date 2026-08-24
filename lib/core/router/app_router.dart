import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/home/presentation/home_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final GoRouter router = GoRouter(
    initialLocation: LoginScreen.routePath,
    redirect: (context, state) {
      final bool loggedIn =
          ref.read(authRepositoryProvider).currentSession != null;
      final String location = state.matchedLocation;
      final bool onAuthScreens = location == LoginScreen.routePath ||
          location == RegisterScreen.routePath;

      if (!loggedIn) {
        return onAuthScreens ? null : LoginScreen.routePath;
      }
      if (onAuthScreens) return HomeScreen.routePath;
      return null;
    },
    routes: [
      GoRoute(
        path: LoginScreen.routePath,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RegisterScreen.routePath,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: HomeScreen.routePath,
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );

  ref.listen(authChangesProvider, (_, __) => router.refresh());
  return router;
});
