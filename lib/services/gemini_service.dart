import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/chat_message.dart';
import 'ai_service.dart';

/// Production implementation of [AIService] that connects EduAI to Google Gemini.
///
/// # Secure Architecture & Billing Constraint
///
/// Because the Firebase project is currently on the Spark (free) plan, Cloud Functions
/// cannot make outbound requests to external APIs like Gemini without upgrading to Blaze.
///
/// To prevent exposing API keys to the client, this service supports:
/// 1. **Secure HTTPS Backend (Production - Recommended)**:
///    Points to an authenticated proxy (Firebase Cloud Function or Cloud Run).
///    Configured via `--dart-define=AI_BACKEND_URL=https://.../geminiProxy`.
///    The client attaches the student's Firebase Auth ID token for verification.
///
/// 2. **Direct Gemini via dart-define (Development Only)**:
///    Configured via `--dart-define=GEMINI_API_KEY=YOUR_KEY`.
///    Never committed to code or Git.
///
/// If neither is configured, [isAvailable] is false and user attempts are met with
/// a clear message that live responses are awaiting secure backend deployment.
class GeminiService implements AIService {
  // ---------------------------------------------------------------------------
  // Configuration constants
  // ---------------------------------------------------------------------------

  /// The verified, current, cost-effective Gemini text model.
  static const String modelName = 'gemini-1.5-flash';

  /// Maximum characters allowed in a single user message.
  static const int maxMessageLength = 2000;

  /// Maximum number of prior messages included in each request as context.
  static const int maxHistoryMessages = 10;

  /// Configurable authenticated HTTPS endpoint for the secure server-side proxy.
  /// Set via `--dart-define=AI_BACKEND_URL=...`
  static const String backendEndpointUrl = String.fromEnvironment('AI_BACKEND_URL');

  /// Fallback Gemini API key for local developer testing.
  /// Set via `--dart-define=GEMINI_API_KEY=...`
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  /// Returns true when either a secure backend URL or a dev API key is supplied.
  bool get isAvailable => backendEndpointUrl.isNotEmpty || _apiKey.isNotEmpty;

  /// Returns true if connected via the secure HTTPS backend proxy.
  bool get isUsingBackendProxy => backendEndpointUrl.isNotEmpty;

  // ---------------------------------------------------------------------------
  // System instruction for the academic tutor persona
  // ---------------------------------------------------------------------------

  static const String _systemInstruction = '''
You are EduAI, a patient and knowledgeable academic tutor designed to help undergraduate and diploma students excel in their studies.

## Your Role
- Explain difficult concepts clearly in simple, student-friendly English.
- Always give step-by-step explanations for algorithms, math, and code problems.
- Provide practical examples and analogies to make abstract ideas concrete.
- Support follow-up questions by building on the prior conversation.

## Subjects You Excel At
Java, Python, C++, Data Structures & Algorithms (DSA), Database Management Systems (DBMS), Operating Systems, Computer Networks, Web Development, Artificial Intelligence & Machine Learning, Aptitude & Logical Reasoning.

## Formatting Guidelines
- Use **bold** for key terms.
- Use numbered lists for steps.
- Use code blocks with language labels for code snippets.
- Keep responses focused and appropriately concise for a mobile screen.

## Honesty
- If you are uncertain about a fact, say so clearly — never invent information.
- Do not claim your answers are verified against specific course material unless that material is provided to you.
- If a question is outside your academic scope, politely redirect the student.

## Tone
Be encouraging, patient, and supportive — like a senior student or teaching assistant who genuinely wants the student to understand, not just memorize.
''';

  GenerativeModel? _model;

  void _ensureInitializedDirect() {
    if (_model != null) return;

    _model = GenerativeModel(
      model: modelName,
      apiKey: _apiKey,
      systemInstruction: Content.system(_systemInstruction),
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 1024,
      ),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.high),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // sendMessage
  // ---------------------------------------------------------------------------

  @override
  Future<String> sendMessage({
    required String userMessage,
    required List<ChatMessage> history,
  }) async {
    final trimmed = userMessage.trim();
    if (trimmed.isEmpty) throw 'Message cannot be empty.';
    if (trimmed.length > maxMessageLength) {
      throw 'Message is too long. Please keep it under $maxMessageLength characters.';
    }

    if (!isAvailable) {
      throw 'Live AI responses are currently awaiting secure backend configuration. '
          'Deploy the backend proxy on the Blaze plan or provide an AI_BACKEND_URL.';
    }

    // Limit history length to protect token usage
    final recentHistory = history.length > maxHistoryMessages
        ? history.sublist(history.length - maxHistoryMessages)
        : history;

    if (backendEndpointUrl.isNotEmpty) {
      return _callSecureBackendProxy(trimmed, recentHistory);
    } else {
      return _callDirectGemini(trimmed, recentHistory);
    }
  }

  /// Calls the configurable server-side HTTPS proxy with the student's Firebase Auth ID token.
  Future<String> _callSecureBackendProxy(
    String message,
    List<ChatMessage> history,
  ) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 25);

    try {
      final uri = Uri.parse(backendEndpointUrl);
      final request = await client.postUrl(uri);
      request.headers.set('content-type', 'application/json; charset=utf-8');

      // Attach Firebase Auth ID token for user verification
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final idToken = await currentUser.getIdToken();
        if (idToken != null) {
          request.headers.set('authorization', 'Bearer $idToken');
        }
      }

      final historyPayload = history.map((m) => {
        'role': m.isUser ? 'user' : 'ai',
        'text': m.text,
      }).toList();

      final payload = jsonEncode({
        'data': {
          'message': message,
          'history': historyPayload,
        }
      });

      request.write(payload);
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(responseBody);
        if (decoded is Map) {
          if (decoded['result'] is Map && decoded['result']['text'] != null) {
            return decoded['result']['text'].toString().trim();
          }
          if (decoded['text'] != null) {
            return decoded['text'].toString().trim();
          }
        }
        return responseBody.trim();
      } else {
        throw 'Secure backend responded with status ${response.statusCode}.';
      }
    } on SocketException {
      throw 'Network error. Please check your internet connection.';
    } on HandshakeException {
      throw 'Secure connection error while contacting AI backend.';
    } catch (e) {
      if (e is String) rethrow;
      throw 'Failed to communicate with AI backend: $e';
    } finally {
      client.close();
    }
  }

  /// Direct Gemini API call for local testing if a key was injected via dart-define.
  Future<String> _callDirectGemini(
    String message,
    List<ChatMessage> history,
  ) async {
    try {
      _ensureInitializedDirect();

      final historyContents = <Content>[];
      for (final msg in history) {
        if (msg.isUser) {
          historyContents.add(Content.text(msg.text));
        } else if (!msg.isError) {
          historyContents.add(Content('model', [TextPart(msg.text)]));
        }
      }

      final session = _model!.startChat(history: historyContents);
      final response = await session.sendMessage(Content.text(message));

      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        throw 'The AI returned an empty response. Please try rephrasing your question.';
      }

      return text.trim();
    } on GenerativeAIException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('api_key') || msg.contains('invalid')) {
        throw 'Invalid API key. Please check your configuration.';
      }
      if (msg.contains('quota') || msg.contains('rate') || msg.contains('429')) {
        throw 'AI service rate limit reached. Please wait a moment and try again.';
      }
      if (msg.contains('blocked') || msg.contains('safety')) {
        throw 'Your message was blocked by safety filters. Please rephrase your question.';
      }
      throw 'AI service error: ${e.message}';
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('socket') ||
          msg.contains('network') ||
          msg.contains('connection') ||
          msg.contains('timeout')) {
        throw 'Network error. Please check your internet connection and try again.';
      }
      if (e is String) rethrow;
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  /// Clears any cached model resources, starting a fresh conversation.
  void clearSession() {
    _model = null;
  }
}
