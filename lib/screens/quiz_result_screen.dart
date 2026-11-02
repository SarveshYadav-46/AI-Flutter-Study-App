import 'package:flutter/material.dart';
import '../models/models.dart';

class QuizResultScreen extends StatelessWidget {
  final Quiz quiz;
  final int score;
  final int totalQuestions;

  const QuizResultScreen({
    super.key,
    required this.quiz,
    required this.score,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    final double percentage = (score / totalQuestions) * 100;
    final bool passed = percentage >= 70;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Results'),
        centerTitle: true,
        automaticallyImplyLeading: false, // Don't allow back to quiz
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                passed ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                size: 120,
                color: passed ? Colors.amber : Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                passed ? 'Congratulations!' : 'Keep Trying!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: passed ? Colors.green : Theme.of(context).colorScheme.error,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'You scored',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '$score / $totalQuestions',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Back to Course', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
