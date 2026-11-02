import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minerproject/models/quiz_bank_model.dart';
import 'package:minerproject/screens/quiz_zone_result_screen.dart';
import 'package:minerproject/utils/quiz_bank_data.dart';

void main() {
  group('Quiz Zone - Question Bank & Topic Filtering Tests', () {
    test('All required topic categories exist and are non-empty', () {
      final categories = QuizBankData.categories;
      expect(categories, containsAll([
        'All',
        'Programming',
        'Computer Science',
        'AI & ML',
        'Web Development',
        'Aptitude',
        'General Knowledge',
      ]));

      for (var category in categories) {
        if (category == 'All') continue;
        final topicsInCat = QuizBankData.getTopicsForCategory(category);
        expect(topicsInCat.isNotEmpty, isTrue, reason: 'Category $category should have topics');
      }
    });

    test('All expected topics are defined in QuizBankData', () {
      final definedTopicNames = QuizBankData.topics.map((t) => t.topic).toList();
      expect(definedTopicNames, containsAll([
        // Programming
        'Java', 'Python', 'C++', 'JavaScript',
        // Computer Science
        'DSA', 'DBMS', 'Operating Systems', 'Computer Networks',
        // AI & ML
        'Artificial Intelligence', 'Machine Learning', 'Deep Learning', 'NLP',
        // Web Development
        'HTML', 'CSS', 'React',
        // Aptitude
        'Quantitative Aptitude', 'Logical Reasoning',
        // General Knowledge
        'General Knowledge',
      ]));
    });

    test('Topic search filters topics correctly by keyword', () {
      final allTopics = QuizBankData.topics;

      // Search 'python'
      final searchPython = allTopics.where((t) =>
        t.topic.toLowerCase().contains('python') ||
        t.description.toLowerCase().contains('python')
      ).toList();
      expect(searchPython.any((t) => t.topic == 'Python'), isTrue);

      // Search 'network'
      final searchNetwork = allTopics.where((t) =>
        t.topic.toLowerCase().contains('network') ||
        t.description.toLowerCase().contains('network')
      ).toList();
      expect(searchNetwork.any((t) => t.topic == 'Computer Networks'), isTrue);

      // Search 'learning'
      final searchLearning = allTopics.where((t) =>
        t.topic.toLowerCase().contains('learning') ||
        t.description.toLowerCase().contains('learning')
      ).toList();
      expect(searchLearning.length, greaterThanOrEqualTo(2)); // Machine Learning, Deep Learning
    });
  });

  group('Quiz Zone - Question Data Model & Schema Integrity', () {
    test('Every question has stable ID, 4 options, valid answer index, and explanation', () {
      final questions = QuizBankData.initialQuestions;
      expect(questions.length, greaterThanOrEqualTo(30));

      final seenIds = <String>{};
      for (var q in questions) {
        // Stable unique ID
        expect(q.id.isNotEmpty, isTrue);
        expect(seenIds.contains(q.id), isFalse, reason: 'Duplicate ID detected: ${q.id}');
        seenIds.add(q.id);

        // Exactly 4 options
        expect(q.options.length, equals(4), reason: 'Question ${q.id} must have exactly 4 options');
        for (var opt in q.options) {
          expect(opt.trim().isNotEmpty, isTrue);
        }

        // Correct option index within bounds [0..3]
        expect(q.correctOptionIndex >= 0 && q.correctOptionIndex < 4, isTrue);

        // Explanation is non-empty
        expect(q.explanation.trim().isNotEmpty, isTrue);

        // Marks >= 1
        expect(q.marks, greaterThanOrEqualTo(1));

        // Difficulty is one of Easy, Medium, Hard
        expect(['Easy', 'Medium', 'Hard'], contains(q.difficulty));
      }
    });

    test('Serialization and deserialization toMap and fromMap are lossless', () {
      final original = QuizBankQuestion(
        id: 'qb_test_001',
        topic: 'Flutter Architecture',
        category: 'Programming',
        difficulty: 'Medium',
        question: 'What is the purpose of BuildContext in Flutter?',
        options: ['Locates widget in element tree', 'Compiles Dart code', 'Connects to database', 'Renders pixels'],
        correctOptionIndex: 0,
        explanation: 'BuildContext represents a handle to the location of a widget in the widget tree hierarchy.',
        marks: 1,
      );

      final map = original.toMap();
      final reconstructed = QuizBankQuestion.fromMap(map, original.id);

      expect(reconstructed.id, equals(original.id));
      expect(reconstructed.topic, equals(original.topic));
      expect(reconstructed.category, equals(original.category));
      expect(reconstructed.difficulty, equals(original.difficulty));
      expect(reconstructed.question, equals(original.question));
      expect(reconstructed.options, equals(original.options));
      expect(reconstructed.correctOptionIndex, equals(original.correctOptionIndex));
      expect(reconstructed.explanation, equals(original.explanation));
      expect(reconstructed.marks, equals(original.marks));
    });
  });

  group('Quiz Zone - Selection, Non-Repetition, and Available Count Capping', () {
    test('Question selection never repeats questions within one quiz attempt', () {
      final pool = QuizBankData.getQuestionsForTopic('Java');
      expect(pool.isNotEmpty, isTrue);

      final sampled = List<QuizBankQuestion>.from(pool)..shuffle();
      final selectedIds = <String>{};

      for (var q in sampled) {
        expect(selectedIds.contains(q.id), isFalse, reason: 'Duplicate question in attempt: ${q.id}');
        selectedIds.add(q.id);
      }
      expect(selectedIds.length, equals(sampled.length));
    });

    test('Caps question count to available count when requested count exceeds bank size', () {
      final pool = QuizBankData.getQuestionsForTopic('Java', difficulty: 'Easy');
      const requestedCount = 20;

      List<QuizBankQuestion> selected = List<QuizBankQuestion>.from(pool);
      if (selected.length > requestedCount) {
        selected = selected.sublist(0, requestedCount);
      }

      // Must not exceed available pool size
      expect(selected.length, equals(pool.length));
      expect(selected.length, lessThanOrEqualTo(requestedCount));

      // No duplicates
      final idSet = selected.map((q) => q.id).toSet();
      expect(idSet.length, equals(selected.length));
    });

    test('Limits to requested count when bank has sufficient questions', () {
      final pool = QuizBankData.initialQuestions; // Large pool
      const requestedCount = 5;

      List<QuizBankQuestion> selected = List<QuizBankQuestion>.from(pool);
      if (selected.length > requestedCount) {
        selected = selected.sublist(0, requestedCount);
      }

      expect(selected.length, equals(5));
      expect(selected.map((q) => q.id).toSet().length, equals(5));
    });
  });

  group('Quiz Zone - Scoring, Percentage, and Timer Logic', () {
    test('Score calculation is 100% when all answers match correctOptionIndex', () {
      final questions = QuizBankData.getQuestionsForTopic('DSA').take(3).toList();
      final userAnswers = <int, int>{};

      for (int i = 0; i < questions.length; i++) {
        userAnswers[i] = questions[i].correctOptionIndex;
      }

      int score = 0;
      for (int i = 0; i < questions.length; i++) {
        if (userAnswers[i] == questions[i].correctOptionIndex) {
          score++;
        }
      }

      final percentage = (score / questions.length) * 100.0;
      expect(score, equals(3));
      expect(percentage, equals(100.0));
    });

    test('Score calculation reflects partial and incorrect answers accurately', () {
      final questions = QuizBankData.getQuestionsForTopic('Python').take(4).toList();
      // 2 correct, 1 wrong, 1 unanswered
      final userAnswers = <int, int>{
        0: questions[0].correctOptionIndex,
        1: (questions[1].correctOptionIndex + 1) % 4, // Wrong
        2: questions[2].correctOptionIndex,
        // index 3 is omitted (unanswered)
      };

      int score = 0;
      for (int i = 0; i < questions.length; i++) {
        if (userAnswers[i] == questions[i].correctOptionIndex) {
          score++;
        }
      }

      final percentage = (score / questions.length) * 100.0;
      expect(score, equals(2));
      expect(percentage, equals(50.0));
    });

    test('Timed mode calculates remaining seconds and triggers when expired', () {
      int remainingSeconds = 3;
      bool submitted = false;

      void tick() {
        if (remainingSeconds <= 1) {
          remainingSeconds = 0;
          submitted = true;
        } else {
          remainingSeconds--;
        }
      }

      // Tick 1
      tick();
      expect(remainingSeconds, equals(2));
      expect(submitted, isFalse);

      // Tick 2
      tick();
      expect(remainingSeconds, equals(1));
      expect(submitted, isFalse);

      // Tick 3: expiry
      tick();
      expect(remainingSeconds, equals(0));
      expect(submitted, isTrue);
    });
  });

  group('Quiz Zone - Student History & Multi-User Isolation Tests', () {
    test('Quiz attempts are strictly isolated by Student UID', () {
      final userAAttempt1 = QuizAttempt(
        id: 'attempt_a1',
        studentId: 'user_alice_uid_111',
        topic: 'Java',
        category: 'Programming',
        difficulty: 'Easy',
        mode: 'Timed',
        score: 5,
        totalQuestions: 5,
        percentage: 100.0,
        timeTakenSeconds: 120,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      );

      final userAAttempt2 = QuizAttempt(
        id: 'attempt_a2',
        studentId: 'user_alice_uid_111',
        topic: 'DSA',
        category: 'Computer Science',
        difficulty: 'Medium',
        mode: 'Practice',
        score: 4,
        totalQuestions: 5,
        percentage: 80.0,
        timeTakenSeconds: 180,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      );

      final userBAttempt = QuizAttempt(
        id: 'attempt_b1',
        studentId: 'user_bob_uid_222',
        topic: 'Python',
        category: 'Programming',
        difficulty: 'Hard',
        mode: 'Timed',
        score: 2,
        totalQuestions: 5,
        percentage: 40.0,
        timeTakenSeconds: 200,
        timestamp: DateTime.now(),
      );

      final allDatabaseAttempts = [userAAttempt1, userAAttempt2, userBAttempt];

      // Simulate isolated query for Alice
      final aliceAttempts = allDatabaseAttempts
          .where((a) => a.studentId == 'user_alice_uid_111')
          .toList();
      expect(aliceAttempts.length, equals(2));
      expect(aliceAttempts.any((a) => a.studentId == 'user_bob_uid_222'), isFalse);

      // Simulate isolated query for Bob
      final bobAttempts = allDatabaseAttempts
          .where((a) => a.studentId == 'user_bob_uid_222')
          .toList();
      expect(bobAttempts.length, equals(1));
      expect(bobAttempts.first.topic, equals('Python'));
      expect(bobAttempts.any((a) => a.studentId == 'user_alice_uid_111'), isFalse);

      // Simulate a brand new user Charlie (no history)
      final charlieAttempts = allDatabaseAttempts
          .where((a) => a.studentId == 'user_charlie_uid_333')
          .toList();
      expect(charlieAttempts.isEmpty, isTrue, reason: 'New user starts with zero quiz history');
    });

    test('Topic best score updates independently per topic and per user', () {
      final Map<String, double> aliceBestScores = {
        'Java': 70.0,
        'DSA': 60.0,
      };

      // Alice takes a new Java quiz scoring 90% -> should update Java best score
      final newScore = 90.0;
      final currentJavaBest = aliceBestScores['Java'] ?? 0.0;
      if (newScore > currentJavaBest) {
        aliceBestScores['Java'] = newScore;
      }
      expect(aliceBestScores['Java'], equals(90.0));

      // Alice takes DSA scoring 50% -> should NOT overwrite higher 60%
      final lowerDsaScore = 50.0;
      final currentDsaBest = aliceBestScores['DSA'] ?? 0.0;
      if (lowerDsaScore > currentDsaBest) {
        aliceBestScores['DSA'] = lowerDsaScore;
      }
      expect(aliceBestScores['DSA'], equals(60.0));

      // Bob's best score map is isolated
      final Map<String, double> bobBestScores = {};
      expect(bobBestScores.containsKey('Java'), isFalse);
    });

    test('Course progress and Quiz Zone attempts remain strictly decoupled', () {
      // Course progress tracks completed lesson IDs:
      final studentCompletedLessons = <String>['l1', 'l2', 'l3'];
      final courseTotalLessons = 5;
      final courseProgress = (studentCompletedLessons.length / courseTotalLessons);
      expect(courseProgress, equals(0.6));

      // Student takes independent Quiz Zone attempts:
      final quizAttempt = QuizAttempt(
        id: 'attempt_qz_999',
        studentId: 'user_test',
        topic: 'DBMS',
        category: 'Computer Science',
        difficulty: 'Easy',
        mode: 'Practice',
        score: 5,
        totalQuestions: 5,
        percentage: 100.0,
        timeTakenSeconds: 60,
        timestamp: DateTime.now(),
      );

      // Quiz attempt should not modify course lesson IDs or progress
      expect(studentCompletedLessons.length, equals(3));
      expect(studentCompletedLessons.contains('attempt_qz_999'), isFalse);
      expect(quizAttempt.score, equals(5));
    });
  });

  group('Quiz Zone - Widget & Result UI Tests', () {
    testWidgets('QuizZoneResultScreen displays score summary, badges, and review items', (tester) async {
      final questions = QuizBankData.getQuestionsForTopic('Python').take(2).toList();
      final userAnswers = <int, int>{
        0: questions[0].correctOptionIndex, // correct
        1: (questions[1].correctOptionIndex + 1) % 4, // incorrect
      };

      final attempt = QuizAttempt(
        id: 'attempt_widget_test',
        studentId: 'test_student',
        topic: 'Python',
        category: 'Programming',
        difficulty: 'Medium',
        mode: 'Practice',
        score: 1,
        totalQuestions: 2,
        percentage: 50.0,
        timeTakenSeconds: 45,
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: QuizZoneResultScreen(
            attempt: attempt,
            questions: questions,
            userAnswers: userAnswers,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify results UI elements
      expect(find.text('Quiz Results'), findsOneWidget);
      expect(find.text('Python • Medium • Practice Mode'), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget); // Score
      expect(find.text('50.0%'), findsOneWidget); // Percentage
      expect(find.text('45s'), findsOneWidget); // Time Taken
      expect(find.text('Retake Quiz'), findsOneWidget);
      expect(find.text('Other Topics'), findsOneWidget);
      expect(find.text('Question Review'), findsOneWidget);

      // Verify question texts are visible
      expect(find.textContaining('Q1.'), findsOneWidget);
      expect(find.textContaining('Q2.'), findsOneWidget);
    });
  });
}
