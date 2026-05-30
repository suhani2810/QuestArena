// WHAT THIS FILE DOES:
// Provides the current player's profile data globally.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_providers.dart';
import '../data/services/firestore_service.dart';
import '../data/repositories/user_repository.dart';
import '../data/models/user_model.dart';
import '../core/errors/result.dart';

final firestoreServiceProvider = Provider((ref) => FirestoreService());

final userRepositoryProvider = Provider((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return UserRepository(service);
});

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return null;

  final repo = ref.watch(userRepositoryProvider);
  final result = await repo.getUserProfile(authState.uid);
  
  return switch (result) {
    Success(data: final profile) => profile,
    Failure() => null,
  };
});
