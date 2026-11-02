import 'package:flutter/material.dart';
import '../models/quiz_bank_model.dart';
import 'quiz_history_screen.dart';
import 'quiz_play_screen.dart';

class QuizZoneResultScreen extends StatelessWidget {
  final QuizAttempt attempt;
  final List<QuizBankQuestion> questions;
  final Map<int, int> userAnswers; // questionIndex -> selectedOptionIndex

  const QuizZoneResultScreen({
    super.key,
    required this.attempt,
    required this.questions,
    required this.userAnswers,
  });

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
    final isPassed = attempt.percentage >= 60.0;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Results'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'View Quiz History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QuizHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Score Summary Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: isPassed
                  ? Colors.green.shade50
                  : Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Column(
                  children: [
                    Icon(
                      isPassed ? Icons.emoji_events : Icons.sentiment_neutral,
                      size: 64,
                      color: isPassed ? Colors.green.shade700 : Colors.orange.shade700,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isPassed ? 'Great Job!' : 'Keep Practicing!',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isPassed ? Colors.green.shade900 : Colors.orange.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${attempt.topic} • ${attempt.difficulty} • ${attempt.mode} Mode',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatItem(
                          label: 'Score',
                          value: '${attempt.score} / ${attempt.totalQuestions}',
                          icon: Icons.check_circle_outline,
                        ),
                        _StatItem(
                          label: 'Percentage',
                          value: '${attempt.percentage.toStringAsFixed(1)}%',
                          icon: Icons.percent,
                        ),
                        _StatItem(
                          label: 'Time Taken',
                          value: _formatTime(attempt.timeTakenSeconds),
                          icon: Icons.timer_outlined,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retake Quiz'),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuizPlayScreen(
                            topic: attempt.topic,
                            difficulty: attempt.difficulty,
                            questionCount: attempt.totalQuestions,
                            mode: attempt.mode,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.apps),
                    label: const Text('Other Topics'),
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Detailed Review Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question Review',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${questions.length} questions',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: questions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final q = questions[idx];
                final selected = userAnswers[idx];
                final isCorrect = selected == q.correctOptionIndex;
                final isUnanswered = selected == null;

                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isUnanswered
                                    ? Colors.grey.shade200
                                    : isCorrect
                                        ? Colors.green.shade100
                                        : Colors.red.shade100,
                              ),
                              child: Icon(
                                isUnanswered
                                    ? Icons.help_outline
                                    : isCorrect
                                        ? Icons.check
                                        : Icons.close,
                                size: 16,
                                color: isUnanswered
                                    ? Colors.grey.shade700
                                    : isCorrect
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Q${idx + 1}. ${q.question}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Options preview
                        ...List.generate(q.options.length, (optIdx) {
                          final optText = q.options[optIdx];
                          final isUserChoice = selected == optIdx;
                          final isCorrectAnswer = optIdx == q.correctOptionIndex;

                          Color? bgColor;
                          Color textColor = Colors.black87;
                          FontWeight fw = FontWeight.normal;

                          if (isCorrectAnswer) {
                            bgColor = Colors.green.shade50;
                            textColor = Colors.green.shade900;
                            fw = FontWeight.bold;
                          } else if (isUserChoice && !isCorrect) {
                            bgColor = Colors.red.shade50;
                            textColor = Colors.red.shade900;
                            fw = FontWeight.w600;
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: bgColor ?? Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isCorrectAnswer
                                    ? Colors.green.shade400
                                    : (isUserChoice ? Colors.red.shade400 : Colors.grey.shade300),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '${String.fromCharCode(65 + optIdx)}. ',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                                ),
                                Expanded(
                                  child: Text(
                                    optText,
                                    style: TextStyle(color: textColor, fontWeight: fw),
                                  ),
                                ),
                                if (isCorrectAnswer)
                                  const Icon(Icons.check_circle, size: 16, color: Colors.green)
                                else if (isUserChoice)
                                  const Icon(Icons.cancel, size: 16, color: Colors.red),
                              ],
                            ),
                          );
                        }),

                        // Explanation container
                        if (q.explanation.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info_outline, size: 16, color: Colors.blue.shade800),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    q.explanation,
                                    style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade700),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }
}
