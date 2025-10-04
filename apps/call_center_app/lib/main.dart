import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nokta_core/nokta_core.dart';

import 'screens/dashboard/call_center_dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('en_US');
  await initializeDateFormatting('ar_SA');

  final localeService = await LocaleService.create();

  runApp(
    ProviderScope(
      overrides: [
        localeServiceProvider.overrideWithValue(localeService),
      ],
      child: const CallCenterApp(),
    ),
  );
}

class CallCenterApp extends ConsumerWidget {
  const CallCenterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final featureFlags = ref.watch(featureFlagsProvider);

    final callCenterEnabled = featureFlags.maybeWhen(
      data: (flags) =>
          flags.any((flag) => flag.key == 'call_center_console' && flag.isEnabled),
      orElse: () => false,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0EA5E9)),
      ),
      home: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          if (!callCenterEnabled) {
            return FeatureFlagDisabledScreen(
              title: l10n.translate('callCenter.title'),
              message: l10n.translate('callCenter.flagDisabled'),
              cta: l10n.translate('callCenter.contactAdministrator'),
            );
          }
          return const CallCenterDashboardScreen();
        },
      ),
    );
  }
}

class FeatureFlagDisabledScreen extends StatelessWidget {
  const FeatureFlagDisabledScreen({
    required this.title,
    required this.message,
    required this.cta,
    super.key,
  });

  final String title;
  final String message;
  final String cta;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 72),
              const SizedBox(height: 16),
              Text(
                message,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                cta,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
