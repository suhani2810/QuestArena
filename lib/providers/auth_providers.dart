// WHAT THIS FILE DOES:
// Exposes Auth state to the entire app.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/services/auth_service.dart';
import '../data/repositories/auth_repository.dart';

final authServiceProvider = Provider((ref) => FirebaseAuthService());
//globally, firebase authencation server ko provide karta hai

final authRepositoryProvider = Provider((ref) {
  final service = ref.watch(authServiceProvider);//watch/tracks providers-> finally updates
  return AuthRepository(service);
});//saare providers ko aapas mein chain karke dependencies ko supply kar raha hai

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});
