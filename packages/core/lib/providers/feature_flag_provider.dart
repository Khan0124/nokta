import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/feature_flag.dart';
import '../services/feature_flag_service.dart';

final featureFlagServiceProvider = Provider<FeatureFlagService>((ref) {
  final service = FeatureFlagService();
  ref.onDispose(service.clearCache);
  return service;
});

final featureFlagsProvider = FutureProvider<List<FeatureFlag>>((ref) async {
  final service = ref.read(featureFlagServiceProvider);
  return service.fetchFlags();
});

final featureFlagDetailProvider = Provider.family<FeatureFlag?, String>((ref, flagKey) {
  final asyncFlags = ref.watch(featureFlagsProvider);
  return asyncFlags.maybeWhen(
    data: (flags) {
      for (final flag in flags) {
        if (flag.key == flagKey) {
          return flag;
        }
      }
      return null;
    },
    orElse: () => null,
  );
});

final featureFlagEnabledProvider = Provider.family<bool, String>((ref, flagKey) {
  final asyncFlags = ref.watch(featureFlagsProvider);
  return asyncFlags.maybeWhen(
    data: (flags) {
      for (final flag in flags) {
        if (flag.key == flagKey) {
          return flag.isEnabled;
        }
      }
      return false;
    },
    orElse: () => false,
  );
});

final featureFlagRefreshProvider = Provider<Future<void> Function({bool force})>((ref) {
  return ({bool force = false}) async {
    if (force) {
      ref.read(featureFlagServiceProvider).clearCache();
    }

    await ref.refresh(featureFlagsProvider.future);
  };
});
