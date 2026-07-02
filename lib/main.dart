// WHAT THIS FILE DOES:
// The starting point of the application.
// Now connected to Firebase using generated options.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:questarena/firebase_options.dart';
import 'core/theme/app_theme.dart';  // ← CHANGED: was core/constants/colors.dart
import 'ui/screens/auth_wrapper.dart';

void main() async {
  // 1. Ensure Flutter framework is ready
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase using the generated options for the current platform (Android/iOS/Web)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase Initialization Error: $e');
  }

  runApp(
    const ProviderScope(
      child: QuestArenaApp(),
    ),
  );
}

class QuestArenaApp extends StatelessWidget {
  const QuestArenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuestArena',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkArena,  // ← CHANGED: replaced entire ThemeData block
      home: const AuthWrapper(),
    );
  }
}