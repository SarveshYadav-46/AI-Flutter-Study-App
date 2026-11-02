import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/progress_card.dart';
import '../services/firestore_service.dart';
import '../models/models.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authUser = FirebaseAuth.instance.currentUser;
    final currentUid = authUser?.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Progress'),
        centerTitle: true,
      ),
      body: StreamBuilder<Student>(
        stream: FirestoreService().getStudentProgress(currentUid),
        builder: (context, studentSnapshot) {
          final student = studentSnapshot.data ??
              Student(
                id: currentUid ?? '',
                name: authUser?.displayName ?? (authUser?.email?.split('@').first ?? 'Student'),
                email: authUser?.email ?? '',
                avatarUrl: authUser?.photoURL ?? '',
                totalPoints: 0,
                coursesCompleted: 0,
                completedLessons: const [],
              );

          return StreamBuilder<List<Course>>(
            stream: FirestoreService().getCourses(currentUid),
            builder: (context, coursesSnapshot) {
              if (coursesSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (coursesSnapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'Failed to load progress: ${FirestoreService.getReadableFirestoreError(coursesSnapshot.error)}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                );
              }

              final courses = coursesSnapshot.data ?? [];

              int completedLessons = student.completedLessons.length;
              double avgProgress = courses.isNotEmpty
                  ? courses.fold(0.0, (sum, c) => sum + c.progress) / courses.length
                  : 0.0;
              String overallProgress = '${(avgProgress * 100).toInt()}%';
              int completedQuizzes = student.totalPoints > 0 ? (student.totalPoints ~/ 10) : 0;
              String quizScore = '${student.totalPoints}';

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overview',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        ProgressCard(
                          title: 'Overall Progress',
                          value: overallProgress,
                          icon: Icons.trending_up,
                          color: Colors.blue,
                        ),
                        ProgressCard(
                          title: 'Completed Lessons',
                          value: '$completedLessons',
                          icon: Icons.play_lesson,
                          color: Colors.green,
                        ),
                        ProgressCard(
                          title: 'Completed Quizzes',
                          value: '$completedQuizzes',
                          icon: Icons.quiz,
                          color: Colors.orange,
                        ),
                        ProgressCard(
                          title: 'Total Points',
                          value: quizScore,
                          icon: Icons.grade,
                          color: Colors.purple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Course Progress',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    if (courses.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          'No courses found to display progress.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: courses.length,
                        itemBuilder: (context, index) {
                          final course = courses[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        course.title,
                                        style: Theme.of(context).textTheme.titleMedium,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '${(course.progress * 100).toInt()}%',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: course.progress,
                                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                                  color: Theme.of(context).colorScheme.primary,
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 32),
                    Text(
                      'Recent Activity',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    if (student.completedLessons.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          'No recent learning activity yet. Complete lessons to track your progress here!',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      )
                    else
                      ListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: student.completedLessons.map((lessonId) {
                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Icon(Icons.check, color: Colors.white),
                            ),
                            title: Text('Completed Lesson ($lessonId)'),
                            subtitle: const Text('Recently completed'),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
