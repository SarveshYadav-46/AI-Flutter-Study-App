import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';
import '../services/gemini_service.dart';

/// AI Academic Assistant screen with real Gemini 1.5 Flash integration.
///
/// Accepts an optional [aiService] for dependency injection in tests.
/// When [aiService] is null, uses [GeminiService] (production).
class AIAssistantScreen extends StatefulWidget {
  /// Optional AI service override — inject [MockAIService] in widget tests.
  final AIService? aiService;

  const AIAssistantScreen({super.key, this.aiService});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  late final AIService _aiService;
  late final GeminiService? _geminiService;

  bool _isSending = false;

  final List<ChatMessage> _messages = [
    ChatMessage(
      id: 'welcome',
      role: MessageRole.ai,
      text:
          'Hi! 👋 I\'m your AI Academic Assistant powered by Gemini.\n\nI can help you with Java, Python, C++, DSA, DBMS, OS, Networking, Web Development, AI/ML, and Aptitude.\n\nWhat would you like to learn today?',
      timestamp: DateTime.now(),
    ),
  ];

  final List<String> _suggestedQuestions = [
    'Explain Java OOP with examples',
    'Teach me binary search step by step',
    'Explain DBMS normalization',
    'What is machine learning?',
    'Create a study plan for DSA',
  ];

  // Whether the empty-state suggestions row should be visible
  bool get _showSuggestions => _messages.length == 1 && !_isSending;

  @override
  void initState() {
    super.initState();
    if (widget.aiService != null) {
      _aiService = widget.aiService!;
      _geminiService = null;
    } else {
      final svc = GeminiService();
      _aiService = svc;
      _geminiService = svc;
    }
  }

  // ---------------------------------------------------------------------------
  // Core send logic
  // ---------------------------------------------------------------------------

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();

    // Validation
    if (trimmed.isEmpty) {
      _showSnackBar('Please enter a message first.');
      return;
    }
    if (trimmed.length > GeminiService.maxMessageLength) {
      _showSnackBar(
          'Message is too long (max ${GeminiService.maxMessageLength} characters).');
      return;
    }
    if (_isSending) return; // Prevent duplicate sends

    final userMsg = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: MessageRole.user,
      text: trimmed,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isSending = true;
      _controller.clear();
    });

    _scrollToBottom();

    // Check availability before calling API
    final gemini = _geminiService;
    if (gemini != null && !gemini.isAvailable) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _addErrorMessage(
          'Live AI responses are currently awaiting secure backend configuration.\n\n'
          'Because the Firebase project is currently on the Spark plan, external outbound calls to the Gemini API require upgrading to the Blaze plan and deploying the server-side Cloud Function proxy.\n\n'
          'Once the secure backend is configured, real-time academic tutoring will be active.',
        );
      });
      _scrollToBottom();
      return;
    }

    try {
      // Pass recent history for context (exclude error messages)
      final history = _messages
          .where((m) => !m.isError)
          .toList();

      final responseText = await _aiService.sendMessage(
        userMessage: trimmed,
        history: history,
      );

      if (!mounted) return;
      setState(() {
        _isSending = false;
        _messages.add(ChatMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          role: MessageRole.ai,
          text: responseText,
          timestamp: DateTime.now(),
        ));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _addErrorMessage(e.toString());
      });
    }

    _scrollToBottom();
  }

  void _addErrorMessage(String errorText) {
    _messages.add(ChatMessage(
      id: 'err_${DateTime.now().microsecondsSinceEpoch}',
      role: MessageRole.ai,
      text: errorText,
      timestamp: DateTime.now(),
      isError: true,
    ));
  }

  /// Retry by resending the last user message.
  void _retry() {
    // Find the last user message
    final lastUser = _messages.lastWhere(
      (m) => m.isUser,
      orElse: () => _messages.first,
    );
    if (!lastUser.isUser) return;

    // Remove any trailing error messages so the UI is clean
    _messages.removeWhere((m) => m.isError);

    _sendMessage(lastUser.text);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // ---------------------------------------------------------------------------
  // Clear chat
  // ---------------------------------------------------------------------------

  Future<void> _confirmClearChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text(
            'Are you sure you want to clear the conversation? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _messages.clear();
        _messages.add(ChatMessage(
          id: 'welcome_reset',
          role: MessageRole.ai,
          text:
              'Chat cleared. I\'m ready to help! What would you like to study? 📚',
          timestamp: DateTime.now(),
        ));
        _isSending = false;
      });
      _geminiService?.clearSession();
    }
  }

  // ---------------------------------------------------------------------------
  // Build helpers
  // ---------------------------------------------------------------------------

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(0),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Thinking...',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    final isError = message.isError;

    Color bubbleColor;
    Color textColor;

    if (isError) {
      bubbleColor = Theme.of(context).colorScheme.errorContainer;
      textColor = Theme.of(context).colorScheme.onErrorContainer;
    } else if (isUser) {
      bubbleColor = Theme.of(context).colorScheme.primaryContainer;
      textColor = Theme.of(context).colorScheme.onPrimaryContainer;
    } else {
      bubbleColor = Theme.of(context).colorScheme.secondaryContainer;
      textColor = Theme.of(context).colorScheme.onSecondaryContainer;
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 0),
                  bottomRight: Radius.circular(isUser ? 0 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isError) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_rounded,
                            size: 16, color: textColor),
                        const SizedBox(width: 6),
                        Text(
                          'Error',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  SelectableText(
                    message.text,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: textColor),
                  ),
                ],
              ),
            ),
            // Retry button for error messages
            if (isError) ...[
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsRow() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestedQuestions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              label: Text(
                _suggestedQuestions[index],
                style: const TextStyle(fontSize: 12),
              ),
              onPressed: _isSending
                  ? null
                  : () => _sendMessage(_suggestedQuestions[index]),
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputRow() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: !_isSending,
              maxLength: GeminiService.maxMessageLength,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              decoration: InputDecoration(
                hintText: 'Ask me anything academic...',
                counterText: '', // Hide default counter
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: _isSending
                    ? Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.5)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (text) {
                if (!_isSending) _sendMessage(text);
              },
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 24,
            backgroundColor: _isSending
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                : Theme.of(context).colorScheme.primary,
            child: IconButton(
              icon: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _isSending ? null : () => _sendMessage(_controller.text),
              tooltip: 'Send',
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Academic Assistant'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear chat',
            onPressed: _confirmClearChat,
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat message list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _messages.length + (_isSending ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // Suggested questions (shown only while chat is fresh)
          if (_showSuggestions) ...[
            const Divider(height: 1),
            const SizedBox(height: 8),
            _buildSuggestionsRow(),
            const SizedBox(height: 8),
          ],

          // Text input + send
          _buildInputRow(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
