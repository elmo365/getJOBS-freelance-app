# Firebase Functions (AI)

This folder contains server-side AI endpoints so the Gemini API key is never shipped in the Flutter app.

## Deploy

```powershell
cd functions
npm install
cd ..

# Set secret (recommended)
firebase functions:secrets:set GEMINI_API_KEY

# Deploy only functions
firebase deploy --only functions
```

## Callable functions

- `aiRecommendJobs` (callable)
  - Auth required
  - Inputs: `{ userProfile, availableJobs, maxResults }`
  - Output: `{ rankings: [{ jobId, matchScore, reason }] }`
