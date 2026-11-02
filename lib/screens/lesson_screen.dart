import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../services/firestore_service.dart';
import '../widgets/lesson_video_player.dart';

class LessonScreen extends StatefulWidget {
  final Lesson lesson;
  final Course course;
  final List<Lesson> allLessons;

  const LessonScreen({
    super.key,
    required this.lesson,
    required this.course,
    required this.allLessons,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late Lesson _currentLesson;

  @override
  void initState() {
    super.initState();
    _currentLesson = widget.lesson;
  }

  List<Lesson> get _courseLessons {
    return widget.allLessons;
  }

  int get _currentIndex {
    return _courseLessons.indexWhere((l) => l.id == _currentLesson.id);
  }

  void _navigateToLesson(int index) {
    if (index >= 0 && index < _courseLessons.length) {
      setState(() {
        _currentLesson = _courseLessons[index];
      });
    }
  }

  void _toggleMarkComplete() async {
    final newState = !_currentLesson.isCompleted;
    setState(() {
      _currentLesson.isCompleted = newState;
      final idx = _courseLessons.indexWhere((l) => l.id == _currentLesson.id);
      if (idx != -1) {
        _courseLessons[idx].isCompleted = newState;
      }
    });

    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid != null) {
        await FirestoreService().updateLessonCompletion(
          _currentLesson.id,
          newState,
          studentId: currentUid,
        );
      }
    } catch (e) {
      print('Failed to update completion status: $e');
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _currentLesson.isCompleted
              ? 'Lesson marked as complete!'
              : 'Lesson marked as incomplete.',
        ),
        backgroundColor: _currentLesson.isCompleted ? Colors.green : Theme.of(context).colorScheme.secondary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lessons = _courseLessons;
    final currentIndex = _currentIndex;
    final hasPrevious = currentIndex > 0;
    final hasNext = currentIndex < lessons.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.title),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Embedded YouTube Video Player or Placeholder
            LessonVideoPlayer(
              key: ValueKey(_currentLesson.id),
              videoUrl: _currentLesson.videoUrl,
              lessonTitle: _currentLesson.title,
            ),
            const SizedBox(height: 20),

            // Module Badge & Duration Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _currentLesson.module,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  _currentLesson.duration,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Lesson Title
            Text(
              _currentLesson.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Lesson Content / Description
            Text(
              'Lesson Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _currentLesson.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),

            // Additional Text-Based Lesson Content from Firestore (if present & distinct)
            if (_currentLesson.content != null &&
                _currentLesson.content!.trim().isNotEmpty &&
                _currentLesson.content!.trim() != _currentLesson.description.trim()) ...[
              const SizedBox(height: 20),
              Text(
                'Lesson Content',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _currentLesson.content!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],

            // Optional External PDF Resource (without Firebase Storage uploads)
            if (_currentLesson.pdfUrl != null && _currentLesson.pdfUrl!.trim().isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.picture_as_pdf,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lesson Resource (PDF)',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _currentLesson.pdfUrl!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),

            // Mark Complete Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: _currentLesson.isCompleted
                  ? OutlinedButton.icon(
                      onPressed: _toggleMarkComplete,
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      label: const Text(
                        'Completed ✓ (Tap to Undo)',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.green, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  : FilledButton.icon(
                      onPressed: _toggleMarkComplete,
                      icon: const Icon(Icons.check),
                      label: const Text(
                        'Mark as Complete',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 24),

            const Divider(),
            const SizedBox(height: 16),

            // Previous / Next Navigation Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: hasPrevious ? () => _navigateToLesson(currentIndex - 1) : null,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Previous'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: hasNext ? () => _navigateToLesson(currentIndex + 1) : null,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Next'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
