import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  /// Stream of authentication state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Currently authenticated Firebase user.
  User? get currentUser => _auth.currentUser;

  /// Authenticated user UID or null if not signed in.
  String? get currentUserId => _auth.currentUser?.uid;

  /// Sign in with email and password.
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        // Ensure student profile in Firestore under student_progress/{uid}
        await _firestoreService.ensureStudentProfile(user);
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      throw getReadableAuthError(e.code, defaultMessage: e.message);
    } catch (e) {
      throw 'An unexpected error occurred during sign-in. Please try again.';
    }
  }

  /// Sign up with email, password, and student name.
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        final cleanName = name.trim().isNotEmpty ? name.trim() : 'Student';
        try {
          await user.updateDisplayName(cleanName);
        } catch (_) {
          // Display name update failure should not block user creation
        }

        // Initialize student profile in Firestore under student_progress/{uid}
        await _firestoreService.createStudentProfile(user, displayName: cleanName);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw getReadableAuthError(e.code, defaultMessage: e.message);
    } catch (e) {
      throw 'An unexpected error occurred during registration. Please try again.';
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error during sign-out: $e');
      rethrow;
    }
  }

  /// Send password reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw getReadableAuthError(e.code, defaultMessage: e.message);
    } catch (e) {
      throw 'Failed to send password reset email. Please try again.';
    }
  }

  /// Maps Firebase Auth error codes to user-friendly messages.
  static String getReadableAuthError(String code, {String? defaultMessage}) {
    switch (code) {
      case 'user-not-found':
        return 'No student account found with this email. Please sign up.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This student account has been disabled. Please contact support.';
      case 'email-already-in-use':
        return 'An account already exists with this email. Please sign in instead.';
      case 'weak-password':
        return 'The password is too weak. Please use at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled in Firebase Console.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network connection error. Please check your internet connection.';
      case 'invalid-credential':
        return 'Invalid email or password. Please verify your credentials.';
      default:
        return defaultMessage ?? 'Authentication error occurred ($code).';
    }
  }
}
