// WHAT THIS FILE DOES:
// Reactive state for the matchmaking process.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_providers.dart';
import '../data/repositories/matchmaking_repository.dart';

final matchmakingRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return MatchmakingRepository(dio);
});

// This provider watches the matchmaking document in real-time
final matchmakingTicketProvider = StreamProvider.autoDispose((ref) {
  final user = ref.watch(currentUserProvider).value;//catches/sees whatever changes happens in the user profile, like badge change,etc
  if (user == null) return Stream.value(null);

  final repo = ref.watch(matchmakingRepositoryProvider);
  return repo.watchTicket(user.uid);
});//Track
