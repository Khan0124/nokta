import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nokta_core/nokta_core.dart';

class CallCenterDashboardScreen extends ConsumerStatefulWidget {
  const CallCenterDashboardScreen({super.key});

  @override
  ConsumerState<CallCenterDashboardScreen> createState() =>
      _CallCenterDashboardScreenState();
}

class _CallCenterDashboardScreenState
    extends ConsumerState<CallCenterDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  CallCenterQueueEntry? _selectedEntry;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final queueAsync = ref.watch(callQueueProvider);
    final metricsAsync = ref.watch(callCenterMetricsProvider);

    final lookupAsync = _searchQuery.trim().length < 3
        ? const AsyncData<CustomerLoyaltyProfile?>(null)
        : ref.watch(callCenterCustomerLookupProvider(_searchQuery));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('callCenter.title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.translate),
            onPressed: () {
              final locale = ref.read(localeProvider);
              final target = locale.languageCode == 'ar'
                  ? const Locale('en')
                  : const Locale('ar');
              ref.read(localeProvider.notifier).setLocale(target);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            metricsAsync.when(
              data: (metrics) => _MetricsHeader(metrics: metrics),
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) => _ErrorBanner(message: error.toString()),
            ),
            const SizedBox(height: 16),
            _SearchBar(
              controller: _searchController,
              hintText: l10n.translate('callCenter.searchHint'),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 8),
            lookupAsync.when(
              data: (profile) => profile == null
                  ? const SizedBox.shrink()
                  : _CustomerProfileCard(profile: profile),
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) => _ErrorBanner(message: error.toString()),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: queueAsync.when(
                data: (queue) => _QueueAndDetails(
                  queue: queue,
                  selectedEntry: _selectedEntry,
                  onEntrySelected: (entry) {
                    setState(() {
                      _selectedEntry = entry;
                    });
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) =>
                    _ErrorBanner(message: error.toString()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricsHeader extends StatelessWidget {
  const _MetricsHeader({required this.metrics});

  final CallCenterMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final formatter = NumberFormat.compact(locale: l10n.locale.toLanguageTag());
    return Row(
      children: [
        Expanded(
          child: KPICard(
            title: l10n.translate('callCenter.waiting'),
            value: formatter.format(metrics.waitingCalls),
            change: metrics.waitingCalls > 3 ? 0.08 : -0.04,
            icon: Icons.phone_in_talk_outlined,
            color: const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: KPICard(
            title: l10n.translate('callCenter.active'),
            value: formatter.format(metrics.activeCalls),
            change: metrics.activeCalls > 0 ? 0.12 : -0.05,
            icon: Icons.support_agent,
            color: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: KPICard(
            title: l10n.translate('callCenter.averageWait'),
            value:
                '${metrics.averageWaitSeconds} ${l10n.translate('common.seconds')}',
            change: metrics.averageWaitSeconds > 120 ? 0.15 : -0.06,
            icon: Icons.timer_outlined,
            color: const Color(0xFFF97316),
          ),
        ),
      ],
    );
  }
}

class _QueueAndDetails extends StatelessWidget {
  const _QueueAndDetails({
    required this.queue,
    required this.selectedEntry,
    required this.onEntrySelected,
  });

  final List<CallCenterQueueEntry> queue;
  final CallCenterQueueEntry? selectedEntry;
  final ValueChanged<CallCenterQueueEntry> onEntrySelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Card(
            child: ListView.separated(
              itemCount: queue.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = queue[index];
                final isSelected = entry.id == selectedEntry?.id;
                return ListTile(
                  selected: isSelected,
                  title: Text(entry.displayName),
                  subtitle: Text(entry.callerNumber),
                  leading: CircleAvatar(
                    backgroundColor: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceVariant,
                    child: Text('${index + 1}'),
                  ),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        l10n.translate(
                          'callCenter.queuePriority',
                          params: {'priority': entry.priority.toString()},
                        ),
                      ),
                      Text(
                        _formatDuration(entry.waitingDuration, l10n),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                  onTap: () => onEntrySelected(entry),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: _CallDetailsPanel(entry: selectedEntry),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration, AppLocalizations l10n) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return l10n.translate(
      'callCenter.queueWaitTime',
      params: {
        'minutes': minutes.toString(),
        'seconds': seconds.toString().padLeft(2, '0'),
      },
    );
  }
}

class _CallDetailsPanel extends ConsumerWidget {
  const _CallDetailsPanel({required this.entry});

  final CallCenterQueueEntry? entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (entry == null) {
      return Card(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l10n.translate('callCenter.selectPrompt')),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry!.displayName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(entry!.callerNumber),
            const Divider(height: 32),
            _CallDetailRow(
              icon: Icons.timer_outlined,
              label: l10n.translate('callCenter.waitingSince'),
              value: DateFormat.Hm(l10n.locale.toLanguageTag())
                  .format(entry!.waitingSince),
            ),
            _CallDetailRow(
              icon: Icons.stacked_line_chart,
              label: l10n.translate('callCenter.priority'),
              value: entry!.priority.toString(),
            ),
            if (entry!.customerId != null) ...[
              const SizedBox(height: 16),
              Text(
                l10n.translate('callCenter.customerHistory'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _CustomerHistorySummary(entry: entry!),
            ],
            const Spacer(),
            Align(
              alignment: AlignmentDirectional.bottomEnd,
              child: FilledButton.icon(
                icon: const Icon(Icons.shopping_bag_outlined),
                label: Text(l10n.translate('callCenter.createOrder')),
                onPressed: () async {
                  try {
                    final result = await ref
                        .read(callCenterServiceProvider)
                        .createGuidedOrder(
                          entry: entry!,
                          branchId: entry!.preferredBranchId,
                        );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.translate(
                            'callCenter.orderCreated',
                            params: {
                              'reference': result.reference,
                            },
                          ),
                        ),
                      ),
                    );
                  } catch (error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        content: Text(error.toString()),
                      ),
                    );
                  }
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _CustomerHistorySummary extends StatelessWidget {
  const _CustomerHistorySummary({required this.entry});

  final CallCenterQueueEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate(
            'callCenter.lastOrder',
            params: {'orderId': (entry.lastOrderId ?? 0).toString()},
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.translate(
            'callCenter.customerId',
            params: {'customerId': (entry.customerId ?? 0).toString()},
          ),
        ),
      ],
    );
  }
}

class _CallDetailRow extends StatelessWidget {
  const _CallDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onChanged: onChanged,
    );
  }
}

class _CustomerProfileCard extends StatelessWidget {
  const _CustomerProfileCard({required this.profile});

  final CustomerLoyaltyProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.verified, color: Color(0xFFFACC15)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.translate(
                      'callCenter.customerTier',
                      params: {'tier': profile.tier.name.toUpperCase()},
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.translate(
                      'callCenter.points',
                      params: {'points': profile.availablePoints.toString()},
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  l10n.translate(
                    'callCenter.lifetimeValue',
                    params: {
                      'value': profile.lifetimeValue.toStringAsFixed(2),
                    },
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.translate(
                    'callCenter.favoriteBranches',
                    params: {
                      'branches': profile.favoriteBranches.join(', '),
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Theme.of(context).colorScheme.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
