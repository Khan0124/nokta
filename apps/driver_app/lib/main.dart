import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nokta_core/nokta_core.dart';
import 'package:uuid/uuid.dart';

import 'screens/auth/login_screen.dart';
import 'screens/home/driver_home_screen.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('en_US');
  await initializeDateFormatting('ar_SA');

  final localeService = await LocaleService.create();
  final driverTaskService = DriverTaskService();

  // Ensure demo assignments exist for new drivers on first launch.
  final seededTasks = await driverTaskService.fetchTasks(includeCompleted: true);
  if (seededTasks.isEmpty) {
    await driverTaskService.upsertTasks(_initialAssignments());
  }

  runApp(
    ProviderScope(
      overrides: [
        localeServiceProvider.overrideWithValue(localeService),
        driverTaskServiceProvider.overrideWithValue(driverTaskService),
      ],
      child: const DriverApp(),
    ),
  );
}

class DriverApp extends ConsumerWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
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

List<DriverTask> _initialAssignments() {
  final now = DateTime.now();
  final uuid = const Uuid();

  return [
    DriverTask(
      id: uuid.v4(),
      driverId: 'driver-001',
      orderId: 12001,
      customerName: 'Omar Al-Harbi',
      customerPhone: '+966500000001',
      dropoffAddress: 'King Fahd Rd, Riyadh',
      latitude: 24.7136,
      longitude: 46.6753,
      amountDue: 64.5,
      currency: 'SAR',
      status: DriverTaskStatus.assigned,
      requiresCollection: true,
      createdAt: now.subtract(const Duration(minutes: 20)),
      notes: 'Cash on delivery',
    ),
    DriverTask(
      id: uuid.v4(),
      driverId: 'driver-001',
      orderId: 12002,
      customerName: 'Laila Al-Qahtani',
      customerPhone: '+966500000002',
      dropoffAddress: 'Olaya St, Riyadh',
      latitude: 24.6927,
      longitude: 46.7240,
      amountDue: 42.0,
      currency: 'SAR',
      status: DriverTaskStatus.accepted,
      requiresCollection: false,
      createdAt: now.subtract(const Duration(minutes: 45)),
    ),
    DriverTask(
      id: uuid.v4(),
      driverId: 'driver-001',
      orderId: 11998,
      customerName: 'Saeed Al Mutairi',
      customerPhone: '+966500000099',
      dropoffAddress: 'Al Olaya Towers, Riyadh',
      latitude: 24.7015,
      longitude: 46.6846,
      amountDue: 55.75,
      currency: 'SAR',
      status: DriverTaskStatus.delivered,
      requiresCollection: true,
      createdAt: now.subtract(const Duration(hours: 2)),
      deliveredAt: now.subtract(const Duration(minutes: 30)),
      paymentMethod: DriverPaymentMethod.cash,
      collectedAmount: 55.75,
    ),
  ];
}
