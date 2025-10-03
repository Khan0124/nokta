import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nokta_core/nokta_core.dart';

import '../../providers/customer_app_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final customer = ref.watch(customerProvider);
    final loyalty = ref.watch(loyaltySummaryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.translate('customer.profile.title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          customer.when(
            data: (data) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(data['name']?.substring(0, 1) ?? '?'),
                ),
                title: Text(data['name'] ?? ''),
                subtitle: Text(data['email'] ?? ''),
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Text('$error'),
          ),
          const SizedBox(height: 16),
          loyalty.when(
            data: (summary) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.translate('customer.profile.loyaltyHeading'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.translate('customer.profile.points',
                        params: {'points': summary.pointsBalance.toString()})),
                    Text(l10n.translate('customer.profile.tier',
                        params: {'tier': summary.tier})),
                  ],
                ),
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Text('$error'),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(l10n.translate('customer.profile.addresses')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.credit_card),
                  title: Text(l10n.translate('customer.profile.payments')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: Text(l10n.translate('customer.profile.preferences')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.logout),
            label: Text(l10n.translate('customer.profile.signOut')),
          ),
        ],
      ),
    );
  }
}
