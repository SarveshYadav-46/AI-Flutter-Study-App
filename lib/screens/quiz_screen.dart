import 'package:flutter/material.dart';
import '../models/models.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends StatefulWidget {
  final Quiz quiz;

  const QuizScreen({super.key, required this.quiz});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  int _score = 0;
  int? _selectedOptionIndex;
  bool _isAnswerChecked = false;

  void _checkAnswer() {
    if (_selectedOptionIndex == null) return;

    setState(() {
      _isAnswerChecked = true;
      if (_selectedOptionIndex == widget.quiz.questions[_currentQuestionIndex].correctOptionIndex) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedOptionIndex = null;
        _isAnswerChecked = false;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizResultScreen(
            quiz: widget.quiz,
            score: _score,
            totalQuestions: widget.quiz.questions.length,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.quiz.questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz.title),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question ${_currentQuestionIndex + 1} of ${widget.quiz.questions.length}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              question.question,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: ListView.builder(
                itemCount: question.options.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedOptionIndex == index;
                  final isCorrect = index == question.correctOptionIndex;
                  
                  Color getBackgroundColor() {
                    if (!_isAnswerChecked) {
                      return isSelected ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surface;
                    }
                    if (isCorrect) return Colors.green.withValues(alpha: 0.2);
                    if (isSelected && !isCorrect) return Colors.red.withValues(alpha: 0.2);
                    return Theme.of(context).colorScheme.surface;
                  }

                  Color getBorderColor() {
                    if (!_isAnswerChecked) {
                      return isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant;
                    }
                    if (isCorrect) return Colors.green;
                    if (isSelected && !isCorrect) return Colors.red;
                    return Theme.of(context).colorScheme.outlineVariant;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: InkWell(
                      onTap: _isAnswerChecked
                          ? null
                          : () {
                              setState(() {
                                _selectedOptionIndex = index;
                              });
                            },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: getBackgroundColor(),
                          border: Border.all(color: getBorderColor(), width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                question.options[index],
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                              ),
                            ),
                            if (_isAnswerChecked && isCorrect)
                              const Icon(Icons.check_circle, color: Colors.green),
                            if (_isAnswerChecked && isSelected && !isCorrect)
                              const Icon(Icons.cancel, color: Colors.red),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _selectedOptionIndex == null
                    ? null
                    : (_isAnswerChecked ? _nextQuestion : _checkAnswer),
                child: Text(
                  _isAnswerChecked
                      ? (_currentQuestionIndex == widget.quiz.questions.length - 1 ? 'Finish' : 'Next Question')
                      : 'Check Answer',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
