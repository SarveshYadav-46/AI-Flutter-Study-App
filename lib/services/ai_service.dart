import '../models/chat_message.dart';

/// Abstract interface for the AI academic assistant backend.
///
/// Implementations:
///   - [GeminiService]  — real Gemini 1.5 Flash API
///   - [MockAIService]  — deterministic fake used in automated tests
abstract class AIService {
  /// Sends [userMessage] to the AI, with [history] as prior context.
  ///
  /// [history] contains recent messages (user + AI) in chronological order.
  /// Returns the AI-generated reply text.
  /// Throws a descriptive [String] error on failure.
  Future<String> sendMessage({
    required String userMessage,
    required List<ChatMessage> history,
  });
}

/// Deterministic AI service for automated tests.
///
/// Returns predictable responses based on keywords so widget tests can assert
/// UI state without touching a real API or needing a key.
class MockAIService implements AIService {
  /// If set, the next call to [sendMessage] will throw this error string.
  String? nextError;

  /// If set, the next call returns this text. Cleared after use.
  String? nextResponse;

  /// Tracks all received messages for assertion in tests.
  final List<String> receivedMessages = [];

  @override
  Future<String> sendMessage({
    required String userMessage,
    required List<ChatMessage> history,
  }) async {
    receivedMessages.add(userMessage);

    // Simulate realistic network latency in tests
    await Future.delayed(const Duration(milliseconds: 50));

    if (nextError != null) {
      final error = nextError!;
      nextError = null;
      throw error;
    }

    if (nextResponse != null) {
      final response = nextResponse!;
      nextResponse = null;
      return response;
    }

    // Default keyword-based responses for widget test assertions
    final lower = userMessage.toLowerCase();
    if (lower.contains('oop') || lower.contains('java')) {
      return 'Mock: Java OOP covers four pillars — Encapsulation, Inheritance, Polymorphism, and Abstraction.';
    }
    if (lower.contains('binary search')) {
      return 'Mock: Binary search divides the array in half each step, giving O(log n) time.';
    }
    if (lower.contains('hello')) {
      return 'Mock: Hello! How can I help you study today?';
    }
    return 'Mock: That is a great question! Let me explain it step by step.';
  }
}
