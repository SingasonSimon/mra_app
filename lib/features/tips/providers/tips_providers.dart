import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/tips_repository.dart';

final tipsRepositoryProvider = Provider<TipsRepository>((ref) {
  return TipsRepository();
});

final tipsStreamProvider = StreamProvider((ref) {
  final repository = ref.watch(tipsRepositoryProvider);
  return repository.watchTips();
});

