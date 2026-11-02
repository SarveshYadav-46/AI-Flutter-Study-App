import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/quiz_bank_model.dart';
import '../services/firestore_service.dart';
import 'quiz_zone_result_screen.dart';

class QuizPlayScreen extends StatefulWidget {
  final String topic;
  final String difficulty;
  final int questionCount;
  final String mode; // 'Practice' or 'Timed'

  const QuizPlayScreen({
    super.key,
    required this.topic,
    required this.difficulty,
    required this.questionCount,
    required this.mode,
  });

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = true;
  String? _errorMessage;
  List<QuizBankQuestion> _questions = [];
  int _currentIndex = 0;

  // Track user selections: questionIndex -> selectedOptionIndex
  final Map<int, int> _userAnswers = {};

  // Timing tracking
  late DateTime _quizStartTime;
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  int _totalTimeSeconds = 0;
  bool _isSubmitted = false;

  @override
  void initState() {
    super.initState();
    _quizStartTime = DateTime.now();
    _loadQuestions();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final loaded = await _firestoreService.getQuizBankQuestions(
        topic: widget.topic,
        difficulty: widget.difficulty,
        count: widget.questionCount,
      );

      if (!mounted) return;

      if (loaded.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No questions found for ${widget.topic} (${widget.difficulty}).';
        });
        return;
      }

      setState(() {
        _questions = loaded;
        _isLoading = false;
        _quizStartTime = DateTime.now();

        // If Timed Mode, allocate 60 seconds per question
        if (widget.mode == 'Timed') {
          _totalTimeSeconds = _questions.length * 60;
          _remainingSeconds = _totalTimeSeconds;
          _startCountdownTimer();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading questions: $e';
      });
    }
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
        });
        _handleTimeExpiredAutoSubmit();
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  void _handleTimeExpiredAutoSubmit() {
    if (_isSubmitted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Time expired! Submitting your quiz now...'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
    _submitQuiz(isAutoSubmit: true);
  }

  void _selectOption(int optionIndex) {
    if (_isSubmitted) return;

    // In Practice mode, once answered, lock option so explanation stays visible
    if (widget.mode == 'Practice' && _userAnswers.containsKey(_currentIndex)) {
      return;
    }

    setState(() {
      _userAnswers[_currentIndex] = optionIndex;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  Future<void> _confirmAndSubmit() async {
    final unansweredCount = _questions.length - _userAnswers.length;

    if (unansweredCount > 0) {
      final shouldSubmit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unanswered Questions'),
          content: Text(
            'You have $unansweredCount unanswered question(s). Are you sure you want to submit?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep Reviewing'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Submit Now'),
            ),
          ],
        ),
      );

      if (shouldSubmit == true) {
        _submitQuiz();
      }
    } else {
      _submitQuiz();
    }
  }

  Future<void> _submitQuiz({bool isAutoSubmit = false}) async {
    if (_isSubmitted) return;
    _isSubmitted = true;
    _countdownTimer?.cancel();

    final endTime = DateTime.now();
    final timeTaken = endTime.difference(_quizStartTime).inSeconds;

    // Calculate score accurately
    int score = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_userAnswers[i] == _questions[i].correctOptionIndex) {
        score++;
      }
    }

    final double percentage = _questions.isNotEmpty
        ? (score / _questions.length) * 100.0
        : 0.0;

    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    final attemptId = 'attempt_${DateTime.now().millisecondsSinceEpoch}';

    final category = _questions.isNotEmpty ? _questions.first.category : 'General';

    final attempt = QuizAttempt(
      id: attemptId,
      studentId: currentUid,
      topic: widget.topic,
      category: category,
      difficulty: widget.difficulty,
      mode: widget.mode,
      score: score,
      totalQuestions: _questions.length,
      percentage: percentage,
      timeTakenSeconds: timeTaken,
      timestamp: DateTime.now(),
    );

    // Save attempt in background to student_quiz_history/{uid}
    await _firestoreService.saveQuizAttempt(attempt);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizZoneResultScreen(
          attempt: attempt,
          questions: _questions,
          userAnswers: _userAnswers,
        ),
      ),
    );
  }

  String _formatTimer(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<bool> _showExitConfirmation() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Quiz?'),
        content: const Text('Your current progress will not be saved if you leave now.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Resume Quiz'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    return shouldLeave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.topic)),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Preparing your quiz questions...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.topic)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.error, fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentQuestion = _questions[_currentIndex];
    final selectedOption = _userAnswers[_currentIndex];
    final isAnswered = selectedOption != null;

    final isPracticeMode = widget.mode == 'Practice';
    final isTimedMode = widget.mode == 'Timed';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldLeave = await _showExitConfirmation();
        if (shouldLeave && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.topic} (${widget.difficulty})'),
          actions: [
            if (isTimedMode)
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _remainingSeconds < 30 ? Colors.red.shade100 : colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer,
                          size: 16,
                          color: _remainingSeconds < 30 ? Colors.red.shade900 : colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimer(_remainingSeconds),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _remainingSeconds < 30 ? Colors.red.shade900 : colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            // Available question count notice if capped
            if (_questions.length < widget.questionCount)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                color: Colors.amber.shade100,
                child: Text(
                  'Note: Displaying all ${_questions.length} available questions in the question bank without repetition.',
                  style: TextStyle(color: Colors.amber.shade900, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),

            // Progress Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Question ${_currentIndex + 1} of ${_questions.length}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isPracticeMode ? Colors.teal.shade50 : Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.mode,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isPracticeMode ? Colors.teal.shade800 : Colors.purple.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (_currentIndex + 1) / _questions.length,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),

            // Question Card & Options
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          currentQuestion.question,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Options list
                    ...List.generate(currentQuestion.options.length, (optIdx) {
                      final optionText = currentQuestion.options[optIdx];
                      final isSelected = selectedOption == optIdx;
                      final isCorrect = optIdx == currentQuestion.correctOptionIndex;

                      Color borderColor = Colors.grey.shade300;
                      Color bgColor = Colors.white;
                      Color textColor = Colors.black87;

                      if (isPracticeMode && isAnswered) {
                        if (isCorrect) {
                          borderColor = Colors.green;
                          bgColor = Colors.green.shade50;
                          textColor = Colors.green.shade900;
                        } else if (isSelected) {
                          borderColor = Colors.red;
                          bgColor = Colors.red.shade50;
                          textColor = Colors.red.shade900;
                        }
                      } else if (isSelected) {
                        borderColor = colorScheme.primary;
                        bgColor = colorScheme.primaryContainer.withValues(alpha: 0.3);
                        textColor = colorScheme.primary;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: InkWell(
                          onTap: () => _selectOption(optIdx),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? (isPracticeMode
                                            ? (isCorrect ? Colors.green : Colors.red)
                                            : colorScheme.primary)
                                        : Colors.grey.shade200,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    String.fromCharCode(65 + optIdx),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    optionText,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: textColor,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isPracticeMode && isAnswered) ...[
                                  if (isCorrect)
                                    const Icon(Icons.check_circle, color: Colors.green)
                                  else if (isSelected)
                                    const Icon(Icons.cancel, color: Colors.red),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    // Practice Mode: Instant Explanation Card
                    if (isPracticeMode && isAnswered) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lightbulb_outline, size: 18, color: Colors.blue.shade800),
                                const SizedBox(width: 8),
                                Text(
                                  'Explanation',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              currentQuestion.explanation,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue.shade900,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom Navigation Controls
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Previous button
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _currentIndex > 0 ? _previousQuestion : null,
                      child: const Text('Previous'),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Next or Submit button
                  if (_currentIndex < _questions.length - 1)
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _nextQuestion,
                        child: const Text('Next'),
                      ),
                    )
                  else
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _confirmAndSubmit,
                        child: const Text('Submit Quiz'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
