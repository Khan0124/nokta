import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nokta_core/nokta_core.dart';

import 'screens/auth/login_screen.dart';
import 'screens/home/driver_home_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const ProviderScope(child: DriverApp()));
}

class DriverApp extends ConsumerWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Driver App',
      theme: AppTheme.driverTheme,
      home: authState.when(
        initial: () => const SplashScreen(),
        loading: () => const SplashScreen(),
        authenticated: (user) => const DriverHomeScreen(),
        unauthenticated: () => const LoginScreen(),
        error: (message) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Authentication error: $message'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(authStateProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
