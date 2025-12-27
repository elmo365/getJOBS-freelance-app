# Critical Sync Gaps - Multi-User Workflow Audit

## Executive Summary
Found **7 critical gaps** where model changes/field additions created out-of-sync behavior between workflows involving multiple user types. Similar to the admin approval issue where `sendFCMNotification` was missing - these are silent failures in cross-user interactions.

---

## GAP 1: Job Application Flow Broken - Missing Interview Link

### Problem
When employer moves applicant to "interview_scheduled" status, interview is created but **application record has no link to interview**.

**Affected Workflows:**
- Job Seeker: Doesn't know which interview matches which application
- Employer: Interview created but application status unclear
- Interview Model: Has optional `applicationId` field but **nothing populates it**

### Root Cause
**ApplicationModel has `interviewId` field** (line 18) but:
- Interview creation (InterviewModel) doesn't store back to `applicationId`
- Application screening doesn't use this field
- No trigger/function links them

### Impact
- Job seeker sees interview scheduled but can't find matching job application
- Employer's applicant view and interview view are disconnected
- No audit trail of which application led to which interview

### Files Involved
- `lib/models/application_model.dart` - Has `interviewId` field
- `lib/models/interview_model.dart` - Has `applicationId` field  
- `lib/screens/admin/application_management_screen.dart` - Sets status to 'interview_scheduled' but doesn't create/link interview
- `functions/index.js` - No trigger to link records

### Possible Fixes

- [x] **Fix 1: Add Interview Link on Status Update**
  When ApplicationModel status changes to 'interview_scheduled':
  - Validate `interviewId` is provided
  - Store `interviewId` in application record
  - Update InterviewModel.applicationId with application ID
  - File: application_review_screen.dart (line 272-295)
  - **IMPLEMENTED:** Modified `_scheduleInterview()` to pass applicationId to InterviewSchedulingScreen. InterviewSchedulingScreen already creates interview with application_id and updates application with interviewId, so removed redundant status update.

- [x] **Fix 2: Create Cloud Function Trigger**
  ```javascript
  exports.linkApplicationToInterview = functions.firestore
    .document('interviews/{interviewId}')
    .onCreate(async (snap, context) => {
      // Validates interview has applicationId
      // Updates application with interviewId atomically
    });
  ```
  File: functions/index.js (line 1239+)
  - **IMPLEMENTED:** Added `linkApplicationToInterview` trigger that validates interview has valid applicationId and atomically updates the application with interviewId.

- [x] **Fix 3: Add Validation in Firestore Rules**
  Require `application_id` field on interview creation
  File: firestore.rules (line 290-306)
  - **IMPLEMENTED:** Updated interviews collection rules to require `application_id` as non-empty string on create. Prevents interviews without application links at DB level.

---

## GAP 2: Job Closure Process - No Status Synchronization

### Problem
When job is "completed" (all positions filled or hiring closed), **no fields update on related records**:
- Applications stuck in 'shortlisted' status
- Job seeker still sees job as active/recruiting
- Interviews still show as "Scheduled" even though job is closed
- Employer can't close job cleanly

### Root Cause
**JobModel has `completedAt` field** (line 27) but:
- No screen/function to close jobs
- No automatic status updates when `positionsFilled >= positionsAvailable`
- Applications collection not updated when job closes
- Interview collection not affected

### Impact
- Job seekers waste time applying to filled positions
- Employer activity cluttered with old jobs
- Inconsistent data state across collections

### Files Involved
- `lib/models/job_model.dart` - Has `completedAt` field (unused)
- `lib/screens/admin/admin_jobs_screen.dart` - No close/complete job action
- `lib/screens/homescreen/components/job_details.dart` - Can't see if job is completed
- Applications & Interviews collections - No status sync

### Possible Fixes

- [ ] **Fix 1: Add Job Closure Cloud Function**
  ```javascript
  exports.closeJob = onCall({}, async (request) => {
    const jobId = request.data.jobId;
    const job = await db.collection('jobs').doc(jobId).get();
    
    // Update job
    await db.collection('jobs').doc(jobId).update({
      status: 'closed',
      recruiting: false,
      completedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    // Update pending/shortlisted applications
    const apps = await db.collection('applications')
      .where('jobId', '==', jobId)
      .where('status', 'in', ['pending', 'shortlisted'])
      .get();
    
    const batch = db.batch();
    apps.docs.forEach(doc => {
      batch.update(doc.ref, {
        status: 'job_closed',
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    });
    
    // Update scheduled interviews
    const interviews = await db.collection('interviews')
      .where('jobId', '==', jobId)
      .where('status', '==', 'Scheduled')
      .get();
      
    interviews.docs.forEach(doc => {
      batch.update(doc.ref, {
        status: 'Cancelled',
        cancelReason: 'Job has been closed by employer'
      });
    });
    
    return batch.commit();
  });
  ```
  File: functions/index.js

- [ ] **Fix 2: Add Closure UI to Admin**
  Add "Close Job" button in admin_jobs_screen
  Calls closeJob cloud function
  File: lib/screens/admin/admin_jobs_screen.dart

- [ ] **Fix 3: Auto-Close When Positions Filled**
  When hiredApplicants.length >= positionsAvailable:
  - Set status='closed' and recruiting=false automatically
  - Trigger closeJob function
  File: functions/index.js (onUpdate trigger)

- [ ] **Fix 4: Update Job Status Constant**
  Add to JobModel/ApplicationStatus:
  ```dart
  static const String jobClosed = 'job_closed';
  static const String closed = 'closed';
  ```

---

## GAP 3: Applicant List Mismatch - Old & New Data Formats

### Problem
Job records use **two different applicant tracking methods**:
1. Old way: `applicantsList` array of objects with {id, name, user_image, timeapplied}
2. New way: Separate `applications` collection with ApplicationModel

**Screen reads old format, doesn't sync with new ApplicationModel data.**

### Root Cause
- Legacy code: jobs collection stores applicantsList array (line 65 in job_post.dart)
- New code: ApplicationModel stores in separate collection with status
- No migration script
- Screens inconsistently read from both

### Impact
- Applicants viewing: Sometimes sees array data, sometimes ApplicationModel data
- Applicant count mismatch: `applicants` field vs `applications` collection record count
- Status changes in applications collection don't reflect in applicantsList array

### Files Involved
- `lib/models/job_model.dart` - Has `applicantsList: List<String>` (legacy)
- `lib/models/application_model.dart` - New canonical source
- `lib/screens/activity/applicants.dart` - Reads applicantsList from old format
- `lib/screens/homescreen/components/job_post.dart` - Creates applicantsList in old format
- `lib/screens/homescreen/components/job_details.dart` - Updates both inconsistently

### Possible Fixes

- [ ] **Fix 1: Remove Legacy applicantsList**
  - Keep applicantsList field in JobModel for backward compatibility (null safe)
  - Stop writing to it
  - Read from applications collection instead
  File: lib/models/job_model.dart (remove from toMap())

- [ ] **Fix 2: Update Applicants Screen**
  Query applications collection instead of job.applicantsList:
  ```dart
  final apps = await db.collection('applications')
    .where('jobId', '==', widget.jobId)
    .where('status', '!=', 'job_closed')
    .get();
  ```
  File: lib/screens/activity/applicants.dart (line 50+)

- [ ] **Fix 3: Fix Job Creation**
  When posting job, don't create applicantsList:
  ```dart
  // REMOVE from job document
  'applicantsList': [],
  ```
  File: lib/screens/homescreen/components/job_post.dart (line 523)

- [ ] **Fix 4: Update Applicant Count**
  Use cloud function to count applications instead of applicants field:
  ```javascript
  exports.updateApplicantCount = onDocumentWritten('applications/{appId}', async (event) => {
    const jobId = event.data.after.data().jobId;
    const count = await db.collection('applications')
      .where('jobId', '==', jobId)
      .where('status', '!=', 'job_closed')
      .count()
      .get();
    
    await db.collection('jobs').doc(jobId).update({
      applicants: count.data().count
    });
  });
  ```

---

## GAP 4: Interview Conflict Detection - No Implementation

### Problem
**InterviewModel has `hasConflict` and `conflictingInterviewIds` fields** (lines 32-33) but:
- No logic detects conflicts
- No function checks for overlapping times
- Employer can schedule overlapping interviews
- Candidate sees no warning

### Root Cause
- Fields added to model but never used
- No trigger to check candidate calendar
- No validation in interview creation screen
- No timezone handling for Botswana time

### Impact
- Candidate double-booked for same time
- Missed interviews
- Poor candidate experience
- No audit trail of why conflicts happened

### Files Involved
- `lib/models/interview_model.dart` - Has unused conflict fields
- `lib/screens/admin/interview_scheduling_screen.dart` - No conflict check
- `firestore.rules` - No validation
- `functions/index.js` - No trigger

### Possible Fixes

- [ ] **Fix 1: Add Conflict Detection Cloud Function**
  ```javascript
  exports.detectInterviewConflicts = onDocumentCreated('interviews/{interviewId}', async (event) => {
    const interview = event.data.data();
    const candidateId = interview.candidate_id;
    const scheduledDate = interview.scheduled_date.toDate();
    const durationMinutes = interview.duration_minutes || 60;
    const endTime = new Date(scheduledDate.getTime() + durationMinutes * 60000);
    
    // Find overlapping interviews
    const conflicts = await db.collection('interviews')
      .where('candidate_id', '==', candidateId)
      .where('status', 'in', ['Scheduled', 'Accepted'])
      .get();
    
    const conflicting = conflicts.docs.filter(doc => {
      const other = doc.data();
      const otherStart = other.scheduled_date.toDate();
      const otherEnd = new Date(otherStart.getTime() + (other.duration_minutes || 60) * 60000);
      return scheduledDate < otherEnd && endTime > otherStart;
    }).map(doc => doc.id);
    
    if (conflicting.length > 0) {
      await event.data.ref.update({
        has_conflict: true,
        conflicting_interview_ids: conflicting
      });
      
      // Notify candidate
      await db.collection('notifications').add({
        userId: candidateId,
        type: 'interview_conflict_warning',
        title: 'Interview Time Conflict ⚠️',
        body: `You have ${conflicting.length} overlapping interview(s) scheduled`,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });
    }
  });
  ```

- [ ] **Fix 2: Add Validation to Interview Scheduling Screen**
  Check conflicts before submitting
  File: lib/screens/admin/interview_scheduling_screen.dart

- [ ] **Fix 3: Update Firestore Rules**
  Prevent creating interviews without duration_minutes field
  File: firestore.rules (line 290+)

- [ ] **Fix 4: Add Conflict Warnings to Candidate UI**
  Display conflicts when viewing interview
  File: lib/screens/interviews/interview_details_screen.dart

---

## GAP 5: Employer Company Verification Status - No Notification or Status Sync

### Problem
**UserModel has `isApproved` and `approvalStatus` fields** but:
- When admin approves employer/company, user doesn't get notified
- Employer account state unclear until refresh
- No email sent on approval/rejection
- Job posting allowed for unapproved companies (should be blocked)

### Root Cause
- Fields exist but admin update doesn't trigger notifications
- No email template for company approval
- Firestore rules allow unapproved companies to post (line 207: commented logic)
- No notification service call on approval

### Impact
- Employer doesn't know they're approved
- Unapproved companies can post jobs (if bug bypassed)
- No professional experience when account approved
- Admin approval invisible to user

### Files Involved
- `lib/models/user_model.dart` - Has approval fields
- `lib/screens/admin/company_verification_screen.dart` - Approves without notifying
- `firestore.rules` - Doesn't enforce isApproved for job posting
- `functions/index.js` - No approval notification trigger
- `lib/screens/homescreen/components/job_post.dart` - No approval check

### Possible Fixes

- [ ] **Fix 1: Add Company Approval Trigger**
  ```javascript
  exports.onCompanyApproved = onDocumentUpdated('users/{userId}', async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    
    // Detect approval status change
    if (before.approvalStatus !== 'approved' && after.approvalStatus === 'approved') {
      // Send notification
      await db.collection('notifications').add({
        userId: event.params.userId,
        type: 'company_approval',
        title: '✅ Company Approved!',
        body: 'Your company has been verified. You can now post jobs and hire candidates.',
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      // Send email
      const user = await db.collection('users').doc(event.params.userId).get();
      const userData = user.data();
      
      await admin.firestore().collection('email_queue').add({
        to: userData.email,
        template: 'company_approval',
        data: {
          companyName: userData.company_name,
          approvalDate: new Date().toISOString()
        }
      });
    }
  });
  ```

- [ ] **Fix 2: Enforce Job Posting Rule**
  Update firestore.rules to prevent unapproved companies:
  ```
  allow create: if isAuthenticated() &&
                   request.resource.data.userId == request.auth.uid &&
                   (!(get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isCompany == true) ||
                    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.approvalStatus == 'approved');
  ```
  File: firestore.rules (line 207)

- [ ] **Fix 3: Add Approval Check to Job Post Screen**
  ```dart
  Future<bool> _checkCompanyApproved() async {
    final user = await _dbService.getUser(userId);
    if (user == null) return false;
    
    final approved = user['approvalStatus'] == 'approved';
    if (!approved) {
      _showDialog('Company Not Approved', 
        'Your company is still being verified. You cannot post jobs yet.');
    }
    return approved;
  }
  ```
  File: lib/screens/homescreen/components/job_post.dart

- [ ] **Fix 4: Add Rejection Handling**
  When approvalStatus = 'rejected':
  - Send rejection email with reason
  - Allow resubmission
  - Store rejection reason

---

## GAP 6: Interview Status Flow - Incomplete State Machine

### Problem
**InterviewModel allows these statuses** (no constants):
`Scheduled, Accepted, Completed, Cancelled, Rescheduled, Ongoing, Declined`

But:
- No transitions defined (what statuses can transition to what)
- No validation prevents invalid transitions
- Candidate declining doesn't update related application
- Interview completion doesn't update hiredApplicants

### Root Cause
- Status values are loose strings, no enum
- No state machine validation
- No cloud function watching interview status changes
- Application record not linked

### Impact
- Invalid state transitions possible (e.g., Completed → Scheduled)
- Interview status changes orphaned (not reflected in application)
- No way to mark candidate as hired after successful interview
- Applicant list incomplete

### Files Involved
- `lib/models/interview_model.dart` - No status constants
- `firestore.rules` - Allows any status string
- `functions/index.js` - No state validation
- Application record - Doesn't update when interview changes

### Possible Fixes

- [ ] **Fix 1: Add Interview Status Constants**
  ```dart
  class InterviewStatus {
    static const String scheduled = 'Scheduled';
    static const String accepted = 'Accepted';
    static const String declined = 'Declined';
    static const String ongoing = 'Ongoing';
    static const String completed = 'Completed';
    static const String cancelled = 'Cancelled';
    static const String rescheduled = 'Rescheduled';
    static const String noShow = 'No-Show';
  }
  
  // Valid transitions
  static const Map<String, List<String>> validTransitions = {
    'Scheduled': ['Accepted', 'Declined', 'Cancelled', 'Rescheduled'],
    'Accepted': ['Ongoing', 'Cancelled', 'No-Show'],
    'Ongoing': ['Completed'],
    'Completed': [],  // Terminal
    'Declined': [],   // Terminal
    'Cancelled': [],  // Terminal
    'No-Show': [],    // Terminal
  };
  ```
  File: lib/models/interview_model.dart

- [ ] **Fix 2: Add Status Change Handler**
  When interview.status changes:
  - Validate transition
  - Update related application status
  - Send notifications
  - If completed: mark application as 'hired' and add to hiredApplicants
  ```javascript
  exports.onInterviewStatusChange = onDocumentUpdated('interviews/{interviewId}', async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    
    if (before.status === after.status) return;
    
    const applicationId = after.application_id;
    if (!applicationId) return;
    
    const appStatus = {
      'Completed': 'hired',
      'Declined': 'rejected',
      'No-Show': 'no_show',
      'Cancelled': 'cancelled'
    }[after.status];
    
    if (appStatus) {
      await db.collection('applications').doc(applicationId).update({
        status: appStatus,
        interviewId: event.params.interviewId
      });
      
      // If hired: add to job's hiredApplicants
      if (appStatus === 'hired') {
        const app = await db.collection('applications').doc(applicationId).get();
        const jobId = app.data().jobId;
        const userId = app.data().userId;
        
        await db.collection('jobs').doc(jobId).update({
          hiredApplicants: admin.firestore.FieldValue.arrayUnion([userId])
        });
      }
    }
  });
  ```

- [ ] **Fix 3: Add Firestore Rules Validation**
  Only allow valid status transitions
  File: firestore.rules

- [ ] **Fix 4: Update Hiring Workflow Screen**
  Use InterviewStatus constants
  File: lib/screens/admin/interview_management_screen.dart

---

## GAP 7: Missing Notification Types - No Notification for Interview Updates

### Problem
**NotificationType class** (lines 92-99 in notification_model.dart) defines:
- jobApplication
- applicationStatus
- interviewScheduled

But **no notifications sent when**:
- Interview rescheduled (candidate unaware)
- Interview cancelled (both parties unaware)
- Interview declining/no-show (employer unaware)
- Interview completed/hired (job seeker unaware)

### Root Cause
- NotificationType has constants but incomplete
- Cloud functions don't send interview update notifications
- Interview screening screen doesn't trigger notifications
- Candidate interview decline has no notification

### Impact
- Candidate misses rescheduled interview
- Employer doesn't know candidate declined
- No confirmation when interview happened
- Silent failures in communication

### Files Involved
- `lib/models/notification_model.dart` - Missing types
- `functions/index.js` - No interview update triggers
- `lib/screens/admin/interview_management_screen.dart` - No notification calls
- NotificationService - Missing send methods

### Possible Fixes

- [ ] **Fix 1: Add Missing Notification Types**
  ```dart
  class NotificationType {
    // ... existing types ...
    static const String interviewRescheduled = 'interview_rescheduled';
    static const String interviewCancelled = 'interview_cancelled';
    static const String interviewDeclined = 'interview_declined';
    static const String interviewCompleted = 'interview_completed';
    static const String candidateHired = 'candidate_hired';
    static const String interviewNoShow = 'interview_no_show';
  }
  ```
  File: lib/models/notification_model.dart

- [ ] **Fix 2: Add Interview Update Notifications**
  ```javascript
  exports.notifyInterviewUpdates = onDocumentUpdated('interviews/{interviewId}', async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    
    if (before.status !== after.status) {
      const updates = {
        'Rescheduled': {
          type: 'interview_rescheduled',
          title: '📅 Interview Rescheduled',
          body: `Your interview for ${after.job_title} has been rescheduled to ${new Date(after.scheduled_date.toDate()).toLocaleString()}`
        },
        'Cancelled': {
          type: 'interview_cancelled',
          title: '❌ Interview Cancelled',
          body: `Your interview for ${after.job_title} has been cancelled. Reason: ${after.cancel_reason || 'Not provided'}`
        },
        'Declined': {
          type: 'interview_declined',
          title: '😞 Interview Declined',
          body: `You declined the interview for ${after.job_title}`
        },
        'Completed': {
          type: 'interview_completed',
          title: '✅ Interview Completed',
          body: `Interview for ${after.job_title} is complete. Results will be shared soon.`
        }
      };
      
      const update = updates[after.status];
      if (update) {
        await db.collection('notifications').add({
          userId: after.candidate_id,
          type: update.type,
          title: update.title,
          body: update.body,
          data: {
            interviewId: event.params.interviewId,
            jobId: after.job_id
          },
          createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
      }
    }
  });
  ```

- [ ] **Fix 3: Add Candidate Hired Notification**
  When application.status → 'hired':
  ```javascript
  exports.notifyHired = onDocumentUpdated('applications/{appId}', async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    
    if (before.status !== 'hired' && after.status === 'hired') {
      await db.collection('notifications').add({
        userId: after.userId,
        type: 'candidate_hired',
        title: '🎉 Congratulations, You\'re Hired!',
        body: `You have been selected for the position of ${after.jobTitle}. The employer will contact you with next steps.`,
        data: {
          jobId: after.jobId,
          applicationId: event.params.appId
        },
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });
    }
  });
  ```

- [ ] **Fix 4: Update NotificationService**
  Add methods for interview notifications
  File: lib/services/notification_service.dart

---

## Implementation Priority

**Critical (affects core workflows):**
1. GAP 1 - Interview Link (can't match interview to job)
2. GAP 3 - Applicant List Sync (data inconsistency)
3. GAP 4 - Interview Conflicts (double-booking)

**High (affects user experience):**
4. GAP 2 - Job Closure (cluttered activity)
5. GAP 6 - Interview State Machine (invalid states)
6. GAP 7 - Missing Notifications (silent failures)

**Medium (affects admin UX):**
7. GAP 5 - Company Approval Notification (visibility)

---

## Testing Strategy

For each fix:
1. **Unit Test**: Verify cloud function logic isolated
2. **Integration Test**: Multi-user flow end-to-end
3. **Cross-Check**: Verify all related fields update consistently
4. **Notification Test**: Confirm notifications sent to right users

Example test:
```
Test: Job Closure Workflow
- Post job as Employer A
- Job Seeker B applies
- Employer A schedules interview
- All records created (job, application, interview)
- Employer A closes job
- Verify:
  ✓ Job.status = 'closed'
  ✓ Application.status = 'job_closed'
  ✓ Interview.status = 'Cancelled'
  ✓ Notifications sent to B
  ✓ Applicant can't apply anymore
```

---

## Summary Table

| Gap | Severity | Sync Issue | Files Affected | Est. Fix Time |
|-----|----------|-----------|-----------------|---------------|
| 1. Interview Link | Critical | Application ↔ Interview | 2 files + func | 2 hours |
| 2. Job Closure | High | Job → Apps → Interviews | 4 files + func | 3 hours |
| 3. Applicant Mismatch | Critical | Old vs New data formats | 5 files | 2 hours |
| 4. Conflict Detection | High | No cross-user check | 3 files + func | 2 hours |
| 5. Company Approval | Medium | No notification | 3 files + func | 1 hour |
| 6. Interview States | High | Invalid transitions | 2 files + func | 2 hours |
| 7. Missing Notifications | High | Silent failures | 2 files + func | 2 hours |

**Total Estimated: 14 hours**

---

*Last Updated: 2025-12-26*
*Next Step: Pick 1 critical gap to fix, test end-to-end, mark checkbox*
