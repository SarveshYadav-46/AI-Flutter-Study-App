/**
 * EduAI Learning — Gemini AI Proxy Cloud Function
 *
 * ⏳ STATUS: AWAITING DEPLOYMENT
 * This function is ready but NOT deployed.
 * Deployment requires upgrading the Firebase project to the Blaze plan.
 * Firebase Spark plan blocks outbound HTTP requests from Cloud Functions.
 *
 * === Deployment Instructions ===
 *
 * 1. Upgrade Firebase project to Blaze (pay-as-you-go) in Firebase Console:
 *    https://console.firebase.google.com/project/miner-project-39b4a/usage/details
 *
 * 2. Install Firebase CLI and Node dependencies:
 *    npm install -g firebase-tools
 *    cd functions && npm install
 *
 * 3. Store your Gemini API key as a server-side secret (never in source code):
 *    firebase functions:secrets:set GEMINI_API_KEY
 *    (Enter your key when prompted — stored in Google Secret Manager)
 *
 * 4. Deploy:
 *    firebase deploy --only functions
 *
 * 5. In lib/services/gemini_service.dart, set _useCloudFunction = true
 *    and update _functionUrl to your deployed function's URL.
 *
 * === Security Properties ===
 * - Gemini API key never leaves the server
 * - All requests require a valid Firebase Auth ID token
 * - Input validated: empty check, max length enforced
 * - Basic per-user rate limiting (10 requests per minute)
 * - No student messages logged to Cloud Logging
 */

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const { GoogleGenerativeAI } = require('@google/generative-ai');

// Secret reference — value read at runtime from Google Secret Manager
const geminiApiKey = defineSecret('GEMINI_API_KEY');

// Rate limit store (in-memory; resets on cold start — acceptable for student project)
const requestTimestamps = new Map();

const MAX_MESSAGE_LENGTH = 2000;
const RATE_LIMIT_WINDOW_MS = 60 * 1000; // 1 minute
const RATE_LIMIT_MAX_REQUESTS = 10;     // per user per minute
const MODEL_NAME = 'gemini-1.5-flash';

const SYSTEM_INSTRUCTION = `
You are EduAI, a patient and knowledgeable academic tutor designed to help undergraduate and diploma students excel in their studies.

Your Role:
- Explain difficult concepts clearly in simple, student-friendly English.
- Always give step-by-step explanations for algorithms, math, and code problems.
- Provide practical examples and analogies to make abstract ideas concrete.
- Support follow-up questions by building on the prior conversation.

Subjects You Excel At:
Java, Python, C++, Data Structures & Algorithms (DSA), Database Management Systems (DBMS), Operating Systems, Computer Networks, Web Development, Artificial Intelligence & Machine Learning, Aptitude & Logical Reasoning.

Honesty:
- If uncertain about a fact, say so clearly — never invent information.
- Do not claim answers are verified against specific course material unless supplied.
`.trim();

exports.geminiProxy = onCall(
  {
    secrets: [geminiApiKey],
    region: 'us-central1',
    timeoutSeconds: 30,
    memory: '256MiB',
  },
  async (request) => {
    // 1. Authentication check
    if (!request.auth) {
      throw new HttpsError(
        'unauthenticated',
        'You must be signed in to use the AI assistant.'
      );
    }

    const uid = request.auth.uid;
    const { message, history = [] } = request.data;

    // 2. Input validation
    if (!message || typeof message !== 'string') {
      throw new HttpsError('invalid-argument', 'message is required.');
    }
    const trimmed = message.trim();
    if (trimmed.length === 0) {
      throw new HttpsError('invalid-argument', 'Message cannot be empty.');
    }
    if (trimmed.length > MAX_MESSAGE_LENGTH) {
      throw new HttpsError(
        'invalid-argument',
        `Message exceeds ${MAX_MESSAGE_LENGTH} character limit.`
      );
    }

    // 3. Rate limiting
    const now = Date.now();
    const userTimestamps = requestTimestamps.get(uid) || [];
    const recentRequests = userTimestamps.filter(
      (ts) => now - ts < RATE_LIMIT_WINDOW_MS
    );
    if (recentRequests.length >= RATE_LIMIT_MAX_REQUESTS) {
      throw new HttpsError(
        'resource-exhausted',
        'Too many requests. Please wait a moment before asking again.'
      );
    }
    recentRequests.push(now);
    requestTimestamps.set(uid, recentRequests);

    // 4. Build conversation history
    const historyContents = [];
    if (Array.isArray(history)) {
      for (const msg of history.slice(-10)) { // max 10 history messages
        if (msg.role === 'user' && msg.text) {
          historyContents.push({
            role: 'user',
            parts: [{ text: String(msg.text).slice(0, MAX_MESSAGE_LENGTH) }],
          });
        } else if (msg.role === 'ai' && msg.text && !msg.isError) {
          historyContents.push({
            role: 'model',
            parts: [{ text: String(msg.text).slice(0, 2000) }],
          });
        }
      }
    }

    // 5. Call Gemini
    try {
      const genAI = new GoogleGenerativeAI(geminiApiKey.value());
      const model = genAI.getGenerativeModel({
        model: MODEL_NAME,
        systemInstruction: SYSTEM_INSTRUCTION,
        generationConfig: {
          temperature: 0.7,
          maxOutputTokens: 1024,
        },
      });

      const chat = model.startChat({ history: historyContents });
      const result = await chat.sendMessage(trimmed);
      const responseText = result.response.text();

      if (!responseText || responseText.trim().length === 0) {
        throw new HttpsError(
          'internal',
          'The AI returned an empty response. Please try rephrasing.'
        );
      }

      // Return only the text — never echo back secrets or uid details
      return { text: responseText.trim() };
    } catch (err) {
      // Do not log the user's message or the API key
      console.error('[geminiProxy] Gemini API call failed:', err.message);

      if (err instanceof HttpsError) throw err;

      const msg = (err.message || '').toLowerCase();
      if (msg.includes('quota') || msg.includes('429')) {
        throw new HttpsError(
          'resource-exhausted',
          'AI service quota exceeded. Please try again later.'
        );
      }
      throw new HttpsError(
        'internal',
        'AI service is temporarily unavailable. Please try again.'
      );
    }
  }
);
