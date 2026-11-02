# EduAI Cloud Function — Gemini Proxy

## Status: ⏳ Awaiting Blaze Plan Upgrade

This Cloud Function is fully implemented but **NOT deployed**.

### Why it's blocked

Firebase **Spark (free) plan** prevents Cloud Functions from making outbound
network requests to external APIs (like the Gemini API). You must upgrade to
the **Blaze (pay-as-you-go) plan** to deploy this function.

> The Blaze plan includes the same generous free quotas as Spark.
> For a student project with light usage, the realistic monthly cost is $0.
> You must link a credit card — Firebase will alert you before any charge.

---

## Deployment Steps (after upgrading to Blaze)

### 1. Upgrade billing
Visit: https://console.firebase.google.com/project/miner-project-39b4a/usage/details
→ Modify Plan → Blaze

### 2. Install dependencies
```bash
npm install -g firebase-tools
cd functions
npm install
```

### 3. Store the API key securely
```bash
firebase functions:secrets:set GEMINI_API_KEY
```
Enter your Gemini API key when prompted.
The key is stored in **Google Secret Manager** — it never enters your code or Git.

### 4. Deploy
```bash
firebase deploy --only functions
```

### 5. Switch the Flutter app to use the Cloud Function
In `lib/services/gemini_service.dart`, set:
```dart
static const bool _useCloudFunction = true;
static const String _functionUrl =
    'https://us-central1-miner-project-39b4a.cloudfunctions.net/geminiProxy';
```

Then rebuild and run the app **without** `--dart-define=GEMINI_API_KEY`.
The API key will no longer be anywhere in the client app.

---

## Security Properties

| Property | Status |
|---|---|
| API key in Flutter code | ❌ Never |
| API key in Git | ❌ Never |
| API key in Cloud Function source | ❌ Never (Secret Manager) |
| Auth required to call function | ✅ Firebase Auth ID token |
| Input validation | ✅ Empty check, max length |
| Rate limiting | ✅ 10 requests/minute per user |
| Student messages logged | ❌ Not logged |
