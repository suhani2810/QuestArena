// WHAT THIS FILE DOES:
// Provides the global top 100 list to the UI.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_providers.dart';
import '../data/repositories/leaderboard_repository.dart';
import '../data/models/leaderboard_model.dart';

final leaderboardRepositoryProvider = Provider((ref) => LeaderboardRepository());

final leaderboardProvider = StreamProvider.autoDispose<List<LeaderboardModel>>((ref) {
  // Only listen if user is authenticated to avoid Permission Denied errors
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return Stream.value([]);

  final repo = ref.watch(leaderboardRepositoryProvider);
  return repo.watchTopPlayers();
});

final weeklyMvpProvider = Provider.autoDispose<LeaderboardModel?>((ref) {
  final players = ref.watch(leaderboardProvider).value ?? [];
  if (players.isEmpty) return null;

  // Sort by mvpScore descending and pick the top one
  final sortedPlayers = List<LeaderboardModel>.from(players);
  sortedPlayers.sort((a, b) => b.mvpScore.compareTo(a.mvpScore));
  
  return sortedPlayers.first;
});
