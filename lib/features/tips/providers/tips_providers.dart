import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/tips_repository.dart';
import '../../auth/providers/auth_providers.dart';

final tipsRepositoryProvider = Provider<TipsRepository>((ref) {
  return TipsRepository();
});

final tipsStreamProvider = StreamProvider((ref) {
  final repository = ref.watch(tipsRepositoryProvider);
  final profileAsync = ref.watch(userProfileProvider);
  final conditions = profileAsync.value?.conditions ?? [];
  
  return repository.watchTips(userConditions: conditions);
});

