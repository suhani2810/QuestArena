// WHAT THIS FILE DOES:
// Orchestrates the flow: Login -> Create Profile -> Home.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';
import '../../providers/user_providers.dart';
import 'login_screen.dart';
import 'splash_screen.dart';
import 'create_profile_screen.dart';
import 'home_screen.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const SplashScreen(),
      error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (user) {
        if (user == null) return const LoginScreen();

        // If logged in, check if user has a profile document
        final userProfile = ref.watch(currentUserProvider);

        return userProfile.when(
          loading: () => const SplashScreen(),
          // If there's an error (like profile not found or network error),
          // we go to CreateProfile so the user isn't stuck.
          error: (e, s) {
            debugPrint('Profile Fetch Error: $e');
            return const CreateProfileScreen();
          },
          data: (profile) {
            if (profile == null) {
              return const CreateProfileScreen();
            }
            return const HomeScreen();
          },
        );
      },
    );
  }
}
