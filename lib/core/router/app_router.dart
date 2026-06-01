import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:financeapp/presentation/screens/auth/login_screen.dart';
import 'package:financeapp/presentation/screens/auth/register_screen.dart';
import 'package:financeapp/presentation/screens/auth/onboarding_screen.dart';
import 'package:financeapp/presentation/screens/home/home_screen.dart';
import 'package:financeapp/presentation/screens/transactions/transactions_screen.dart';
import 'package:financeapp/presentation/screens/transactions/add_transaction_screen.dart';
import 'package:financeapp/presentation/screens/investments/investments_screen.dart';
import 'package:financeapp/presentation/screens/investments/stock_detail_screen.dart';
import 'package:financeapp/presentation/screens/profile/profile_screen.dart';
import 'package:financeapp/presentation/screens/shell/main_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuth = session != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isOnboarding = state.matchedLocation == '/';

      if (!isAuth && !isAuthRoute && !isOnboarding) return '/auth/login';
      if (isAuth && (isAuthRoute || isOnboarding)) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/transactions',
            builder: (context, state) => const TransactionsScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const AddTransactionScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/investments',
            builder: (context, state) => const InvestmentsScreen(),
            routes: [
              GoRoute(
                path: ':symbol',
                builder: (context, state) => StockDetailScreen(
                  symbol: state.pathParameters['symbol']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Página não encontrada: ${state.error}'),
      ),
    ),
  );
});
