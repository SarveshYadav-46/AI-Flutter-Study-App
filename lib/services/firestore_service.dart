import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../utils/mock_data.dart';
import '../utils/quiz_bank_data.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Courses ---
  Stream<List<Course>> getCourses([String? studentId]) {
    final effectiveStudentId = studentId ?? FirebaseAuth.instance.currentUser?.uid;
    late StreamController<List<Course>> controller;
    StreamSubscription? coursesSub;
    StreamSubscription? lessonsSub;
    StreamSubscription? progressSub;

    List<QueryDocumentSnapshot>? currentCourseDocs;
    final Map<String, List<String>> courseLessonMap = {};
    for (var l in MockData.lessons) {
      courseLessonMap.putIfAbsent(l.courseId, () => []).add(l.id);
    }
    List<String> currentCompletedLessonIds = [];

    void emitIfReady() {
      if (controller.isClosed || currentCourseDocs == null) return;

      final courses = currentCourseDocs!.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final courseId = doc.id;
        final lessonIds = courseLessonMap[courseId] ?? [];
        final rawTotal = data['totalLessons'];
        final totalLessons = (rawTotal is int && rawTotal > 0)
            ? rawTotal
            : (lessonIds.isNotEmpty ? lessonIds.length : 1);
        final completedInCourse = lessonIds.where((id) => currentCompletedLessonIds.contains(id)).length;
        final progress = (totalLessons > 0)
            ? (completedInCourse / totalLessons).clamp(0.0, 1.0)
            : 0.0;

        return Course(
          id: courseId,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          instructor: data['instructor'] ?? '',
          progress: progress,
          imageUrl: data['image'] ?? '',
          totalLessons: totalLessons,
          category: data['category'] ?? '',
        );
      }).toList();

      controller.add(courses);
    }

    controller = StreamController<List<Course>>.broadcast(
      onListen: () {
        coursesSub = _db.collection('courses').snapshots().listen(
          (snapshot) {
            currentCourseDocs = List<QueryDocumentSnapshot>.from(snapshot.docs);
            emitIfReady();
          },
          onError: (error) {
            print('Firestore error (courses): $error');
            if (!controller.isClosed) {
              controller.addError(error);
            }
          },
        );

        lessonsSub = _db.collection('lessons').snapshots().listen(
          (snapshot) {
            final Map<String, List<String>> updatedMap = {};
            for (var doc in snapshot.docs) {
              final data = doc.data();
              final cId = data['courseId'] as String?;
              if (cId != null && cId.isNotEmpty) {
                updatedMap.putIfAbsent(cId, () => []).add(doc.id);
              }
            }
            if (updatedMap.isNotEmpty) {
              courseLessonMap.clear();
              courseLessonMap.addAll(updatedMap);
            }
            emitIfReady();
          },
          onError: (error) {
            print('Firestore warning (lessons for courses): $error');
          },
        );

        if (effectiveStudentId != null) {
          progressSub = _db
              .collection('student_progress')
              .doc(effectiveStudentId)
              .snapshots()
              .listen(
            (doc) {
              if (doc.exists && doc.data() != null) {
                final data = doc.data()!;
                final raw = data['completedLessons'];
                if (raw is List) {
                  currentCompletedLessonIds = List<String>.from(raw);
                } else {
                  currentCompletedLessonIds = [];
                }
              } else {
                currentCompletedLessonIds = [];
              }
              emitIfReady();
            },
            onError: (error) {
              print('Firestore warning (progress for courses): $error');
              currentCompletedLessonIds = [];
              emitIfReady();
            },
          );
        } else {
          currentCompletedLessonIds = [];
          emitIfReady();
        }
      },
      onCancel: () {
        coursesSub?.cancel();
        lessonsSub?.cancel();
        progressSub?.cancel();
      },
    );

    return controller.stream;
  }

  Future<Course?> getCourse(String courseId, {String? studentId}) async {
    final effectiveStudentId = studentId ?? FirebaseAuth.instance.currentUser?.uid;
    try {
      final doc = await _db.collection('courses').doc(courseId).get();
      if (doc.exists) {
        double progress = 0.0;
        if (effectiveStudentId != null) {
          final progressDoc = await _db.collection('student_progress').doc(effectiveStudentId).get();
          if (progressDoc.exists && progressDoc.data() != null) {
            final raw = progressDoc.data()!['completedLessons'];
            final completed = raw is List ? List<String>.from(raw) : <String>[];
            final lessonDocs = await _db.collection('lessons').where('courseId', isEqualTo: courseId).get();
            final lessonIds = lessonDocs.docs.map((d) => d.id).toList();
            final completedCount = lessonIds.where((id) => completed.contains(id)).length;
            final total = (doc.data()?['totalLessons'] as int?) ?? (lessonIds.isNotEmpty ? lessonIds.length : 1);
            progress = total > 0 ? (completedCount / total).clamp(0.0, 1.0) : 0.0;
          }
        }
        return _courseFromFirestore(doc, progress: progress);
      }
    } catch (e) {
      print('Firestore error (getCourse): $e');
    }
    return null;
  }

  Course _courseFromFirestore(DocumentSnapshot doc, {double progress = 0.0}) {
    final data = doc.data() as Map<String, dynamic>;
    return Course(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      instructor: data['instructor'] ?? '',
      progress: progress,
      imageUrl: data['image'] ?? '',
      totalLessons: data['totalLessons'] ?? 0,
      category: data['category'] ?? '',
    );
  }

  // --- Lessons ---
  Stream<List<Lesson>> getLessons(String courseId, {String? studentId}) {
    final effectiveStudentId = studentId ?? FirebaseAuth.instance.currentUser?.uid;
    late StreamController<List<Lesson>> controller;
    StreamSubscription? lessonsSub;
    StreamSubscription? progressSub;

    List<QueryDocumentSnapshot>? currentLessonDocs;
    List<String>? currentCompletedLessonIds;

    void emitIfReady() {
      if (controller.isClosed || currentLessonDocs == null) return;

      final completedIds = currentCompletedLessonIds ?? [];
      final lessons = currentLessonDocs!.map((doc) {
        final isCompleted = completedIds.contains(doc.id);
        return _lessonFromFirestore(doc, isCompleted: isCompleted);
      }).toList();

      controller.add(lessons);
    }

    controller = StreamController<List<Lesson>>.broadcast(
      onListen: () {
        lessonsSub = _db
            .collection('lessons')
            .where('courseId', isEqualTo: courseId)
            .snapshots()
            .listen(
          (snapshot) {
            final docs = List<QueryDocumentSnapshot>.from(snapshot.docs);
            docs.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aOrder = aData['order'] is int
                  ? aData['order'] as int
                  : int.tryParse('${aData['order']}') ?? 0;
              final bOrder = bData['order'] is int
                  ? bData['order'] as int
                  : int.tryParse('${bData['order']}') ?? 0;
              return aOrder.compareTo(bOrder);
            });
            currentLessonDocs = docs;
            emitIfReady();
          },
          onError: (error) {
            print('Firestore error (lessons): $error');
            if (!controller.isClosed) {
              controller.add(
                MockData.lessons.where((l) => l.courseId == courseId).toList(),
              );
            }
          },
        );

        if (effectiveStudentId != null) {
          progressSub = _db
              .collection('student_progress')
              .doc(effectiveStudentId)
              .snapshots()
              .listen(
            (doc) {
              if (doc.exists && doc.data() != null) {
                final data = doc.data()!;
                final raw = data['completedLessons'];
                if (raw is List) {
                  currentCompletedLessonIds = List<String>.from(raw);
                } else {
                  currentCompletedLessonIds = [];
                }
              } else {
                currentCompletedLessonIds = [];
              }
              emitIfReady();
            },
            onError: (error) {
              print('Firestore error (progress for lessons): $error');
              currentCompletedLessonIds = [];
              emitIfReady();
            },
          );
        } else {
          currentCompletedLessonIds = [];
          emitIfReady();
        }
      },
      onCancel: () {
        lessonsSub?.cancel();
        progressSub?.cancel();
      },
    );

    return controller.stream;
  }

  Lesson _lessonFromFirestore(DocumentSnapshot doc, {bool isCompleted = false}) {
    final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
    // If the remote Firestore document does not specify a videoUrl, fall back to default definition
    if ((data['videoUrl'] as String?)?.trim().isNotEmpty != true) {
      final defaultLesson = MockData.lessons.where((l) => l.id == doc.id).firstOrNull;
      if (defaultLesson?.videoUrl != null) {
        data['videoUrl'] = defaultLesson!.videoUrl;
      }
    }
    return Lesson.fromMap(data, doc.id, isCompleted: isCompleted);
  }

  // --- Quizzes ---
  Stream<List<Quiz>> getQuizzes(String courseId) {
    return _db
        .collection('quizzes')
        .where('courseId', isEqualTo: courseId)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Quiz> quizzes = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final questions = await getQuizQuestions(doc.id);
        quizzes.add(Quiz(
          id: doc.id,
          courseId: data['courseId'] ?? '',
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          questions: questions,
        ));
      }
      return quizzes;
    }).handleError((error) {
      print('Firestore error (quizzes): $error');
      return MockData.quizzes.where((q) => q.courseId == courseId).toList();
    });
  }

  Future<List<QuizQuestion>> getQuizQuestions(String quizId) async {
    try {
      final snapshot = await _db
          .collection('quiz_questions')
          .where('quizId', isEqualTo: quizId)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return QuizQuestion(
          question: data['question'] ?? '',
          options: List<String>.from(data['options'] ?? []),
          correctOptionIndex: data['correctAnswer'] ?? 0,
        );
      }).toList();
    } catch (e) {
      return MockData.quizzes.firstWhere((q) => q.id == quizId, orElse: () => MockData.quizzes.first).questions;
    }
  }

  // --- Readable Error Helper ---
  static String getReadableFirestoreError(dynamic error) {
    if (error == null) return 'An unknown Firestore error occurred.';
    final str = error.toString().toLowerCase();
    if (str.contains('permission-denied') || str.contains('permission_denied')) {
      return 'Access denied (PERMISSION_DENIED). Please ensure you are logged in with an authorized student account.';
    }
    if (str.contains('unavailable') || str.contains('network')) {
      return 'Network connection unavailable. Please check your internet connection.';
    }
    if (str.contains('deadline-exceeded') || str.contains('timeout')) {
      return 'The request timed out. Please try again.';
    }
    if (str.contains('not-found')) {
      return 'The requested course content was not found.';
    }
    return 'Firestore error: $error';
  }

  // --- Progress ---
  Stream<Student> getStudentProgress([String? studentId]) {
    final effectiveStudentId = studentId ?? FirebaseAuth.instance.currentUser?.uid;
    if (effectiveStudentId == null) {
      return Stream.value(
        Student(
          id: '',
          name: 'Student',
          email: '',
          avatarUrl: '',
          totalPoints: 0,
          coursesCompleted: 0,
          completedLessons: const [],
        ),
      );
    }

    return _db
        .collection('student_progress')
        .doc(effectiveStudentId)
        .snapshots()
        .map((doc) {
      final authUser = FirebaseAuth.instance.currentUser;
      if (!doc.exists) {
        return Student(
          id: effectiveStudentId,
          name: authUser?.displayName ?? (authUser?.email?.split('@').first ?? 'Student'),
          email: authUser?.email ?? '',
          avatarUrl: authUser?.photoURL ?? '',
          totalPoints: 0,
          coursesCompleted: 0,
          completedLessons: const [],
        );
      }
      final data = doc.data()!;
      final rawCompleted = data['completedLessons'];
      final List<String> completedList;
      if (rawCompleted is List) {
        completedList = List<String>.from(rawCompleted);
      } else {
        completedList = [];
      }

      return Student(
        id: doc.id,
        name: data['name'] ?? authUser?.displayName ?? (authUser?.email?.split('@').first ?? 'Student'),
        email: data['email'] ?? authUser?.email ?? '',
        avatarUrl: data['avatarUrl'] ?? authUser?.photoURL ?? '',
        totalPoints: data['quizScore'] ?? 0,
        coursesCompleted: data['coursesCompleted'] ?? 0,
        completedLessons: completedList,
      );
    }).handleError((error) {
      print('Firestore error (student progress): $error');
      final authUser = FirebaseAuth.instance.currentUser;
      return Student(
        id: effectiveStudentId,
        name: authUser?.displayName ?? (authUser?.email?.split('@').first ?? 'Student'),
        email: authUser?.email ?? '',
        avatarUrl: authUser?.photoURL ?? '',
        totalPoints: 0,
        coursesCompleted: 0,
        completedLessons: const [],
      );
    });
  }

  Future<void> updateLessonCompletion(
    String lessonId,
    bool isCompleted, {
    String? studentId,
  }) async {
    final effectiveStudentId = studentId ?? FirebaseAuth.instance.currentUser?.uid;
    if (effectiveStudentId == null) return;
    final docRef = _db.collection('student_progress').doc(effectiveStudentId);
    if (isCompleted) {
      await docRef.set({
        'completedLessons': FieldValue.arrayUnion([lessonId]),
      }, SetOptions(merge: true));
    } else {
      await docRef.set({
        'completedLessons': FieldValue.arrayRemove([lessonId]),
      }, SetOptions(merge: true));
    }
  }

  /// Ensure a student profile exists in Firestore under student_progress/{uid}.
  /// On first sign-in, initializes an empty progress document if it does not exist.
  /// Never copies demo progress and never overwrites existing progress.
  Future<void> ensureStudentProfile(User user, {String? displayName}) async {
    try {
      final docRef = _db.collection('student_progress').doc(user.uid);
      final docSnap = await docRef.get();
      if (!docSnap.exists) {
        final name = (displayName != null && displayName.trim().isNotEmpty)
            ? displayName.trim()
            : (user.displayName?.trim().isNotEmpty == true
                ? user.displayName!.trim()
                : (user.email?.split('@').first ?? 'Student'));
        await docRef.set({
          'name': name,
          'email': user.email ?? '',
          'avatarUrl': user.photoURL ?? '',
          'quizScore': 0,
          'coursesCompleted': 0,
          'completedLessons': <String>[],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Firestore error (ensureStudentProfile): $e');
    }
  }

  /// Create a new student profile in Firestore under student_progress/{uid}
  Future<void> createStudentProfile(User user, {String? displayName}) =>
      ensureStudentProfile(user, displayName: displayName);

  // --- Text-Based Lesson Content & Optional Media URLs (No Storage) ---
  Future<void> updateLessonContent({
    required String lessonId,
    required String content,
    String? videoUrl,
    String? pdfUrl,
  }) async {
    final Map<String, dynamic> data = {
      'content': content,
    };
    if (videoUrl != null) data['videoUrl'] = videoUrl;
    if (pdfUrl != null) data['pdfUrl'] = pdfUrl;

    await _db.collection('lessons').doc(lessonId).set(
      data,
      SetOptions(merge: true),
    );
  }

  /// Updates only the `videoUrl` field for existing lesson documents in Firestore.
  /// Strictly preserves existing document IDs (l1-l17), course IDs, and all other fields.
  Future<Map<String, dynamic>> updateExistingLessonVideos() async {
    print('=== [FIRESTORE LESSON VIDEOS UPDATE] Updating existing lesson video URLs ===');
    int updatedCount = 0;
    int skippedCount = 0;
    final List<String> updatedLessonIds = [];
    final List<String> errorLessonIds = [];

    for (var lesson in MockData.lessons) {
      if (lesson.videoUrl == null || lesson.videoUrl!.isEmpty) continue;
      try {
        final docRef = _db.collection('lessons').doc(lesson.id);
        final docSnap = await docRef.get();
        if (docSnap.exists) {
          await docRef.set({
            'videoUrl': lesson.videoUrl,
          }, SetOptions(merge: true));
          updatedCount++;
          updatedLessonIds.add(lesson.id);
          print('[VIDEO_SYNCED] lessons/${lesson.id} -> ${lesson.videoUrl}');
        } else {
          skippedCount++;
          print('[VIDEO_SYNC_SKIPPED] lessons/${lesson.id} does not exist in Firestore');
        }
      } catch (e) {
        print('[VIDEO_SYNC_ERROR] Failed for lessons/${lesson.id}: $e');
        errorLessonIds.add(lesson.id);
      }
    }

    return {
      'updatedCount': updatedCount,
      'skippedCount': skippedCount,
      'updatedLessonIds': updatedLessonIds,
      'errorLessonIds': errorLessonIds,
    };
  }

  // =========================================================================
  // --- Quiz Zone: Large Question Bank & Isolated Student Quiz History ---
  // =========================================================================

  /// Seed the shared Quiz Bank in Firestore if not already seeded
  Future<Map<String, dynamic>> seedQuizBankIfEmpty() async {
    print('=== [QUIZ BANK SEEDING] Starting safe quiz bank seeding ===');
    final sentinelRef = _db.collection('_metadata').doc('quiz_bank_seeding');

    int createdCount = 0;
    int skippedCount = 0;

    try {
      final sentinelSnap = await sentinelRef.get();
      if (sentinelSnap.exists) {
        print('[QUIZ BANK SEEDING] quiz_bank is already seeded. Skipping.');
        return {
          'alreadySeeded': true,
          'totalCreated': 0,
          'totalSkipped': QuizBankData.initialQuestions.length,
        };
      }

      for (var question in QuizBankData.initialQuestions) {
        final docRef = _db.collection('quiz_bank').doc(question.id);
        final docSnap = await docRef.get();
        if (docSnap.exists) {
          skippedCount++;
        } else {
          await docRef.set(question.toMap());
          createdCount++;
        }
      }

      await sentinelRef.set({
        'isSeeded': true,
        'seededAt': FieldValue.serverTimestamp(),
        'questionCount': QuizBankData.initialQuestions.length,
      });

      print('[QUIZ BANK SEEDING] Finished. Created: $createdCount, Skipped: $skippedCount');
      return {
        'alreadySeeded': false,
        'totalCreated': createdCount,
        'totalSkipped': skippedCount,
      };
    } catch (e) {
      print('[QUIZ BANK SEEDING ERROR] $e');
      return {
        'error': e.toString(),
        'totalCreated': createdCount,
        'totalSkipped': skippedCount,
      };
    }
  }

  /// Load questions by topic and difficulty, randomly sampled up to [count].
  /// Never duplicates questions within an attempt.
  Future<List<QuizBankQuestion>> getQuizBankQuestions({
    required String topic,
    required String difficulty,
    required int count,
  }) async {
    List<QuizBankQuestion> questions = [];
    try {
      final querySnap = await _db
          .collection('quiz_bank')
          .where('topic', isEqualTo: topic)
          .where('difficulty', isEqualTo: difficulty)
          .get();

      if (querySnap.docs.isNotEmpty) {
        questions = querySnap.docs
            .map((doc) => QuizBankQuestion.fromMap(doc.data(), doc.id))
            .toList();
      }
    } catch (e) {
      print('Firestore error loading quiz_bank questions: $e');
    }

    // Fallback to local offline repository if Firestore has no questions or errors
    if (questions.isEmpty) {
      questions = QuizBankData.getQuestionsForTopic(topic, difficulty: difficulty);
    }

    // Shuffle randomly to provide distinct quiz attempts
    questions.shuffle();

    // If requested count is less than available, limit it; otherwise return all available without repeating
    if (questions.length > count) {
      return questions.sublist(0, count);
    }
    return questions;
  }

  /// Get total available question count for a topic and difficulty
  Future<int> getAvailableQuestionCount({
    required String topic,
    required String difficulty,
  }) async {
    try {
      final querySnap = await _db
          .collection('quiz_bank')
          .where('topic', isEqualTo: topic)
          .where('difficulty', isEqualTo: difficulty)
          .get();
      if (querySnap.docs.isNotEmpty) {
        return querySnap.docs.length;
      }
    } catch (e) {
      print('Firestore count error: $e');
    }
    return QuizBankData.getQuestionsForTopic(topic, difficulty: difficulty).length;
  }

  // In-memory session cache for quiz attempts & best scores (acts as fast fallback when Firestore remote rules are pending deployment)
  static final Map<String, List<QuizAttempt>> _sessionAttempts = {};
  static final Map<String, Map<String, double>> _sessionBestScores = {};

  /// Save student quiz attempt under student_quiz_history/{uid}/attempts/{attemptId}
  /// and update the student's best score summary.
  Future<void> saveQuizAttempt(QuizAttempt attempt) async {
    final effectiveUid = attempt.studentId.isNotEmpty
        ? attempt.studentId
        : (FirebaseAuth.instance.currentUser?.uid ?? 'anonymous');

    // 1. Immediately store in local session cache
    final list = _sessionAttempts.putIfAbsent(effectiveUid, () => []);
    list.removeWhere((a) => a.id == attempt.id);
    list.insert(0, attempt);

    final bestMap = _sessionBestScores.putIfAbsent(effectiveUid, () => {});
    final prevSessionBest = bestMap[attempt.topic] ?? 0.0;
    if (attempt.percentage > prevSessionBest) {
      bestMap[attempt.topic] = attempt.percentage;
    }

    // 2. Persist to Cloud Firestore
    try {
      final attemptRef = _db
          .collection('student_quiz_history')
          .doc(effectiveUid)
          .collection('attempts')
          .doc(attempt.id);

      await attemptRef.set(attempt.toMap());

      // Update best score summary in student's parent document
      final summaryDocRef = _db.collection('student_quiz_history').doc(effectiveUid);
      final summarySnap = await summaryDocRef.get();

      Map<String, dynamic> bestScores = {};
      if (summarySnap.exists && summarySnap.data() != null) {
        final raw = summarySnap.data()!['bestScores'];
        if (raw is Map) {
          bestScores = Map<String, dynamic>.from(raw);
        }
      }

      final prevBest = (bestScores[attempt.topic] as num?)?.toDouble() ?? 0.0;
      if (attempt.percentage > prevBest) {
        bestScores[attempt.topic] = attempt.percentage;
      }

      await summaryDocRef.set({
        'studentId': effectiveUid,
        'lastAttemptAt': FieldValue.serverTimestamp(),
        'bestScores': bestScores,
      }, SetOptions(merge: true));

      print('[QUIZ ZONE] Saved attempt ${attempt.id} for student $effectiveUid to Firestore');
    } catch (e) {
      print('[QUIZ ZONE WARNING] Attempt cached in session; Firestore sync pending rules: $e');
    }
  }

  /// Stream of quiz attempts for the authenticated student (resilient with instant local emission)
  Stream<List<QuizAttempt>> getStudentQuizHistory([String? studentId]) {
    final effectiveUid = studentId ?? FirebaseAuth.instance.currentUser?.uid;
    if (effectiveUid == null || effectiveUid.isEmpty) {
      return Stream.value(<QuizAttempt>[]);
    }

    late StreamController<List<QuizAttempt>> controller;
    StreamSubscription? sub;

    controller = StreamController<List<QuizAttempt>>.broadcast(
      onListen: () {
        // Emit current session attempts immediately so UI never hangs
        final initialCached = List<QuizAttempt>.from(_sessionAttempts[effectiveUid] ?? []);
        controller.add(initialCached);

        sub = _db
            .collection('student_quiz_history')
            .doc(effectiveUid)
            .collection('attempts')
            .orderBy('timestamp', descending: true)
            .snapshots()
            .listen(
          (snapshot) {
            final fromDb = snapshot.docs
                .map((doc) => QuizAttempt.fromMap(doc.data(), doc.id))
                .toList();

            final Map<String, QuizAttempt> merged = {
              for (var a in fromDb) a.id: a,
              for (var a in (_sessionAttempts[effectiveUid] ?? [])) a.id: a,
            };
            final sorted = merged.values.toList()
              ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

            if (!controller.isClosed) {
              controller.add(sorted);
            }
          },
          onError: (error) {
            print('Firestore error in getStudentQuizHistory: $error');
            if (!controller.isClosed) {
              controller.add(List<QuizAttempt>.from(_sessionAttempts[effectiveUid] ?? []));
            }
          },
        );
      },
      onCancel: () {
        sub?.cancel();
      },
    );

    return controller.stream;
  }

  /// Stream of best scores per topic for the authenticated student
  Stream<Map<String, double>> getTopicBestScores([String? studentId]) {
    final effectiveUid = studentId ?? FirebaseAuth.instance.currentUser?.uid;
    if (effectiveUid == null || effectiveUid.isEmpty) {
      return Stream.value(<String, double>{});
    }

    late StreamController<Map<String, double>> controller;
    StreamSubscription? sub;

    controller = StreamController<Map<String, double>>.broadcast(
      onListen: () {
        final initialCached = Map<String, double>.from(_sessionBestScores[effectiveUid] ?? {});
        controller.add(initialCached);

        sub = _db
            .collection('student_quiz_history')
            .doc(effectiveUid)
            .snapshots()
            .listen(
          (doc) {
            final Map<String, double> scores = Map<String, double>.from(_sessionBestScores[effectiveUid] ?? {});
            if (doc.exists && doc.data() != null) {
              final raw = doc.data()!['bestScores'];
              if (raw is Map) {
                for (var entry in raw.entries) {
                  scores[entry.key.toString()] = (entry.value as num).toDouble();
                }
              }
            }
            if (!controller.isClosed) {
              controller.add(scores);
            }
          },
          onError: (error) {
            print('Firestore error in getTopicBestScores: $error');
            if (!controller.isClosed) {
              controller.add(Map<String, double>.from(_sessionBestScores[effectiveUid] ?? {}));
            }
          },
        );
      },
      onCancel: () {
        sub?.cancel();
      },
    );

    return controller.stream;
  }

  /// Dynamic topic retrieval: merges Firestore topics with predefined topics so any
  /// new topics added in Firestore automatically show up in the UI without modifying code!
  Future<List<QuizTopicMeta>> getAvailableQuizTopics() async {
    final Map<String, QuizTopicMeta> topicMap = {
      for (var t in QuizBankData.topics) t.topic.toLowerCase(): t,
    };

    try {
      final snapshot = await _db.collection('quiz_bank').get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final topicName = data['topic']?.toString() ?? '';
        final category = data['category']?.toString() ?? 'General Knowledge';
        if (topicName.isNotEmpty && !topicMap.containsKey(topicName.toLowerCase())) {
          topicMap[topicName.toLowerCase()] = QuizTopicMeta(
            topic: topicName,
            category: category,
            description: 'Practice and test your knowledge in $topicName',
            iconKey: 'quiz',
          );
        }
      }
    } catch (e) {
      print('Firestore warning in getAvailableQuizTopics: $e');
    }

    return topicMap.values.toList();
  }

  // --- Safe One-Time Seed Data ---
  Future<Map<String, dynamic>> seedDatabaseIfEmpty() async {
    print('=== [FIRESTORE SEEDING] Starting safe verification and seeding ===');

    int createdCount = 0;
    int skippedCount = 0;
    final Map<String, int> createdByCollection = {
      'courses': 0,
      'lessons': 0,
      'quizzes': 0,
      'quiz_questions': 0,
      'student_progress': 0,
    };
    final Map<String, int> skippedByCollection = {
      'courses': 0,
      'lessons': 0,
      'quizzes': 0,
      'quiz_questions': 0,
      'student_progress': 0,
    };
    bool sentinelCreated = false;

    // Reference to sentinel document
    final sentinelDocRef = _db.collection('_metadata').doc('seeding');

    try {
      final sentinelInitialSnap = await sentinelDocRef.get();
      if (sentinelInitialSnap.exists) {
        print('[FIRESTORE SEEDING] Database is already seeded (_metadata/seeding sentinel exists). Skipping seeding.');
        return {
          'totalCreated': 0,
          'totalSkipped': MockData.courses.length + MockData.lessons.length + MockData.quizzes.length + 3 + 1,
          'createdByCollection': createdByCollection,
          'skippedByCollection': {
            'courses': MockData.courses.length,
            'lessons': MockData.lessons.length,
            'quizzes': MockData.quizzes.length,
            'quiz_questions': 3,
            'student_progress': 1,
          },
          'sentinelCreated': false,
        };
      }

      // 1. Courses (6 documents: c1 to c6)
      for (var course in MockData.courses) {
        final docRef = _db.collection('courses').doc(course.id);
        final docSnap = await docRef.get();
        if (docSnap.exists) {
          skippedCount++;
          skippedByCollection['courses'] = (skippedByCollection['courses'] ?? 0) + 1;
          print('[SEED_SKIPPED] courses/${course.id} already exists');
        } else {
          await docRef.set({
            'title': course.title,
            'description': course.description,
            'instructor': course.instructor,
            'category': course.category,
            'image': course.imageUrl,
            'totalLessons': course.totalLessons,
            'progress': course.progress,
          });
          createdCount++;
          createdByCollection['courses'] = (createdByCollection['courses'] ?? 0) + 1;
          print('[SEED_CREATED] courses/${course.id}');
        }
      }

      // 2. Lessons (17 documents: l1 to l17)
      int lessonOrder = 0;
      for (var lesson in MockData.lessons) {
        final docRef = _db.collection('lessons').doc(lesson.id);
        final docSnap = await docRef.get();
        if (docSnap.exists) {
          skippedCount++;
          skippedByCollection['lessons'] = (skippedByCollection['lessons'] ?? 0) + 1;
          // Safely backfill videoUrl if missing in the existing document without overwriting any other field
          final existingData = docSnap.data() as Map<String, dynamic>?;
          if (lesson.videoUrl != null &&
              lesson.videoUrl!.isNotEmpty &&
              (existingData?['videoUrl'] as String?)?.trim().isNotEmpty != true) {
            await docRef.set({'videoUrl': lesson.videoUrl}, SetOptions(merge: true));
            print('[SEED_VIDEO_BACKFILLED] lessons/${lesson.id}');
          }
          print('[SEED_SKIPPED] lessons/${lesson.id} already exists');
        } else {
          final Map<String, dynamic> lessonData = {
            'courseId': lesson.courseId,
            'title': lesson.title,
            'description': lesson.description,
            'duration': lesson.duration,
            'module': lesson.module,
            'order': lessonOrder,
          };
          if (lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty) {
            lessonData['videoUrl'] = lesson.videoUrl;
          }
          await docRef.set(lessonData);
          createdCount++;
          createdByCollection['lessons'] = (createdByCollection['lessons'] ?? 0) + 1;
          print('[SEED_CREATED] lessons/${lesson.id}');
        }
        lessonOrder++;
      }

      // 3. Quizzes (1 document: q1)
      for (var quiz in MockData.quizzes) {
        final docRef = _db.collection('quizzes').doc(quiz.id);
        final docSnap = await docRef.get();
        if (docSnap.exists) {
          skippedCount++;
          skippedByCollection['quizzes'] = (skippedByCollection['quizzes'] ?? 0) + 1;
          print('[SEED_SKIPPED] quizzes/${quiz.id} already exists');
        } else {
          await docRef.set({
            'courseId': quiz.courseId,
            'title': quiz.title,
            'description': quiz.description,
            'passingScore': 70,
          });
          createdCount++;
          createdByCollection['quizzes'] = (createdByCollection['quizzes'] ?? 0) + 1;
          print('[SEED_CREATED] quizzes/${quiz.id}');
        }

        // 4. Quiz Questions (3 questions under q1: q1_q0, q1_q1, q1_q2)
        int questionIndex = 0;
        for (var q in quiz.questions) {
          final qDocId = '${quiz.id}_q$questionIndex';
          final qDocRef = _db.collection('quiz_questions').doc(qDocId);
          final qDocSnap = await qDocRef.get();
          if (qDocSnap.exists) {
            skippedCount++;
            skippedByCollection['quiz_questions'] = (skippedByCollection['quiz_questions'] ?? 0) + 1;
            print('[SEED_SKIPPED] quiz_questions/$qDocId already exists');
          } else {
            await qDocRef.set({
              'quizId': quiz.id,
              'question': q.question,
              'options': q.options,
              'correctAnswer': q.correctOptionIndex,
            });
            createdCount++;
            createdByCollection['quiz_questions'] = (createdByCollection['quiz_questions'] ?? 0) + 1;
            print('[SEED_CREATED] quiz_questions/$qDocId');
          }
          questionIndex++;
        }
      }

      // 5. Student Progress (1 document: s1)
      final studentDocRef = _db.collection('student_progress').doc(MockData.currentUser.id);
      final studentDocSnap = await studentDocRef.get();
      if (studentDocSnap.exists) {
        skippedCount++;
        skippedByCollection['student_progress'] = (skippedByCollection['student_progress'] ?? 0) + 1;
        print('[SEED_SKIPPED] student_progress/${MockData.currentUser.id} already exists');
      } else {
        await studentDocRef.set({
          'name': MockData.currentUser.name,
          'email': MockData.currentUser.email,
          'avatarUrl': MockData.currentUser.avatarUrl,
          'quizScore': MockData.currentUser.totalPoints,
          'coursesCompleted': MockData.currentUser.coursesCompleted,
          'completedLessons': MockData.currentUser.completedLessons,
        });
        createdCount++;
        createdByCollection['student_progress'] = (createdByCollection['student_progress'] ?? 0) + 1;
        print('[SEED_CREATED] student_progress/${MockData.currentUser.id}');
      }

      // 6. Sentinel Document (_metadata/seeding)
      // Created only after successful seeding of data
      final sentinelSnapAfter = await sentinelDocRef.get();
      if (!sentinelSnapAfter.exists) {
        await sentinelDocRef.set({
          'isSeeded': true,
          'seededAt': FieldValue.serverTimestamp(),
          'project': 'miner-project-39b4a',
          'database': '(default)',
          'coursesVerified': MockData.courses.length,
          'lessonsVerified': MockData.lessons.length,
          'quizzesVerified': MockData.quizzes.length,
          'quizQuestionsVerified': 3,
          'studentVerified': MockData.currentUser.id,
        });
        sentinelCreated = true;
        print('[SEED_CREATED] _metadata/seeding sentinel created successfully.');
      } else {
        print('[SEED_SKIPPED] _metadata/seeding sentinel already exists');
      }
    } catch (e, stack) {
      print('[FIRESTORE SEEDING ERROR] Exception during seeding: $e\n$stack');
      rethrow;
    }

    final summary = {
      'totalCreated': createdCount,
      'totalSkipped': skippedCount,
      'createdByCollection': createdByCollection,
      'skippedByCollection': skippedByCollection,
      'sentinelCreated': sentinelCreated,
    };

    print('=== [FIRESTORE SEEDING REPORT] ===');
    print('TOTAL DOCUMENTS CREATED: $createdCount');
    print('TOTAL DOCUMENTS SKIPPED: $skippedCount');
    print('Breakdown Created: $createdByCollection');
    print('Breakdown Skipped: $skippedByCollection');
    print('Sentinel Created: $sentinelCreated');
    print('==================================');

    return summary;
  }
}
