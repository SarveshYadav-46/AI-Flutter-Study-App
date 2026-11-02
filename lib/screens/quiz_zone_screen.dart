import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/quiz_bank_model.dart';
import '../services/firestore_service.dart';
import '../utils/quiz_bank_data.dart';
import 'quiz_history_screen.dart';
import 'quiz_play_screen.dart';

class QuizZoneScreen extends StatefulWidget {
  const QuizZoneScreen({super.key});

  @override
  State<QuizZoneScreen> createState() => _QuizZoneScreenState();
}

class _QuizZoneScreenState extends State<QuizZoneScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'All';
  String _searchQuery = '';
  List<QuizTopicMeta> _allTopics = QuizBankData.topics;
  bool _isLoadingTopics = false;

  @override
  void initState() {
    super.initState();
    _initQuizZone();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initQuizZone() async {
    // 1. One-time safe seed check for quiz_bank collection
    _firestoreService.seedQuizBankIfEmpty().ignore();

    // 2. Fetch available topics dynamically so newly added Firestore topics show up
    setState(() => _isLoadingTopics = true);
    final dynamicTopics = await _firestoreService.getAvailableQuizTopics();
    if (mounted) {
      setState(() {
        _allTopics = dynamicTopics;
        _isLoadingTopics = false;
      });
    }
  }

  IconData _resolveIcon(String iconKey) {
    switch (iconKey.toLowerCase()) {
      case 'coffee':
        return Icons.coffee;
      case 'terminal':
        return Icons.terminal;
      case 'code':
        return Icons.code;
      case 'javascript':
        return Icons.javascript;
      case 'account_tree':
        return Icons.account_tree;
      case 'storage':
        return Icons.storage;
      case 'memory':
        return Icons.memory;
      case 'hub':
        return Icons.hub;
      case 'psychology':
        return Icons.psychology;
      case 'auto_graph':
        return Icons.auto_graph;
      case 'bubble_chart':
        return Icons.bubble_chart;
      case 'forum':
        return Icons.forum;
      case 'html':
        return Icons.html;
      case 'css':
        return Icons.css;
      case 'widgets':
        return Icons.widgets;
      case 'calculate':
        return Icons.calculate;
      case 'lightbulb':
        return Icons.lightbulb;
      case 'public':
        return Icons.public;
      default:
        return Icons.quiz;
    }
  }

  void _showQuizConfigSheet(BuildContext context, QuizTopicMeta topicMeta) {
    String selectedDifficulty = 'Medium';
    int selectedQuestionCount = 10;
    String selectedMode = 'Practice'; // 'Practice' or 'Timed'

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _resolveIcon(topicMeta.iconKey),
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              topicMeta.topic,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              topicMeta.category,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(modalContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Difficulty Selector
                  Text(
                    'Select Difficulty',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Easy', label: Text('Easy')),
                      ButtonSegment(value: 'Medium', label: Text('Medium')),
                      ButtonSegment(value: 'Hard', label: Text('Hard')),
                    ],
                    selected: {selectedDifficulty},
                    onSelectionChanged: (newSelection) {
                      setModalState(() {
                        selectedDifficulty = newSelection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 18),

                  // Question Count Selector
                  Text(
                    'Number of Questions',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [5, 10, 15, 20].map((count) {
                      final isSelected = selectedQuestionCount == count;
                      return ChoiceChip(
                        label: Text('$count Qs'),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() {
                              selectedQuestionCount = count;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // Quiz Mode Selector
                  Text(
                    'Quiz Mode',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setModalState(() => selectedMode = 'Practice');
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: selectedMode == 'Practice'
                                  ? Colors.teal.shade50
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedMode == 'Practice'
                                    ? Colors.teal
                                    : Colors.grey.shade300,
                                width: selectedMode == 'Practice' ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.school_outlined,
                                      size: 18,
                                      color: selectedMode == 'Practice'
                                          ? Colors.teal.shade900
                                          : Colors.grey.shade700,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Practice',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: selectedMode == 'Practice'
                                          ? Colors.teal.shade900
                                          : Colors.grey.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Instant explanations after each question',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: selectedMode == 'Practice'
                                        ? Colors.teal.shade800
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setModalState(() => selectedMode = 'Timed');
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: selectedMode == 'Timed'
                                  ? Colors.purple.shade50
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedMode == 'Timed'
                                    ? Colors.purple
                                    : Colors.grey.shade300,
                                width: selectedMode == 'Timed' ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.timer_outlined,
                                      size: 18,
                                      color: selectedMode == 'Timed'
                                          ? Colors.purple.shade900
                                          : Colors.grey.shade700,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Timed',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: selectedMode == 'Timed'
                                          ? Colors.purple.shade900
                                          : Colors.grey.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Countdown timer with auto-submit',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: selectedMode == 'Timed'
                                        ? Colors.purple.shade800
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Start Quiz Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text(
                      'Start Quiz',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.pop(modalContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuizPlayScreen(
                            topic: topicMeta.topic,
                            difficulty: selectedDifficulty,
                            questionCount: selectedQuestionCount,
                            mode: selectedMode,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    // Filter topics by category and search text
    final filteredTopics = _allTopics.where((t) {
      final matchesCategory = _selectedCategory == 'All' ||
          t.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          t.topic.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.category.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Zone'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Quiz History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QuizHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<Map<String, double>>(
        stream: _firestoreService.getTopicBestScores(user?.uid),
        builder: (context, bestScoresSnapshot) {
          final bestScores = bestScoresSnapshot.data ?? {};

          return Column(
            children: [
              // Search Box
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search topics (e.g. Java, DSA, Machine Learning)',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() => _searchQuery = val.trim());
                  },
                ),
              ),

              // Categories Horizontal Scroll List
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: QuizBankData.categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final cat = QuizBankData.categories[idx];
                    final isSelected = _selectedCategory == cat;
                    return ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategory = cat);
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),

              // Topic Cards List
              Expanded(
                child: _isLoadingTopics
                    ? const Center(child: CircularProgressIndicator())
                    : filteredTopics.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                'No topics found matching "$_searchQuery".',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredTopics.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, idx) {
                              final topicMeta = filteredTopics[idx];
                              final bestScore = bestScores[topicMeta.topic];

                              // Calculate total questions available locally or default
                              final totalQs = QuizBankData.getQuestionsForTopic(topicMeta.topic).length;

                              return Card(
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: InkWell(
                                  onTap: () => _showQuizConfigSheet(context, topicMeta),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        // Topic Icon
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primaryContainer,
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: Icon(
                                            _resolveIcon(topicMeta.iconKey),
                                            size: 28,
                                            color: theme.colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                        const SizedBox(width: 16),

                                        // Topic Info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      topicMeta.topic,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                  if (bestScore != null)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.green.shade50,
                                                        borderRadius: BorderRadius.circular(6),
                                                        border: Border.all(
                                                          color: Colors.green.shade300,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        'Best: ${bestScore.toStringAsFixed(0)}%',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.green.shade800,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                topicMeta.description,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey.shade100,
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      topicMeta.category,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.grey.shade700,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    '$totalQs questions bank',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey.shade500,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Icon(
                                                    Icons.arrow_forward_ios,
                                                    size: 14,
                                                    color: Colors.grey.shade400,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}
