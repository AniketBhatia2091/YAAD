import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/capture/capture_screen.dart';
import '../features/capture/preview_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/home/home_screen.dart';
import '../features/main_navigation/main_navigation_screen.dart';
import '../features/memory_detail/memory_detail_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/search/search_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/understanding/understanding_screen.dart';
import '../features/vault/category_memories_screen.dart';
import '../features/vault/vault_screen.dart';
import 'providers.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  final isOnboardingCompleted = ref.watch(onboardingCompletedProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: isOnboardingCompleted ? '/' : '/onboarding',
    redirect: (context, state) {
      final onboardingDone = ref.read(onboardingCompletedProvider);
      final isGoingToOnboarding = state.matchedLocation == '/onboarding';

      if (!onboardingDone && !isGoingToOnboarding) {
        return '/onboarding';
      }
      if (onboardingDone && isGoingToOnboarding) {
        return '/';
      }
      return null;
    },
    routes: [
      // Onboarding Route
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Capture Screen (Full screen modal route)
      GoRoute(
        path: '/capture',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CaptureScreen(),
      ),

      // Preview Screen
      GoRoute(
        path: '/preview',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final imagePath = state.extra as String? ?? '';
          return PreviewScreen(imagePath: imagePath);
        },
      ),

      // Understanding Screen (Review extracted information)
      GoRoute(
        path: '/understanding/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final memoryId = state.pathParameters['id'] ?? '';
          return UnderstandingScreen(memoryId: memoryId);
        },
      ),

      // Memory Detail Screen
      GoRoute(
        path: '/memory/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final memoryId = state.pathParameters['id'] ?? '';
          return MemoryDetailScreen(memoryId: memoryId);
        },
      ),

      // Category Memories Screen
      GoRoute(
        path: '/vault/category/:key',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final key = state.pathParameters['key'] ?? '';
          return CategoryMemoriesScreen(categoryKey: key);
        },
      ),

      // Settings Screen (Pushed on top of stack)
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),

      // Main Stateful Navigation Shell (Bottom Navigation Tabs)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationScreen(navigationShell: navigationShell);
        },
        branches: [
          // Tab 1: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),

          // Tab 2: Vault
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/vault',
                builder: (context, state) => const VaultScreen(),
              ),
            ],
          ),

          // Tab 3: Capture Dummy Placeholder Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/capture_tab',
                builder: (context, state) => const CaptureScreen(),
              ),
            ],
          ),

          // Tab 4: Search
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),

          // Tab 5: Chat
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chat',
                builder: (context, state) => const ChatScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
