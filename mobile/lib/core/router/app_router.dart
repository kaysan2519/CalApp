import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/today/presentation/today_screen.dart';
import '../../features/nutrition/presentation/nutrition_screen.dart';
import '../../features/workouts/presentation/workouts_screen.dart';
import '../../features/community/presentation/community_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/onboarding/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/welcome_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/onboarding/presentation/recommendations_screen.dart';
import '../../features/gamification/presentation/rank_overview_screen.dart';
import '../../features/today/presentation/master_action_hub_modal.dart';
import '../../features/auth/presentation/auth_state_notifier.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/welcome',
    redirect: (context, state) {
      final path = state.matchedLocation;
      final isEditingProfile = path == '/onboarding' && state.uri.queryParameters['edit'] == 'true';

      final auth = ref.read(authStateProvider);
      final isPublic = path == '/welcome' || path == '/login' || path == '/register' || path == '/splash';
      final user = auth.valueOrNull;

      if (isPublic) {
        if (user != null) {
          return user.onboardingCompleted ? '/today' : '/onboarding';
        }
        return null;
      }

      if (auth.isLoading) return null;

      if (user == null) return '/welcome';
      if (!user.onboardingCompleted && path != '/onboarding') return '/onboarding';
      if (user.onboardingCompleted && path == '/onboarding' && !isEditingProfile) return '/today';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/recommendations', builder: (context, state) => const RecommendationsScreen()),
      GoRoute(path: '/rank', builder: (context, state) => const RankOverviewScreen()),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Scaffold(
            body: navigationShell,
            floatingActionButton: FloatingActionButton(
              heroTag: 'cal_master_action_fab',
              onPressed: () => MasterActionHubModal.show(context),
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.black,
              elevation: 4,
              tooltip: 'Aksi Cepat & Pindai (+)',
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.add_rounded, size: 28),
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) {
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.today_outlined),
                  selectedIcon: Icon(Icons.today_rounded),
                  label: 'Hari Ini',
                ),
                NavigationDestination(
                  icon: Icon(Icons.restaurant_outlined),
                  selectedIcon: Icon(Icons.restaurant_rounded),
                  label: 'Nutrisi',
                ),
                NavigationDestination(
                  icon: Icon(Icons.fitness_center_outlined),
                  selectedIcon: Icon(Icons.fitness_center_rounded),
                  label: 'Latihan',
                ),
                NavigationDestination(
                  icon: Icon(Icons.groups_outlined),
                  selectedIcon: Icon(Icons.groups_rounded),
                  label: 'Komunitas',
                ),
              ],
            ),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/today',
                builder: (context, state) => const TodayScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/nutrition',
                builder: (context, state) => const NutritionScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/workouts',
                builder: (context, state) => const WorkoutsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/community',
                builder: (context, state) => const CommunityScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.listen(authStateProvider, (_, _) => router.refresh());
  ref.onDispose(router.dispose);
  return router;
});
