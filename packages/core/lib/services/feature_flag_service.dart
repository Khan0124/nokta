import '../models/feature_flag.dart';
import 'api.dart';

class FeatureFlagService {
  FeatureFlagService({this.cacheTtl = const Duration(minutes: 5)});

  final Duration cacheTtl;
  List<FeatureFlag> _cache = const [];
  DateTime? _expiresAt;
  bool _isLoading = false;
  Future<List<FeatureFlag>>? _pending;

  Future<List<FeatureFlag>> fetchFlags({String scope = 'tenant', bool forceRefresh = false}) async {
    final now = DateTime.now();

    if (!forceRefresh && _expiresAt != null && now.isBefore(_expiresAt!)) {
      return _cache;
    }

    if (_isLoading && _pending != null) {
      return _pending!;
    }

    final completer = ApiService.get(
      '/api/v1/feature-flags',
      queryParams: {
        'scope': scope,
        'includeMetadata': true,
      },
    ).then((response) {
      final data = response.data['data'] as List<dynamic>? ?? const [];
      _cache = data
          .map((entry) => FeatureFlag.fromJson(entry as Map<String, dynamic>))
          .toList(growable: false);
      _expiresAt = DateTime.now().add(cacheTtl);
      return _cache;
    });

    _isLoading = true;
    _pending = completer;

    try {
      return await completer;
    } finally {
      _isLoading = false;
      _pending = null;
    }
  }

  FeatureFlag? getFlag(String key) {
    for (final flag in _cache) {
      if (flag.key == key) {
        return flag;
      }
    }
    return null;
  }

  bool isEnabled(String key) => getFlag(key)?.isEnabled ?? false;

  void clearCache() {
    _cache = const [];
    _expiresAt = null;
  }
}
