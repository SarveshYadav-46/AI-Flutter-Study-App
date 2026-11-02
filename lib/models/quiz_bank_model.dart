class QuizBankQuestion {
  final String id;
  final String topic;
  final String category;
  final String difficulty; // 'Easy', 'Medium', 'Hard'
  final String question;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;
  final int marks;

  QuizBankQuestion({
    required this.id,
    required this.topic,
    required this.category,
    required this.difficulty,
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
    this.marks = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'topic': topic,
      'category': category,
      'difficulty': difficulty,
      'question': question,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'explanation': explanation,
      'marks': marks,
    };
  }

  factory QuizBankQuestion.fromMap(Map<String, dynamic> map, [String? docId]) {
    final rawOptions = map['options'];
    List<String> parsedOptions = [];
    if (rawOptions is List) {
      parsedOptions = rawOptions.map((e) => e.toString()).toList();
    }

    return QuizBankQuestion(
      id: docId ?? (map['id']?.toString() ?? ''),
      topic: map['topic']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      difficulty: map['difficulty']?.toString() ?? 'Medium',
      question: map['question']?.toString() ?? '',
      options: parsedOptions,
      correctOptionIndex: (map['correctOptionIndex'] as num?)?.toInt() ?? 0,
      explanation: map['explanation']?.toString() ?? '',
      marks: (map['marks'] as num?)?.toInt() ?? 1,
    );
  }
}

class QuizAttempt {
  final String id;
  final String studentId;
  final String topic;
  final String category;
  final String difficulty;
  final String mode; // 'Practice' or 'Timed'
  final int score;
  final int totalQuestions;
  final double percentage;
  final int timeTakenSeconds;
  final DateTime timestamp;

  QuizAttempt({
    required this.id,
    required this.studentId,
    required this.topic,
    required this.category,
    required this.difficulty,
    required this.mode,
    required this.score,
    required this.totalQuestions,
    required this.percentage,
    required this.timeTakenSeconds,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'topic': topic,
      'category': category,
      'difficulty': difficulty,
      'mode': mode,
      'score': score,
      'totalQuestions': totalQuestions,
      'percentage': percentage,
      'timeTakenSeconds': timeTakenSeconds,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory QuizAttempt.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parsedDate;
    final rawTs = map['timestamp'];
    if (rawTs is String) {
      parsedDate = DateTime.tryParse(rawTs) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return QuizAttempt(
      id: docId ?? (map['id']?.toString() ?? ''),
      studentId: map['studentId']?.toString() ?? '',
      topic: map['topic']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      difficulty: map['difficulty']?.toString() ?? 'Medium',
      mode: map['mode']?.toString() ?? 'Practice',
      score: (map['score'] as num?)?.toInt() ?? 0,
      totalQuestions: (map['totalQuestions'] as num?)?.toInt() ?? 0,
      percentage: (map['percentage'] as num?)?.toDouble() ?? 0.0,
      timeTakenSeconds: (map['timeTakenSeconds'] as num?)?.toInt() ?? 0,
      timestamp: parsedDate,
    );
  }
}

class QuizTopicMeta {
  final String topic;
  final String category;
  final String description;
  final String iconKey;

  const QuizTopicMeta({
    required this.topic,
    required this.category,
    required this.description,
    required this.iconKey,
  });
}
