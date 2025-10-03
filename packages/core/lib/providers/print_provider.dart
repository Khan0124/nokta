import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/print_service.dart';

final printServiceProvider = Provider<PrintService>((ref) {
  return const PrintService();
});
