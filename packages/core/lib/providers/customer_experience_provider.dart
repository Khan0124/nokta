import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/customer_experience_service.dart';

final customerExperienceServiceProvider =
    Provider<CustomerExperienceService>((ref) {
  return CustomerExperienceService();
});
