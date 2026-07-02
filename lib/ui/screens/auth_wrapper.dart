// WHAT THIS FILE DOES:
// Orchestrates the flow: Login -> Create Profile -> Character Select -> Home.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';
import '../../providers/user_providers.dart';
import '../../ui/widgets/character_avatar.dart';
import 'login_screen.dart';
import 'splash_screen.dart';
import 'create_profile_screen.dart';
import 'character_select_screen.dart';
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

        final userProfile = ref.watch(currentUserProvider);

        return userProfile.when(
          loading: () => const SplashScreen(),
          error: (e, s) {
            debugPrint('Profile Fetch Error: $e');
            return const CreateProfileScreen();
          },
          data: (profile) {
            // No profile yet → create one first
            if (profile == null) return const CreateProfileScreen();

            // Profile exists but no character chosen yet → show character select
            // We use avatarUrl field to store the character id (e.g. 'f1', 'm2')
            // If it's null, empty, or still a URL (contains 'http'), show picker
            final hasChoseCharacter = profile.avatarUrl != null &&
                profile.avatarUrl!.isNotEmpty &&
                !profile.avatarUrl!.startsWith('http') &&
                kCharacters.any((c) => c.id == profile.avatarUrl);

            if (!hasChoseCharacter) {
              return CharacterSelectScreen(
                username: profile.username,
                onConfirm: (CharacterData selected) async {
                  // Save the character id to the user's avatarUrl field
                  // using your existing user provider/repository
                  await ref
                      .read(userRepositoryProvider)
                      .updateAvatarUrl(profile.uid, selected.id);
                  // AuthWrapper rebuilds automatically via currentUserProvider
                },
              );
            }

            return const HomeScreen();
          },
        );
      },
    );
  }
}