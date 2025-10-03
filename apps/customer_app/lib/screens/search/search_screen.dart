import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nokta_core/nokta_core.dart';

import '../../providers/customer_app_providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final results = ref.watch(menuSearchProvider(_query));

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: l10n.translate('customer.search.placeholder'),
            border: InputBorder.none,
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (value) => setState(() => _query = value.trim()),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _controller.clear();
              setState(() => _query = '');
            },
          ),
        ],
      ),
      body: results.when(
        data: (items) {
          if (_query.isEmpty) {
            return Center(
              child: Text(l10n.translate('customer.search.startTyping')),
            );
          }
          if (items.isEmpty) {
            return Center(
              child: Text(l10n.translate('customer.search.noResults', params: {'query': _query})),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final product = items[index];
              return Card(
                child: ListTile(
                  title: Text(product.name),
                  subtitle: Text(product.description),
                  trailing: Text(l10n.formatCurrency(product.price)),
                  onTap: () => ref.read(cartProvider.notifier).addItem(product),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('$error'),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
