import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minerproject/services/auth_service.dart';
import 'package:minerproject/screens/login_screen.dart';
import 'package:minerproject/screens/signup_screen.dart';

void main() {
  group('AuthService - Readable Error Mapping Tests', () {
    test('Correctly translates standard Firebase Auth error codes', () {
      expect(
        AuthService.getReadableAuthError('user-not-found'),
        contains('No student account found'),
      );
      expect(
        AuthService.getReadableAuthError('wrong-password'),
        contains('Incorrect password'),
      );
      expect(
        AuthService.getReadableAuthError('email-already-in-use'),
        contains('already exists'),
      );
      expect(
        AuthService.getReadableAuthError('invalid-email'),
        contains('valid email'),
      );
      expect(
        AuthService.getReadableAuthError('weak-password'),
        contains('at least 6 characters'),
      );
      expect(
        AuthService.getReadableAuthError('invalid-credential'),
        contains('Invalid email or password'),
      );
      expect(
        AuthService.getReadableAuthError('too-many-requests'),
        contains('Too many failed attempts'),
      );
      expect(
        AuthService.getReadableAuthError('network-request-failed'),
        contains('Network connection error'),
      );
      expect(
        AuthService.getReadableAuthError('unknown-code', defaultMessage: 'Custom fallback'),
        equals('Custom fallback'),
      );
    });
  });

  group('LoginScreen Form Validation Tests', () {
    testWidgets('Renders all login widgets properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      expect(find.text('EduAI Learning'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('Shows validation errors on empty submission', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
      await tester.pump();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('Shows validation error on malformed email or short password', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.first, 'not-an-email');
      await tester.enterText(textFields.last, '123');

      await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
      await tester.pump();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });
  });

  group('SignupScreen Form Validation Tests', () {
    testWidgets('Renders all signup widgets properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignupScreen(),
        ),
      );

      expect(find.text('Join EduAI'), findsOneWidget);
      expect(find.text('Create Account'), findsNWidgets(2)); // AppBar title & Button
      expect(find.byType(TextFormField), findsNWidgets(4)); // Name, Email, Password, ConfirmPassword
    });

    testWidgets('Shows validation errors on empty fields', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignupScreen(),
        ),
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
      await tester.pump();

      expect(find.text('Please enter your full name'), findsOneWidget);
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter a password'), findsOneWidget);
    });

    testWidgets('Shows validation error on mismatched password confirmation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignupScreen(),
        ),
      );

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Jane Doe');
      await tester.enterText(textFields.at(1), 'jane@example.com');
      await tester.enterText(textFields.at(2), 'secret123');
      await tester.enterText(textFields.at(3), 'secret999');

      await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });
  });
}
