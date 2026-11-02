export 'quiz_bank_model.dart';

class Course {
  final String id;
  final String title;
  final String description;
  final String instructor;
  double progress;
  final String imageUrl;
  final int totalLessons;
  final String category;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.instructor,
    required this.progress,
    required this.imageUrl,
    required this.totalLessons,
    required this.category,
  });
}

class Lesson {
  final String id;
  final String courseId;
  final String title;
  final String duration;
  final String module;
  final String description;
  final String? content;
  final String? videoUrl;
  final String? pdfUrl;
  bool isCompleted;

  Lesson({
    required this.id,
    required this.courseId,
    required this.title,
    required this.duration,
    required this.module,
    required this.description,
    this.content,
    this.videoUrl,
    this.pdfUrl,
    this.isCompleted = false,
  });

  bool get hasVideo => videoUrl != null && videoUrl!.trim().isNotEmpty;

  Map<String, dynamic> toMap({int? order}) {
    final map = <String, dynamic>{
      'courseId': courseId,
      'title': title,
      'description': description,
      'duration': duration,
      'module': module,
    };
    if (order != null) map['order'] = order;
    if (content != null) map['content'] = content;
    if (videoUrl != null) map['videoUrl'] = videoUrl;
    if (pdfUrl != null) map['pdfUrl'] = pdfUrl;
    return map;
  }

  factory Lesson.fromMap(
    Map<String, dynamic> data,
    String id, {
    bool isCompleted = false,
  }) {
    return Lesson(
      id: id,
      courseId: data['courseId'] ?? '',
      title: data['title'] ?? '',
      duration: data['duration'] ?? '',
      module: data['module'] ?? '',
      description: data['description'] ?? '',
      content: data['content'] as String?,
      videoUrl: data['videoUrl'] as String?,
      pdfUrl: data['pdfUrl'] as String?,
      isCompleted: isCompleted,
    );
  }

  Lesson copyWith({
    String? id,
    String? courseId,
    String? title,
    String? duration,
    String? module,
    String? description,
    String? content,
    String? videoUrl,
    String? pdfUrl,
    bool? isCompleted,
  }) {
    return Lesson(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      duration: duration ?? this.duration,
      module: module ?? this.module,
      description: description ?? this.description,
      content: content ?? this.content,
      videoUrl: videoUrl ?? this.videoUrl,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class Quiz {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final List<QuizQuestion> questions;

  Quiz({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.questions,
  });
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctOptionIndex;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctOptionIndex,
  });
}

class Student {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final int totalPoints;
  final int coursesCompleted;
  final List<String> completedLessons;

  Student({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.totalPoints,
    required this.coursesCompleted,
    this.completedLessons = const [],
  });

  bool isLessonCompleted(String lessonId) => completedLessons.contains(lessonId);

  Student copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    int? totalPoints,
    int? coursesCompleted,
    List<String>? completedLessons,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      totalPoints: totalPoints ?? this.totalPoints,
      coursesCompleted: coursesCompleted ?? this.coursesCompleted,
      completedLessons: completedLessons ?? this.completedLessons,
    );
  }
}
