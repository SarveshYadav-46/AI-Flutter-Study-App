import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/quiz_bank_model.dart';
import '../services/firestore_service.dart';

class QuizHistoryScreen extends StatelessWidget {
  const QuizHistoryScreen({super.key});

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} • $hour:$minute $ampm';
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Quiz History'),
      ),
      body: user == null
          ? const Center(
              child: Text('Please sign in to view your quiz history.'),
            )
          : StreamBuilder<List<QuizAttempt>>(
              stream: FirestoreService().getStudentQuizHistory(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Failed to load history: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  );
                }

                final attempts = snapshot.data ?? [];
                if (attempts.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.quiz_outlined,
                            size: 72,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Quizzes Attempted Yet',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Head over to the Quiz Zone, pick any topic, and test your knowledge!',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Summary Stats
                final totalAttempts = attempts.length;
                final avgScore = attempts.map((a) => a.percentage).reduce((a, b) => a + b) / totalAttempts;
                final bestAttempt = attempts.reduce((a, b) => a.percentage > b.percentage ? a : b);

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Card(
                          elevation: 0,
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _SummaryColumn(
                                  label: 'Total Quizzes',
                                  value: '$totalAttempts',
                                  icon: Icons.assignment_outlined,
                                ),
                                _SummaryColumn(
                                  label: 'Avg Score',
                                  value: '${avgScore.toStringAsFixed(0)}%',
                                  icon: Icons.trending_up,
                                ),
                                _SummaryColumn(
                                  label: 'Best Score',
                                  value: '${bestAttempt.percentage.toStringAsFixed(0)}%',
                                  icon: Icons.star_outline,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final attempt = attempts[index];
                            final isPassed = attempt.percentage >= 60.0;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 1,
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
                                        Expanded(
                                          child: Text(
                                            attempt.topic,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isPassed ? Colors.green.shade50 : Colors.orange.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: isPassed ? Colors.green.shade300 : Colors.orange.shade300,
                                            ),
                                          ),
                                          child: Text(
                                            '${attempt.percentage.toStringAsFixed(0)}%',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isPassed ? Colors.green.shade800 : Colors.orange.shade800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        _Badge(text: attempt.category, color: Colors.blue),
                                        const SizedBox(width: 6),
                                        _Badge(
                                          text: attempt.difficulty,
                                          color: attempt.difficulty == 'Easy'
                                              ? Colors.green
                                              : (attempt.difficulty == 'Medium' ? Colors.orange : Colors.red),
                                        ),
                                        const SizedBox(width: 6),
                                        _Badge(
                                          text: attempt.mode,
                                          color: attempt.mode == 'Timed' ? Colors.purple : Colors.teal,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Score: ${attempt.score}/${attempt.totalQuestions} • Time: ${_formatTime(attempt.timeTakenSeconds)}',
                                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                        ),
                                        Text(
                                          _formatDate(attempt.timestamp),
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: attempts.length,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _SummaryColumn extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryColumn({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final MaterialColor color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: color.shade800, fontWeight: FontWeight.w500),
      ),
    );
  }
}
