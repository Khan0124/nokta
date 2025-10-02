// packages/core/lib/services/tenant_service.dart
import 'package:riverpod/riverpod.dart';

class TenantService {
  String? _currentTenantId;
  
  String get currentTenantId => _currentTenantId ?? '';
  
  void setTenant(String tenantId) {
    _currentTenantId = tenantId;
  }
  
  Map<String, String> get headers => {
    if (_currentTenantId != null) 'X-Tenant-ID': _currentTenantId!,
  };
}

final tenantServiceProvider = Provider((ref) => TenantService());