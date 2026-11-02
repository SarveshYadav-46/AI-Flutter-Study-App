import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minerproject/screens/ai_assistant_screen.dart';
import 'package:minerproject/services/ai_service.dart';
import 'package:minerproject/models/chat_message.dart';
import 'package:minerproject/services/gemini_service.dart';

// ---------------------------------------------------------------------------
// Helper: pump the AIAssistantScreen with a MockAIService injected
// ---------------------------------------------------------------------------
Future<void> pumpScreen(
  WidgetTester tester, {
  MockAIService? mockService,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: AIAssistantScreen(aiService: mockService ?? MockAIService()),
    ),
  );
  // Let the widget settle
  await tester.pump();
}

void main() {
  // -------------------------------------------------------------------------
  // Unit tests: MockAIService
  // -------------------------------------------------------------------------
  group('MockAIService', () {
    test('returns default keyword response for "java"', () async {
      final svc = MockAIService();
      final reply = await svc.sendMessage(
        userMessage: 'Explain java OOP',
        history: [],
      );
      expect(reply, contains('Java OOP'));
      expect(svc.receivedMessages, contains('Explain java OOP'));
    });

    test('returns configured nextResponse and clears it', () async {
      final svc = MockAIService()..nextResponse = 'Custom reply';
      final first = await svc.sendMessage(userMessage: 'q1', history: []);
      expect(first, equals('Custom reply'));
      // After use, nextResponse is cleared — falls back to keyword logic
      final second = await svc.sendMessage(userMessage: 'hello', history: []);
      expect(second, isNot(equals('Custom reply')));
    });

    test('throws nextError and clears it', () async {
      final svc = MockAIService()
        ..nextError = 'Network error. Please check your internet connection.';
      expect(
        () => svc.sendMessage(userMessage: 'any', history: []),
        throwsA(contains('Network error')),
      );
    });

    test('records all sent messages', () async {
      final svc = MockAIService();
      await svc.sendMessage(userMessage: 'msg1', history: []);
      await svc.sendMessage(userMessage: 'msg2', history: []);
      expect(svc.receivedMessages, containsAll(['msg1', 'msg2']));
    });
  });

  // -------------------------------------------------------------------------
  // Unit tests: GeminiService input validation & configuration
  // -------------------------------------------------------------------------
  group('GeminiService', () {
    test('rejects empty messages', () async {
      final service = GeminiService();
      expect(
        () => service.sendMessage(userMessage: '   ', history: []),
        throwsA(contains('empty')),
      );
    });

    test('rejects messages exceeding max length', () async {
      final service = GeminiService();
      final overlyLongMessage = 'A' * (GeminiService.maxMessageLength + 10);
      expect(
        () => service.sendMessage(userMessage: overlyLongMessage, history: []),
        throwsA(contains('too long')),
      );
    });

    test('isAvailable defaults to false when no backend URL or dev key is set', () {
      final service = GeminiService();
      // In default test environment without dart-define, isAvailable is false
      expect(service.isAvailable, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Unit tests: ChatMessage model
  // -------------------------------------------------------------------------
  group('ChatMessage', () {
    test('isUser returns true for user role', () {
      final msg = ChatMessage(
        id: '1',
        role: MessageRole.user,
        text: 'hello',
        timestamp: DateTime.now(),
      );
      expect(msg.isUser, isTrue);
      expect(msg.isAI, isFalse);
    });

    test('isAI returns true for ai role', () {
      final msg = ChatMessage(
        id: '2',
        role: MessageRole.ai,
        text: 'hi',
        timestamp: DateTime.now(),
      );
      expect(msg.isAI, isTrue);
      expect(msg.isUser, isFalse);
    });

    test('isError defaults to false', () {
      final msg = ChatMessage(
        id: '3',
        role: MessageRole.ai,
        text: 'ok',
        timestamp: DateTime.now(),
      );
      expect(msg.isError, isFalse);
    });

    test('copyWith preserves unmodified fields', () {
      final original = ChatMessage(
        id: 'x',
        role: MessageRole.user,
        text: 'original',
        timestamp: DateTime.now(),
      );
      final copy = original.copyWith(text: 'updated');
      expect(copy.id, equals('x'));
      expect(copy.text, equals('updated'));
      expect(copy.role, equals(MessageRole.user));
    });
  });

  // -------------------------------------------------------------------------
  // Widget tests: AIAssistantScreen UI
  // -------------------------------------------------------------------------
  group('AIAssistantScreen widget', () {
    testWidgets('shows welcome message on launch', (tester) async {
      await pumpScreen(tester);
      expect(find.textContaining('AI Academic Assistant'), findsWidgets);
      // Welcome bubble text
      expect(find.textContaining("Hi! 👋"), findsOneWidget);
    });

    testWidgets('shows suggested questions initially', (tester) async {
      await pumpScreen(tester);
      expect(find.text('Explain Java OOP with examples'), findsOneWidget);
    });

    testWidgets('has text input field and send button', (tester) async {
      await pumpScreen(tester);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('shows loading indicator while waiting for AI response',
        (tester) async {
      // Use a service that hangs for a bit
      final mock = MockAIService()..nextResponse = 'Response';
      await pumpScreen(tester, mockService: mock);

      await tester.enterText(find.byType(TextField), 'What is OOP?');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump(); // Start async

      // Typing indicator should appear
      expect(find.text('Thinking...'), findsOneWidget);

      // Let the mock complete
      await tester.pumpAndSettle();
      expect(find.text('Thinking...'), findsNothing);
    });

    testWidgets('user message bubble appears after sending', (tester) async {
      final mock = MockAIService()..nextResponse = 'Got it!';
      await pumpScreen(tester, mockService: mock);

      await tester.enterText(find.byType(TextField), 'Hello AI');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(find.text('Hello AI'), findsOneWidget);
    });

    testWidgets('AI response bubble appears after mock reply', (tester) async {
      final mock = MockAIService()
        ..nextResponse = 'Binary search is O(log n).';
      await pumpScreen(tester, mockService: mock);

      await tester.enterText(
          find.byType(TextField), 'Explain binary search');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(find.textContaining('Binary search is O(log n)'), findsOneWidget);
    });

    testWidgets('error bubble shows when AI service throws', (tester) async {
      final mock = MockAIService()
        ..nextError = 'Network error. Please check your internet connection.';
      await pumpScreen(tester, mockService: mock);

      await tester.enterText(find.byType(TextField), 'Test question');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(find.text('Error'), findsOneWidget);
      expect(find.textContaining('Network error'), findsOneWidget);
    });

    testWidgets('retry button appears on error and triggers resend',
        (tester) async {
      final mock = MockAIService()
        ..nextError = 'Service unavailable.';
      await pumpScreen(tester, mockService: mock);

      await tester.enterText(find.byType(TextField), 'Retry question');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Error bubble with Retry button
      expect(find.text('Retry'), findsOneWidget);

      // Now configure success response for retry
      mock.nextResponse = 'Retry succeeded!';
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Retry succeeded!'), findsOneWidget);
    });

    testWidgets('empty message shows snackbar, does not call service',
        (tester) async {
      final mock = MockAIService();
      await pumpScreen(tester, mockService: mock);

      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Snackbar with validation message
      expect(find.text('Please enter a message first.'), findsOneWidget);
      // Service was not called
      expect(mock.receivedMessages, isEmpty);
    });

    testWidgets('send button is disabled while request is in progress',
        (tester) async {
      final mock = MockAIService()..nextResponse = 'Later...';
      await pumpScreen(tester, mockService: mock);

      await tester.enterText(find.byType(TextField), 'First message');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump(); // Do NOT settle — catch mid-flight state

      // Send icon replaced by progress indicator
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      await tester.pumpAndSettle();
    });

    testWidgets('clear chat dialog appears and resets conversation',
        (tester) async {
      final mock = MockAIService()..nextResponse = 'Hello back!';
      await pumpScreen(tester, mockService: mock);

      // Send a message first
      await tester.enterText(find.byType(TextField), 'Hi');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Tap clear button (delete_sweep icon in app bar)
      await tester.tap(find.byIcon(Icons.delete_sweep_outlined));
      await tester.pumpAndSettle();

      // Confirm dialog should appear
      expect(find.text('Clear Chat'), findsOneWidget);
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      // Only the reset welcome message should be visible
      expect(find.textContaining('Chat cleared'), findsOneWidget);
    });

    testWidgets('suggested chip sends message and hides suggestions',
        (tester) async {
      final mock = MockAIService()
        ..nextResponse = 'Java OOP covers Encapsulation, Inheritance, etc.';
      await pumpScreen(tester, mockService: mock);

      // Suggestions visible initially
      final chipFinder = find.text('Explain Java OOP with examples');
      expect(chipFinder, findsOneWidget);

      await tester.tap(chipFinder);
      await tester.pumpAndSettle();

      // The chip message was sent
      expect(find.text('Explain Java OOP with examples'),
          findsWidgets); // appears in bubble
      expect(find.textContaining('Java OOP covers'), findsOneWidget);
    });

    testWidgets('shows awaiting secure backend message when unconfigured',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AIAssistantScreen(), // uses default unconfigured GeminiService
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Hello tutor');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
            'Live AI responses are currently awaiting secure backend configuration'),
        findsOneWidget,
      );
    });
  });

  // -------------------------------------------------------------------------
  // Note on live API testing
  // -------------------------------------------------------------------------
  // All tests above use MockAIService and do NOT require a real Gemini API key.
  //
  // To verify real AI integration, run the app manually:
  //   flutter run --dart-define=GEMINI_API_KEY=YOUR_KEY
  //
  // Then:
  //  1. Navigate to AI Helper tab
  //  2. Type "Explain Java OOP with examples" and tap Send
  //  3. Verify a coherent multi-paragraph response appears within ~5 seconds
  //  4. Ask a follow-up: "Can you give me a code example?" — verify context is maintained
}
