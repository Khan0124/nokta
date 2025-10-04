import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

final connectivityStatusProvider = StreamProvider<ConnectivityResult>((ref) async* {
  final connectivity = ref.watch(connectivityProvider);
  final initial = await connectivity.checkConnectivity();
  yield initial;
  yield* connectivity.onConnectivityChanged;
});

final isOfflineProvider = Provider<bool>((ref) {
  final status = ref.watch(connectivityStatusProvider);
  final result = status.valueOrNull ?? ConnectivityResult.none;
  return result == ConnectivityResult.none;
});
