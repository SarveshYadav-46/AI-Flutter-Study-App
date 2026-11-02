import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'splash_screen.dart';
import 'main_navigation.dart';
import 'login_screen.dart';

/// AuthGate serves as the gatekeeper for authentication.
/// - Shows SplashScreen while authentication state is being initialized.
/// - Shows MainNavigation ONLY when Firebase Authentication confirms a signed-in user.
/// - Shows LoginScreen when no Firebase user is signed in.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        // While Firebase is determining auth status
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        // Only show main app when Firebase Authentication confirms a signed-in user
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          FirestoreService().ensureStudentProfile(user);
          return const MainNavigation();
        }

        // When no Firebase user is signed in, strictly show the Login screen
        return const LoginScreen();
      },
    );
  }
}
