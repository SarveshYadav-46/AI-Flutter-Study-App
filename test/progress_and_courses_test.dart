import 'package:flutter_test/flutter_test.dart';
import 'package:minerproject/models/models.dart';
import 'package:minerproject/services/firestore_service.dart';
import 'package:minerproject/utils/mock_data.dart';

void main() {
  group('FirestoreService - Readable Error Formatting Tests', () {
    test('Translates permission-denied error code into readable explanation', () {
      final errorMsg = FirestoreService.getReadableFirestoreError(
        '[cloud_firestore/permission-denied] Missing or insufficient permissions.',
      );
      expect(errorMsg, contains('Access denied (PERMISSION_DENIED)'));
      expect(errorMsg, contains('authorized student account'));
    });

    test('Translates network/unavailable error code into readable explanation', () {
      final errorMsg = FirestoreService.getReadableFirestoreError(
        '[cloud_firestore/unavailable] Network connection unavailable.',
      );
      expect(errorMsg, contains('Network connection unavailable'));
    });

    test('Translates timeout/deadline-exceeded error code into readable explanation', () {
      final errorMsg = FirestoreService.getReadableFirestoreError(
        '[cloud_firestore/deadline-exceeded] Request timed out.',
      );
      expect(errorMsg, contains('request timed out'));
    });

    test('Handles generic or unknown errors cleanly', () {
      final errorMsg = FirestoreService.getReadableFirestoreError('Custom error string');
      expect(errorMsg, contains('Custom error string'));
    });
  });

  group('User-Specific Progress Calculation Tests', () {
    test('New user with no completed lessons has 0.0 progress across all courses', () {
      final newStudent = Student(
        id: 'new_uid_12345',
        name: 'New Student',
        email: 'newstudent@example.com',
        avatarUrl: '',
        totalPoints: 0,
        coursesCompleted: 0,
        completedLessons: const [],
      );

      // Verify empty completed lessons
      expect(newStudent.completedLessons, isEmpty);
      expect(newStudent.totalPoints, equals(0));

      // Calculate progress for each mock course with new user's completed lessons
      for (final course in MockData.courses) {
        final courseLessons = MockData.lessons.where((l) => l.courseId == course.id).toList();
        final completedInCourse = courseLessons
            .where((l) => newStudent.completedLessons.contains(l.id))
            .length;
        final total = course.totalLessons > 0 ? course.totalLessons : courseLessons.length;
        final progress = total > 0 ? (completedInCourse / total) : 0.0;

        expect(progress, equals(0.0), reason: 'Course ${course.id} should have 0.0 progress for new student');
      }
    });

    test('Alex Johnson (s1) has intact 60% progress on c1 and 25% on c2', () {
      final alexStudent = MockData.currentUser;
      expect(alexStudent.id, equals('s1'));
      expect(alexStudent.completedLessons, equals(['l1', 'l2', 'l3', 'l6']));

      // Course c1 (5 lessons: l1, l2, l3, l4, l5)
      final c1Lessons = MockData.lessons.where((l) => l.courseId == 'c1').toList();
      final c1Completed = c1Lessons.where((l) => alexStudent.completedLessons.contains(l.id)).length;
      final c1Progress = c1Completed / 5;
      expect(c1Completed, equals(3));
      expect(c1Progress, equals(0.60));

      // Course c2 (4 lessons: l6, l7, l8, l9)
      final c2Lessons = MockData.lessons.where((l) => l.courseId == 'c2').toList();
      final c2Completed = c2Lessons.where((l) => alexStudent.completedLessons.contains(l.id)).length;
      final c2Progress = c2Completed / 4;
      expect(c2Completed, equals(1));
      expect(c2Progress, equals(0.25));

      // Course c3 (4 lessons: l10, l11, l12, l13)
      final c3Lessons = MockData.lessons.where((l) => l.courseId == 'c3').toList();
      final c3Completed = c3Lessons.where((l) => alexStudent.completedLessons.contains(l.id)).length;
      final c3Progress = c3Completed / 4;
      expect(c3Completed, equals(0));
      expect(c3Progress, equals(0.0));
    });

    test('Progress updates dynamically when user marks lessons complete', () {
      final userCompletedLessons = <String>[];

      double calcC1Progress() {
        final c1Lessons = MockData.lessons.where((l) => l.courseId == 'c1').toList();
        final completed = c1Lessons.where((l) => userCompletedLessons.contains(l.id)).length;
        return completed / 5;
      }

      // Initial: 0%
      expect(calcC1Progress(), equals(0.0));

      // Complete 1 lesson: 20%
      userCompletedLessons.add('l1');
      expect(calcC1Progress(), equals(0.20));

      // Complete 2nd lesson: 40%
      userCompletedLessons.add('l2');
      expect(calcC1Progress(), equals(0.40));

      // Complete 3rd lesson: 60%
      userCompletedLessons.add('l3');
      expect(calcC1Progress(), equals(0.60));

      // Complete all 5 lessons: 100%
      userCompletedLessons.addAll(['l4', 'l5']);
      expect(calcC1Progress(), equals(1.0));
    });

    test('MockData courses default progress is 0.0 and decoupled from shared course definitions', () {
      for (final course in MockData.courses) {
        expect(course.progress, equals(0.0), reason: 'Shared course template must not carry hardcoded demo progress');
      }
    });
  });
}
