import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/dashboard/screens/placeholder_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      if (authState.isLoading) return null;

      final isAuth = authState.value != null;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isAuth && !isLoggingIn) return '/login';
      if (isAuth && isLoggingIn) return '/';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
        routes: [
          GoRoute(
            path: 'news',
            builder: (context, state) => const PlaceholderScreen(title: 'News Feed'),
          ),
          GoRoute(
            path: 'kids',
            builder: (context, state) => const PlaceholderScreen(title: 'My Kids'),
          ),
          GoRoute(
            path: 'messages',
            builder: (context, state) => const PlaceholderScreen(title: 'Messages'),
          ),
          GoRoute(
            path: 'notifications',
            builder: (context, state) => const PlaceholderScreen(title: 'Notifications'),
          ),
        ]
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
  );
});
