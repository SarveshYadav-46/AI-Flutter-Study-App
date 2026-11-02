import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/firestore_service.dart';
import '../widgets/lesson_card.dart';
import 'lesson_screen.dart';

class CourseDetailsScreen extends StatefulWidget {
  final Course course;

  const CourseDetailsScreen({super.key, required this.course});

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  void _openLesson(Lesson lesson, List<Lesson> allLessons) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonScreen(
          lesson: lesson,
          course: widget.course,
          allLessons: allLessons,
        ),
      ),
    );
  }

  void _startNextLesson(List<Lesson> lessons) {
    if (lessons.isEmpty) return;

    final nextIncomplete = lessons.firstWhere(
      (l) => !l.isCompleted,
      orElse: () => lessons.first,
    );
    _openLesson(nextIncomplete, lessons);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Lesson>>(
        stream: FirestoreService().getLessons(widget.course.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final lessons = snapshot.data ?? [];
          final completedCount = lessons.where((l) => l.isCompleted).length;
          final progress = lessons.isEmpty ? 0.0 : completedCount / lessons.length;
          widget.course.progress = progress;

          final Map<String, List<Lesson>> grouped = {};
          for (var lesson in lessons) {
            if (!grouped.containsKey(lesson.module)) {
              grouped[lesson.module] = [];
            }
            grouped[lesson.module]!.add(lesson);
          }

          return CustomScrollView(
            slivers: [
              // App Bar with Course Image
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      widget.course.imageUrl.trim().isNotEmpty
                          ? Image.network(
                              widget.course.imageUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  child: Center(
                                    child: SizedBox(
                                      width: 36,
                                      height: 36,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  child: Icon(
                                    Icons.image,
                                    size: 80,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.image,
                                size: 80,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.4),
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.course.category,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

          // Course Info Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    widget.course.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 6),

                  // Instructor
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Instructor: ${widget.course.instructor}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Stats Badges Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoChip(
                        context,
                        Icons.play_lesson,
                        '${lessons.length} Lessons',
                        Theme.of(context).colorScheme.secondaryContainer,
                        Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                      _buildInfoChip(
                        context,
                        Icons.check_circle_outline,
                        '$completedCount / ${lessons.length} Done',
                        Colors.green.withValues(alpha: 0.2),
                        Colors.green.shade800,
                      ),
                      _buildInfoChip(
                        context,
                        Icons.star_outline,
                        '4.8 Rating',
                        Theme.of(context).colorScheme.tertiaryContainer,
                        Theme.of(context).colorScheme.onTertiaryContainer,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Progress Bar & Percentage
                  Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Course Progress',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                            backgroundColor: Theme.of(context).colorScheme.outlineVariant,
                            color: progress >= 1.0 ? Colors.green : Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Course Description
                  Text(
                    'About This Course',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.course.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 24),

                  // Start / Continue Learning Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: lessons.isEmpty ? null : () => _startNextLesson(lessons),
                      icon: Icon(progress >= 1.0 ? Icons.replay : Icons.play_arrow),
                      label: Text(
                        progress >= 1.0
                            ? 'Review Course'
                            : (progress == 0.0 ? 'Start Course' : 'Continue Learning'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Lessons Header Title
                  Text(
                    'Course Curriculum',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Lessons List organized into Modules
          if (grouped.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Text('No lessons available for this course yet.'),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, moduleIndex) {
                    final moduleName = grouped.keys.elementAt(moduleIndex);
                    final moduleLessons = grouped[moduleName]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Module Header
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.folder_open,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  moduleName,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Lessons under this module
                        ...moduleLessons.asMap().entries.map((entry) {
                          final lessonIndex = lessons.indexOf(entry.value);
                          final lesson = entry.value;

                          return LessonCard(
                            lesson: lesson,
                            index: lessonIndex,
                            onTap: () => _openLesson(lesson, lessons),
                          );
                        }),
                      ],
                    );
                  },
                  childCount: grouped.keys.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      );
      }),
    );
  }

  Widget _buildInfoChip(
    BuildContext context,
    IconData icon,
    String label,
    Color bg,
    Color fg,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: fg,
                ),
          ),
        ],
      ),
    );
  }
}
