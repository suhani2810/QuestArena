// WHAT THIS FILE DOES:
// Exposes Auth state to the entire app.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/services/auth_service.dart';
import '../data/repositories/auth_repository.dart';

final authServiceProvider = Provider((ref) => FirebaseAuthService());

final authRepositoryProvider = Provider((ref) {
  final service = ref.watch(authServiceProvider);
  return AuthRepository(service);
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});
