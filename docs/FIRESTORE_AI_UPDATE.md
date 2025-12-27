# Firestore Rules & Indexes Update for AI Features

## Overview
This document outlines the Firestore security rules and indexes required for AI features in BotsJobsConnect.

## AI Data Structure

### Collections Used by AI Features:

1. **`users/{userId}/ai/cv_analysis`**
   - Stores CV analysis results from Gemini AI
   - Fields: `analysis`, `updatedAt`, `model`, `source`

2. **`users/{userId}/ai/job_events/events`**
   - Stores user job interaction events for behavior learning
   - Fields: `jobId`, `event`, `source`, `metadata`, `createdAt`, `model`

## Firestore Rules

### Current Rules (Already Implemented ✅)

```javascript
// User AI subcollections (signals/analysis)
match /users/{userId}/ai/{docId=**} {
  allow read, write: if isOwner(userId) || isAdmin();
}
```

**Status:** ✅ Already covers all AI subcollections:
- `users/{userId}/ai/cv_analysis`
- `users/{userId}/ai/job_events/events`
- Any future AI subcollections

**Security:**
- Users can only read/write their own AI data
- Admins can access all AI data
- Prevents unauthorized access to AI analysis results

## Firestore Indexes

### Required Indexes

#### 1. AI Job Events Query Index ✅ NOT NEEDED

**Query Pattern:**
```dart
_firestore
  .collection('users')
  .doc(userId)
  .collection('ai')
  .doc('job_events')
  .collection('events')
  .orderBy('createdAt', descending: true)
  .limit(20)
  .get()
```

**Status:** No index required - Firestore automatically handles single-field queries.

**Note:** Firestore creates single-field indexes automatically. Composite indexes (multiple fields) require explicit definition in `firestore.indexes.json`.

## Data Privacy & Security

### AI Data Handling:

1. **CV Analysis Data:**
   - Stored in user's private subcollection
   - Only accessible by user and admins
   - Used for improving job recommendations

2. **Job Interaction Events:**
   - Tracks: views, applications, bookmarks
   - Used for personalized recommendations
   - User can opt-out (future feature)

3. **No Raw CV Text Storage:**
   - AI analysis results only (structured data)
   - Original CV text not stored in AI collections

## Deployment

### To Deploy Updated Rules & Indexes:

1. **Deploy Firestore Rules:**
   ```bash
   firebase deploy --only firestore:rules
   ```

2. **Deploy Firestore Indexes:**
   ```bash
   firebase deploy --only firestore:indexes
   ```

3. **Verify Index Creation:**
   - Check Firebase Console → Firestore → Indexes
   - Wait for index to build (may take a few minutes)

## Testing

### Verify Rules Work:

1. **User can write to own AI data:**
   ```dart
   await _firestore
     .collection('users')
     .doc(userId)
     .collection('ai')
     .doc('cv_analysis')
     .set({...}); // Should succeed
   ```

2. **User cannot write to other user's AI data:**
   ```dart
   await _firestore
     .collection('users')
     .doc(otherUserId)
     .collection('ai')
     .doc('cv_analysis')
     .set({...}); // Should fail with permission error
   ```

3. **Query job events:**
   ```dart
   await _firestore
     .collection('users')
     .doc(userId)
     .collection('ai')
     .doc('job_events')
     .collection('events')
     .orderBy('createdAt', descending: true)
     .limit(20)
     .get(); // Should succeed with index
   ```

## Future Considerations

### Potential Additional Indexes:

1. **AI Analysis by Model:**
   - If querying by AI model type
   - Index: `model` + `updatedAt`

2. **Job Events by Event Type:**
   - If filtering by event type
   - Index: `event` + `createdAt`

3. **AI Analysis by Source:**
   - If tracking analysis sources
   - Index: `source` + `updatedAt`

### Security Enhancements:

1. **Rate Limiting:**
   - Consider Cloud Functions for AI operations
   - Server-side rate limiting prevents abuse

2. **Data Retention:**
   - Consider TTL policies for old AI events
   - Keep only last 90 days of events

3. **Audit Logging:**
   - Log AI data access for compliance
   - Track admin access to user AI data

---

*Last Updated: December 2024*
*Status: Rules ✅ | Indexes ✅ (No additional indexes needed) | Ready for Production*

