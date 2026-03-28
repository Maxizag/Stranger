import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neznakomets/features/chat/chat_screen.dart';
import 'package:neznakomets/features/home/home_screen.dart';
import 'package:neznakomets/features/onboarding/onboarding_screen.dart';
import 'package:neznakomets/features/subscription/subscription_screen.dart';
import 'package:neznakomets/features/vault/vault_entry_screen.dart';
import 'package:neznakomets/features/vault/vault_session_detail_screen.dart';

/// Переопределяется в `main` после чтения SharedPreferences.
final appInitialLocationProvider = Provider<String>((ref) => '/');

final goRouterProvider = Provider<GoRouter>((ref) {
  final initialLocation = ref.watch(appInitialLocationProvider);
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: '/vault',
        builder: (context, state) => const VaultEntryScreen(),
        routes: [
          GoRoute(
            path: 'session/:id',
            builder: (context, state) => VaultSessionDetailScreen(
              sessionId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),
    ],
  );
});
