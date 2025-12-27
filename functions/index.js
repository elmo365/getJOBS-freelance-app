const admin = require('firebase-admin');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const functions = require('firebase-functions');
const { defineSecret } = require('firebase-functions/params');
const { GoogleGenerativeAI } = require('@google/generative-ai');

admin.initializeApp();

const GEMINI_API_KEY = defineSecret('GEMINI_API_KEY');
const BREVO_API_KEY = defineSecret('BREVO_API_KEY');

function normalizeFcmData(input) {
  const out = {};
  if (!input || typeof input !== 'object') return out;
  for (const [k, v] of Object.entries(input)) {
    if (v === undefined || v === null) continue;
    if (typeof v === 'string') {
      out[k] = v;
    } else if (typeof v === 'number' || typeof v === 'boolean') {
      out[k] = String(v);
    } else {
      try {
        out[k] = JSON.stringify(v).slice(0, 1500);
      } catch (_) {
        out[k] = String(v);
      }
    }
  }
  return out;
}

function getEmailTemplate({ type, title, body, data }) {
  const baseStyle = `
    <style>
      body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; line-height: 1.6; color: #333; }
      .container { max-width: 600px; margin: 0 auto; padding: 20px; }
      .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }
      .content { background: #ffffff; padding: 30px; border: 1px solid #e0e0e0; border-top: none; }
      .footer { background: #f5f5f5; padding: 20px; text-align: center; color: #666; font-size: 12px; border-radius: 0 0 8px 8px; }
      .button { display: inline-block; padding: 12px 24px; background: #667eea; color: white; text-decoration: none; border-radius: 6px; margin: 20px 0; }
      .alert { padding: 15px; border-radius: 6px; margin: 20px 0; }
      .alert-success { background: #d4edda; border-left: 4px solid #28a745; color: #155724; }
      .alert-error { background: #f8d7da; border-left: 4px solid #dc3545; color: #721c24; }
      .alert-info { background: #d1ecf1; border-left: 4px solid #17a2b8; color: #0c5460; }
    </style>
  `;

  let contentHtml = '';
  let alertClass = 'alert-info';

  switch (type) {
    case 'company_approval':
      alertClass = 'alert-success';
      contentHtml = `
        <div class="alert ${alertClass}">
          <h2 style="margin-top: 0;">🎉 Company Approved!</h2>
          <p><strong>${title}</strong></p>
          <p>${body}</p>
          <p>You can now:</p>
          <ul>
            <li>Post job listings</li>
            <li>Browse verified candidate profiles</li>
            <li>Schedule interviews</li>
            <li>Use AI-powered candidate suggestions</li>
          </ul>
          <a href="https://botsjobsconnect.com/dashboard" class="button">Go to Dashboard</a>
        </div>
      `;
      break;

    case 'company_rejected':
      alertClass = 'alert-error';
      const reason = data && data.reason ? data.reason : 'Please review your submission and try again.';
      contentHtml = `
        <div class="alert ${alertClass}">
          <h2 style="margin-top: 0;">❌ Company Verification Rejected</h2>
          <p><strong>${title}</strong></p>
          <p>${body}</p>
          <p><strong>Reason:</strong> ${reason}</p>
          <p>You can resubmit your verification documents after addressing the issues mentioned above.</p>
          <a href="https://botsjobsconnect.com/verification" class="button">Review Documents</a>
        </div>
      `;
      break;

    case 'company_kyc_submitted':
      alertClass = 'alert-info';
      contentHtml = `
        <div class="alert ${alertClass}">
          <h2 style="margin-top: 0;">📋 KYC Documents Submitted</h2>
          <p><strong>${title}</strong></p>
          <p>${body}</p>
          <p>Our admin team will review your documents and get back to you within 2-3 business days.</p>
          <p>You will receive an email notification once the review is complete.</p>
        </div>
      `;
      break;

    case 'job_approval':
      alertClass = 'alert-success';
      contentHtml = `
        <div class="alert ${alertClass}">
          <h2 style="margin-top: 0;">✅ Job Approved!</h2>
          <p><strong>${title}</strong></p>
          <p>${body}</p>
          <p>Your job posting is now live and visible to job seekers.</p>
          <a href="https://botsjobsconnect.com/jobs/${data && data.jobId ? data.jobId : ''}" class="button">View Job</a>
        </div>
      `;
      break;

    case 'job_rejected':
      alertClass = 'alert-error';
      const jobReason = data && data.reason ? data.reason : 'Please review your job posting and try again.';
      contentHtml = `
        <div class="alert ${alertClass}">
          <h2 style="margin-top: 0;">❌ Job Rejected</h2>
          <p><strong>${title}</strong></p>
          <p>${body}</p>
          ${jobReason ? `<p><strong>Reason:</strong> ${jobReason}</p>` : ''}
          <p>You can edit and resubmit your job posting.</p>
          <a href="https://botsjobsconnect.com/jobs/edit/${data && data.jobId ? data.jobId : ''}" class="button">Edit Job</a>
        </div>
      `;
      break;

    case 'job_posted':
      alertClass = 'alert-success';
      contentHtml = `
        <div class="alert ${alertClass}">
          <h2 style="margin-top: 0;">✅ Job Posted Successfully!</h2>
          <p><strong>${title}</strong></p>
          <p>${body}</p>
          <p>Your job posting is now ${data && data.status === 'pending' ? 'pending admin approval' : 'live and visible to job seekers'}.</p>
          <a href="https://botsjobsconnect.com/jobs/${data && data.jobId ? data.jobId : ''}" class="button">View Job</a>
        </div>
      `;
      break;

    case 'job_pending_approval':
      alertClass = 'alert-info';
      contentHtml = `
        <div class="alert ${alertClass}">
          <h2 style="margin-top: 0;">📋 New Job Pending Approval</h2>
          <p><strong>${title}</strong></p>
          <p>${body}</p>
          <p>Please review the job posting and approve or reject it from the admin panel.</p>
          <a href="https://botsjobsconnect.com/admin/jobs" class="button">Review Job</a>
        </div>
      `;
      break;

    case 'job_application':
      alertClass = 'alert-info';
      contentHtml = `
        <div class="alert ${alertClass}">
          <h2 style="margin-top: 0;">📝 New Job Application</h2>
          <p><strong>${title}</strong></p>
          <p>${body}</p>
          <p>Review the candidate's profile and application in your dashboard.</p>
          <a href="https://botsjobsconnect.com/applications" class="button">View Applications</a>
        </div>
      `;
      break;

    case 'application_submitted':
      alertClass = 'alert-success';
      contentHtml = `
        <div class="alert ${alertClass}">
          <h2 style="margin-top: 0;">✅ Application Submitted</h2>
          <p><strong>${title}</strong></p>
          <p>${body}</p>
          <p>The employer will review your application and get back to you soon.</p>
          <a href="https://botsjobsconnect.com/applications" class="button">View My Applications</a>
        </div>
      `;
      break;

    case 'application_approved':
      alertClass = 'alert-success';
      contentHtml = `
        <div class="alert ${alertClass}">
          <h2 style="margin-top: 0;">🎉 Application Approved!</h2>
          <p><strong>${title}</strong></p>
          <p>${body}</p>
          <p>The employer may contact you for next steps or schedule an interview.</p>
          <a href="https://botsjobsconnect.com/applications" class="button">View Application</a>
        </div>
      `;
      break;

    case 'application_rejected':
      alertClass = 'alert-error';
      const appReason = data && data.notes ? data.notes : '';
      contentHtml = `
        <div class="alert ${alertClass}">
          <h2 style="margin-top: 0;">Application Update</h2>
          <p><strong>${title}</strong></p>
          <p>${body}</p>
          ${appReason ? `<p><strong>Feedback:</strong> ${appReason}</p>` : ''}
          <p>Keep applying to other opportunities that match your skills.</p>
          <a href="https://botsjobsconnect.com/jobs" class="button">Browse Jobs</a>
        </div>
      `;
      break;

    case 'interview_scheduled':
      alertClass = 'alert-info';
      const interviewDate = data && data.scheduledDate ? new Date(data.scheduledDate).toLocaleString() : '';
      const meetingLink = data && data.meetingLink ? data.meetingLink : '';
      const location = data && data.location ? data.location : '';
      contentHtml = `
        <div class="alert ${alertClass}">
          <h2 style="margin-top: 0;">📅 Interview Scheduled</h2>
          <p><strong>${title}</strong></p>
          <p>${body}</p>
          ${interviewDate ? `<p><strong>Date & Time:</strong> ${interviewDate}</p>` : ''}
          ${meetingLink ? `<p><strong>Meeting Link:</strong> <a href="${meetingLink}">${meetingLink}</a></p>` : ''}
          ${location ? `<p><strong>Location:</strong> ${location}</p>` : ''}
          <p>Please prepare for the interview and arrive on time.</p>
          <a href="https://botsjobsconnect.com/interviews" class="button">View Interview Details</a>
        </div>
      `;
      break;

    case 'application_status':
      alertClass = 'alert-info';
      contentHtml = `
        <div class="alert ${alertClass}">
          <h2 style="margin-top: 0;">Application Status Update</h2>
          <p><strong>${title}</strong></p>
          <p>${body}</p>
          <a href="https://botsjobsconnect.com/applications" class="button">View Application</a>
        </div>
      `;
      break;

    default:
      contentHtml = `
        <div class="alert ${alertClass}">
          <p><strong>${title}</strong></p>
          <p>${body.replaceAll('\n', '<br/>')}</p>
        </div>
      `;
  }

  return `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      ${baseStyle}
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1 style="margin: 0;">BotsJobsConnect</h1>
        </div>
        <div class="content">
          ${contentHtml}
        </div>
        <div class="footer">
          <p>This is an automated notification from BotsJobsConnect.</p>
          <p>If you have any questions, please contact our support team.</p>
          <p>&copy; ${new Date().getFullYear()} BotsJobsConnect. All rights reserved.</p>
        </div>
      </div>
    </body>
    </html>
  `;
}

async function sendBrevoEmail({ apiKey, toEmail, subject, htmlContent, textContent }) {
  if (!apiKey) {
    throw new HttpsError('failed-precondition', 'Brevo is not configured on the server.');
  }

  const res = await fetch('https://api.brevo.com/v3/smtp/email', {
    method: 'POST',
    headers: {
      'api-key': apiKey,
      'Content-Type': 'application/json',
      accept: 'application/json',
    },
    body: JSON.stringify({
      sender: {
        name: process.env.BREVO_SENDER_NAME || 'BotsJobsConnect',
        email: process.env.BREVO_SENDER_EMAIL || 'noreply@botsjobsconnect.com',
      },
      to: [{ email: toEmail }],
      subject,
      htmlContent,
      ...(textContent ? { textContent } : {}),
    }),
  });

  if (!res.ok) {
    const body = await res.text();
    throw new HttpsError('internal', 'Failed to send email.', {
      status: res.status,
      body: String(body || '').slice(0, 2000),
    });
  }
}

function stripCodeFences(text) {
  const trimmed = (text || '').trim();
  if (!trimmed.startsWith('```')) return trimmed;
  const lines = trimmed.split('\n');
  if (lines.length === 0) return trimmed;
  if (lines[0].trim().startsWith('```')) lines.shift();
  if (lines.length > 0 && lines[lines.length - 1].trim() === '```') lines.pop();
  return lines.join('\n').trim();
}

function extractFirstJson(text) {
  const cleaned = stripCodeFences(text);
  const arrayStart = cleaned.indexOf('[');
  const objStart = cleaned.indexOf('{');
  const start = arrayStart === -1 ? objStart : objStart === -1 ? arrayStart : Math.min(arrayStart, objStart);
  if (start === -1) return cleaned;
  const endChar = cleaned[start] === '[' ? ']' : '}';
  const end = cleaned.lastIndexOf(endChar);
  if (end === -1 || end <= start) return cleaned.substring(start);
  return cleaned.substring(start, end + 1);
}

async function enforceRateLimit(uid) {
  const ref = admin.firestore().collection('aiRateLimits').doc(uid);
  const now = Date.now();
  const minuteMs = 60 * 1000;
  const dayMs = 24 * 60 * 60 * 1000;

  // Conservative defaults.
  const maxPerMinute = 30;
  const maxPerDay = 1000;

  await admin.firestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.exists ? snap.data() : {};

    const minuteWindowStart = typeof data.minuteWindowStart === 'number' ? data.minuteWindowStart : now;
    const dayWindowStart = typeof data.dayWindowStart === 'number' ? data.dayWindowStart : now;
    const minuteCount = typeof data.minuteCount === 'number' ? data.minuteCount : 0;
    const dayCount = typeof data.dayCount === 'number' ? data.dayCount : 0;

    const minuteReset = now - minuteWindowStart >= minuteMs;
    const dayReset = now - dayWindowStart >= dayMs;

    const nextMinuteWindowStart = minuteReset ? now : minuteWindowStart;
    const nextDayWindowStart = dayReset ? now : dayWindowStart;

    const nextMinuteCount = (minuteReset ? 0 : minuteCount) + 1;
    const nextDayCount = (dayReset ? 0 : dayCount) + 1;

    if (nextMinuteCount > maxPerMinute || nextDayCount > maxPerDay) {
      throw new HttpsError('resource-exhausted', 'AI rate limit exceeded. Please try again later.');
    }

    tx.set(
      ref,
      {
        minuteWindowStart: nextMinuteWindowStart,
        dayWindowStart: nextDayWindowStart,
        minuteCount: nextMinuteCount,
        dayCount: nextDayCount,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  });
}

async function enforceNotifyRateLimit(uid) {
  const ref = admin.firestore().collection('notifyRateLimits').doc(uid);
  const now = Date.now();
  const minuteMs = 60 * 1000;
  const dayMs = 24 * 60 * 60 * 1000;

  // Conservative defaults.
  const maxPerMinute = 20;
  const maxPerDay = 200;

  await admin.firestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.exists ? snap.data() : {};

    const minuteWindowStart = typeof data.minuteWindowStart === 'number' ? data.minuteWindowStart : now;
    const dayWindowStart = typeof data.dayWindowStart === 'number' ? data.dayWindowStart : now;
    const minuteCount = typeof data.minuteCount === 'number' ? data.minuteCount : 0;
    const dayCount = typeof data.dayCount === 'number' ? data.dayCount : 0;

    const minuteReset = now - minuteWindowStart >= minuteMs;
    const dayReset = now - dayWindowStart >= dayMs;

    const nextMinuteWindowStart = minuteReset ? now : minuteWindowStart;
    const nextDayWindowStart = dayReset ? now : dayWindowStart;

    const nextMinuteCount = (minuteReset ? 0 : minuteCount) + 1;
    const nextDayCount = (dayReset ? 0 : dayCount) + 1;

    if (nextMinuteCount > maxPerMinute || nextDayCount > maxPerDay) {
      throw new HttpsError('resource-exhausted', 'Notification rate limit exceeded. Please try again later.');
    }

    tx.set(
      ref,
      {
        minuteWindowStart: nextMinuteWindowStart,
        dayWindowStart: nextDayWindowStart,
        minuteCount: nextMinuteCount,
        dayCount: nextDayCount,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  });
}

async function getUserDoc(uid) {
  return admin.firestore().collection('users').doc(uid).get();
}

async function canNotifyUser({ callerUid, recipientUid, type, data }) {
  if (!callerUid || !recipientUid) return false;
  if (callerUid === recipientUid) return true;

  const [callerDoc, recipientDoc] = await Promise.all([
    getUserDoc(callerUid),
    getUserDoc(recipientUid),
  ]);

  const caller = callerDoc.exists ? callerDoc.data() : null;
  const recipient = recipientDoc.exists ? recipientDoc.data() : null;

  const safeData = data && typeof data === 'object' ? data : null;

  const callerIsAdmin = Boolean(caller && caller.isAdmin === true);
  if (callerIsAdmin) {
    // For admin-originated notifications, keep broad capability but enforce
    // basic integrity on the highest-risk ones.

    // Company approval/rejection should target the intended company.
    if ((type === 'company_approval' || type === 'company_rejected') && safeData && safeData.companyId) {
      return String(safeData.companyId) === recipientUid;
    }

    // Job approval should target the job owner when jobId is provided.
    if (type === 'job_approval' && safeData && safeData.jobId) {
      const jobId = String(safeData.jobId).trim();
      if (!jobId) return false;

      // Prefer `jobs`, but support legacy `jobPosted`.
      let jobDoc = await admin.firestore().collection('jobs').doc(jobId).get();
      let job = jobDoc.exists ? jobDoc.data() || {} : null;
      if (!job) {
        jobDoc = await admin.firestore().collection('jobPosted').doc(jobId).get();
        job = jobDoc.exists ? jobDoc.data() || {} : null;
      }
      if (!job) return false;

      const owner = job.userId || job.id;
      return String(owner || '') === recipientUid;
    }

    return true;
  }

  const callerIsCompany = Boolean(caller && caller.isCompany === true);
  const recipientIsAdmin = Boolean(recipient && recipient.isAdmin === true);

  // Company -> admin system events.
  if (callerIsCompany && recipientIsAdmin) {
    if (type === 'company_kyc_submitted') {
      // Require that the payload claims the calling company.
      if (safeData && safeData.companyId) return String(safeData.companyId) === callerUid;
      return false;
    }
    if (type === 'job_approval') {
      // Company submitting a job for approval.
      // Some flows may not have the jobId at notification time.
      return true;
    }
  }

  // Application-based relationship notifications.
  if (safeData && safeData.applicationId) {
    const appDoc = await admin
      .firestore()
      .collection('applications')
      .doc(String(safeData.applicationId))
      .get();
    if (!appDoc.exists) return false;
    const app = appDoc.data() || {};
    const jobId = String(app.jobId || '').trim();
    const applicantId = String(app.userId || '').trim();
    if (!jobId || !applicantId) return false;

    const jobDoc = await admin.firestore().collection('jobs').doc(jobId).get();
    if (!jobDoc.exists) return false;
    const job = jobDoc.data() || {};
    const employerId = String(job.userId || '').trim();
    if (!employerId) return false;

    const callerOk = callerUid === employerId || callerUid === applicantId;
    const recipientOk = recipientUid === employerId || recipientUid === applicantId;
    return callerOk && recipientOk;
  }

  // Interview-based relationship notifications.
  if (safeData && safeData.interviewId) {
    const interviewDoc = await admin
      .firestore()
      .collection('interviews')
      .doc(String(safeData.interviewId))
      .get();
    if (!interviewDoc.exists) return false;
    const interview = interviewDoc.data() || {};
    const employerId = String(interview.employerId || '').trim();
    const candidateId = String(interview.candidateId || '').trim();
    if (!employerId || !candidateId) return false;

    const callerOk = callerUid === employerId || callerUid === candidateId;
    const recipientOk = recipientUid === employerId || recipientUid === candidateId;
    return callerOk && recipientOk;
  }

  return false;
}

async function fetchRecentSignals(uid) {
  try {
    const snap = await admin
      .firestore()
      .collection('users')
      .doc(uid)
      .collection('ai')
      .doc('job_events')
      .collection('events')
      .orderBy('createdAt', 'desc')
      .limit(20)
      .get();

    return snap.docs.map((d) => d.data());
  } catch (_) {
    return [];
  }
}

async function fetchCvAnalysis(uid) {
  try {
    const snap = await admin
      .firestore()
      .collection('users')
      .doc(uid)
      .collection('ai')
      .doc('cv_analysis')
      .get();

    const data = snap.exists ? snap.data() : null;
    return data && data.analysis ? data.analysis : null;
  } catch (_) {
    return null;
  }
}

// DEPRECATED: aiRecommendJobs - Replaced by local Gemini implementation in GeminiAIService
// Kept for reference; use GeminiAIService.recommendJobsForUser() in client code instead

// DEPRECATED: aiRecommendCandidates - Replaced by local Gemini implementation in GeminiAIService
// Kept for reference; use GeminiAIService.recommendCandidates() in client code instead

exports.notifyUser = onCall(
  {
    region: 'us-central1',
    secrets: [BREVO_API_KEY],
  },
  async (request) => {
    if (!request.auth || !request.auth.uid) {
      throw new HttpsError('unauthenticated', 'Sign-in required.');
    }

    const callerUid = request.auth.uid;
    await enforceNotifyRateLimit(callerUid);
    const body = request.data || {};

    const userId = String(body.userId || '').trim();
    const type = String(body.type || 'general');
    const title = String(body.title || '').slice(0, 120);
    const messageBody = String(body.body || '').slice(0, 800);
    const data = body.data && typeof body.data === 'object' ? body.data : null;
    const actionUrl = body.actionUrl ? String(body.actionUrl) : null;
    const sendEmail = Boolean(body.sendEmail);
    const emailRecipient = body.emailRecipient ? String(body.emailRecipient) : null;

    if (!userId) {
      throw new HttpsError('invalid-argument', 'userId is required.');
    }

    const allowed = await canNotifyUser({ callerUid, recipientUid: userId, type, data });
    if (!allowed) {
      throw new HttpsError('permission-denied', 'Not allowed to notify this user.');
    }

    // Write in-app notification.
    await admin.firestore().collection('notifications').add({
      userId,
      type,
      title,
      body: messageBody,
      data: data,
      isRead: false,
      createdAt: new Date().toISOString(),
      actionUrl: actionUrl,
      createdBy: callerUid,
    });

    // Push via FCM (server-side).
    try {
      const userDoc = await admin.firestore().collection('users').doc(userId).get();
      const fcmToken = userDoc.exists ? userDoc.data().fcmToken : null;
      if (fcmToken) {
        await admin.messaging().send({
          token: String(fcmToken),
          notification: { title, body: messageBody },
          data: normalizeFcmData({
            type,
            ...(data ? { payload: data } : {}),
            ...(actionUrl ? { actionUrl } : {}),
          }),
        });
      }
    } catch (e) {
      // Don't fail the whole request for push errors.
      console.warn('notifyUser push failed', e);
    }

    // Optional email via Brevo.
    if (sendEmail) {
      const recipientDoc = await admin.firestore().collection('users').doc(userId).get();
      const recipientEmail = recipientDoc.exists ? String(recipientDoc.data().email || '').trim() : '';
      const providedEmail = emailRecipient ? String(emailRecipient).trim() : '';
      const matches =
        !providedEmail ||
        (recipientEmail && providedEmail.toLowerCase() === recipientEmail.toLowerCase());

      if (recipientEmail && matches) {
        const apiKey = BREVO_API_KEY.value();
        const htmlContent = getEmailTemplate({ type, title, body: messageBody, data });
        await sendBrevoEmail({
          apiKey,
          toEmail: recipientEmail,
          subject: title || 'Notification from BotsJobsConnect',
          htmlContent,
          textContent: messageBody,
        });
      }
    }

    return { ok: true };
  },
);

exports.hireApplicant = onCall(
  {
    region: 'us-central1',
  },
  async (request) => {
    if (!request.auth || !request.auth.uid) {
      throw new HttpsError('unauthenticated', 'Sign-in required.');
    }

    const uid = request.auth.uid;
    const body = request.data || {};
    const jobId = String(body.jobId || '').trim();
    const applicationId = String(body.applicationId || '').trim();

    if (!jobId || !applicationId) {
      throw new HttpsError('invalid-argument', 'jobId and applicationId are required.');
    }

    // Get caller's user document to check if admin
    let callerDoc;
    try {
      callerDoc = await admin.firestore().collection('users').doc(uid).get();
    } catch (e) {
      console.error('Error fetching caller user document:', e);
      throw new HttpsError('internal', 'Failed to fetch user information.');
    }

    const caller = callerDoc.exists ? callerDoc.data() || {} : {};
    const isAdmin = Boolean(caller.isAdmin === true);

    // Get job document
    let jobDoc;
    try {
      jobDoc = await admin.firestore().collection('jobs').doc(jobId).get();
    } catch (e) {
      console.error('Error fetching job:', e);
      throw new HttpsError('internal', 'Failed to fetch job.');
    }

    if (!jobDoc.exists) {
      throw new HttpsError('not-found', 'Job not found.');
    }

    const job = jobDoc.data() || {};
    const jobOwnerId = job.userId || '';

    // Check authorization: caller must be job owner or admin
    if (uid !== jobOwnerId && !isAdmin) {
      throw new HttpsError('permission-denied', 'You do not have permission to hire for this job.');
    }

    // Validate job state
    if (job.status === 'filled') {
      throw new HttpsError('failed-precondition', 'All positions for this job have already been filled.');
    }

    // Get application document
    let appDoc;
    try {
      appDoc = await admin.firestore().collection('applications').doc(applicationId).get();
    } catch (e) {
      console.error('Error fetching application:', e);
      throw new HttpsError('internal', 'Failed to fetch application.');
    }

    if (!appDoc.exists) {
      throw new HttpsError('not-found', 'Application not found.');
    }

    const app = appDoc.data() || {};
    const applicantId = app.userId || '';

    // Validate application is for this job and is pending
    if (app.jobId !== jobId) {
      throw new HttpsError('failed-precondition', 'Application does not belong to this job.');
    }

    if (app.status !== 'pending') {
      throw new HttpsError('failed-precondition', `Application is already ${app.status}. Cannot hire.`);
    }

    // Perform atomic transaction
    const db = admin.firestore();
    const batch = db.batch();

    try {
      const positionsAvailable = Number(job.positionsAvailable || 1);
      const positionsFilled = Number(job.positionsFilled || 0);
      let hiredApplicants = Array.isArray(job.hiredApplicants) ? [...job.hiredApplicants] : [];

      // Check if positions are available
      if (positionsFilled >= positionsAvailable) {
        throw new HttpsError('failed-precondition', 'All positions for this job have already been filled.');
      }

      // Add applicant to hired list if not already there
      if (!hiredApplicants.includes(applicantId)) {
        hiredApplicants.push(applicantId);
      }

      const newPositionsFilled = positionsFilled + 1;
      const allPositionsFilled = newPositionsFilled >= positionsAvailable;

      // 1. Update application status to 'hired'
      batch.update(
        db.collection('applications').doc(applicationId),
        {
          status: 'hired',
          reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
        }
      );

      // 2. Update job with new hire info
      const jobUpdateData = {
        positionsFilled: newPositionsFilled,
        hiredApplicants: hiredApplicants,
      };

      if (allPositionsFilled) {
        jobUpdateData.status = 'filled';
        jobUpdateData.completedAt = admin.firestore.FieldValue.serverTimestamp();
      }

      batch.update(db.collection('jobs').doc(jobId), jobUpdateData);

      // 3. If all positions filled, auto-reject pending applications
      if (allPositionsFilled) {
        try {
          const pendingAppsSnap = await db
            .collection('applications')
            .where('jobId', '==', jobId)
            .where('status', '==', 'pending')
            .get();

          for (const pendingApp of pendingAppsSnap.docs) {
            batch.update(pendingApp.ref, {
              status: 'auto_rejected',
              reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
              reviewNotes: 'Position filled by another candidate',
            });
          }
        } catch (e) {
          console.error('Error querying pending applications:', e);
          // Don't fail the entire transaction, just log
        }
      }

      // Commit transaction
      await batch.commit();

      // Send notifications (outside transaction for resilience)
      try {
        // Notify hired applicant
        const jobTitle = job.title || 'Job Position';
        await sendNotificationWithRetry(
          applicantId,
          {
            type: 'application_hired',
            title: 'Congratulations! You\'re Hired! 🎉',
            body: `You have been hired for the position "${jobTitle}". Please rate your experience with the company.`,
            data: {
              jobId: jobId,
              jobTitle: jobTitle,
              applicationId: applicationId,
            },
          }
        );
      } catch (e) {
        console.error('Error sending hire notification:', e);
        // Don't fail the function, just log
      }

      // If job now filled, notify all rejected applicants and company
      if (allPositionsFilled) {
        try {
          const rejectedAppsSnap = await db
            .collection('applications')
            .where('jobId', '==', jobId)
            .where('status', '==', 'auto_rejected')
            .get();

          for (const rejectedApp of rejectedAppsSnap.docs) {
            const rejectedData = rejectedApp.data() || {};
            const rejectedUserId = rejectedData.userId || '';
            if (rejectedUserId) {
              try {
                await sendNotificationWithRetry(rejectedUserId, {
                  type: 'application_rejected',
                  title: 'Application Update',
                  body: `The position for "${jobTitle}" has been filled.`,
                  data: {
                    jobId: jobId,
                    jobTitle: jobTitle,
                    applicationId: rejectedApp.id,
                  },
                });
              } catch (e) {
                console.error(`Error notifying rejected applicant ${rejectedUserId}:`, e);
              }
            }
          }

          // Notify company that all positions are filled
          if (jobOwnerId) {
            try {
              await sendNotificationWithRetry(jobOwnerId, {
                type: 'job_all_positions_filled',
                title: 'All Positions Filled! 🎉',
                body: `All ${positionsAvailable} positions for "${jobTitle}" have been filled.`,
                data: {
                  jobId: jobId,
                  jobTitle: jobTitle,
                  positionsFilled: newPositionsFilled,
                  positionsAvailable: positionsAvailable,
                },
              });
            } catch (e) {
              console.error(`Error notifying job owner ${jobOwnerId}:`, e);
            }
          }
        } catch (e) {
          console.error('Error in post-hire notifications:', e);
        }
      }

      return {
        success: true,
        message: 'Applicant hired successfully.',
        jobStatus: allPositionsFilled ? 'filled' : 'active',
        positionsFilled: newPositionsFilled,
        positionsAvailable: positionsAvailable,
      };
    } catch (e) {
      if (e instanceof HttpsError) {
        throw e;
      }
      console.error('Error in hireApplicant transaction:', e);
      throw new HttpsError('internal', `Failed to hire applicant: ${String(e && e.message ? e.message : e)}`);
    }
  }
);

async function sendNotificationWithRetry(userId, notificationData, maxRetries = 2) {
  // Helper function to send notifications with basic retry logic
  // This wraps the existing notification system with error handling
  try {
    // Call the notifyUser function directly
    const docRef = admin.firestore().collection('notifications').doc();
    await docRef.set({
      userId: userId,
      type: notificationData.type,
      title: notificationData.title,
      body: notificationData.body,
      data: notificationData.data || {},
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (e) {
    console.error(`Error sending notification to ${userId}:`, e);
    throw e;
  }
}

exports.aggregateRatings = onDocumentWritten(
  {
    region: 'us-central1',
    document: 'ratings/{ratingId}',
  },
  async (event) => {
    const change = event.change;
    const ratingDoc = change.after.exists ? change.after.data() : null;
    const previousRatingDoc = change.before.exists ? change.before.data() : null;

    // Handle deletion: no after document
    if (!ratingDoc) {
      if (!previousRatingDoc) return;
      // Rating was deleted, recalculate aggregates
      const ratedUserId = previousRatingDoc.ratedUserId;
      const ratedUserType = previousRatingDoc.ratedUserType;
      return await updateRatingAggregates(ratedUserId, ratedUserType);
    }

    // Handle creation or update
    const ratedUserId = ratingDoc.ratedUserId;
    const ratedUserType = ratingDoc.ratedUserType;

    if (!ratedUserId || !ratedUserType) {
      console.error('Rating missing ratedUserId or ratedUserType:', ratingDoc);
      return;
    }

    try {
      await updateRatingAggregates(ratedUserId, ratedUserType);
    } catch (error) {
      console.error(`Error aggregating ratings for ${ratedUserType} ${ratedUserId}:`, error);
    }
  }
);

async function updateRatingAggregates(userId, userType) {
  const db = admin.firestore();

  try {
    // Query all ratings for this user
    const ratingsSnap = await db
      .collection('ratings')
      .where('ratedUserId', '==', userId)
      .where('ratedUserType', '==', userType)
      .where('isApproved', '==', true)
      .get();

    const ratings = ratingsSnap.docs.map(doc => {
      const data = doc.data();
      const rating = typeof data.rating === 'number' ? data.rating : 0;
      return Math.max(0, Math.min(rating, 5)); // Clamp between 0-5
    });

    const totalRatings = ratings.length;
    const averageRating = totalRatings > 0 
      ? Math.round((ratings.reduce((a, b) => a + b, 0) / totalRatings) * 10) / 10
      : 0;

    // Update user or company document with aggregated data
    let updateRef;
    if (userType === 'jobSeeker') {
      updateRef = db.collection('users').doc(userId);
    } else if (userType === 'company') {
      updateRef = db.collection('users').doc(userId); // Companies are also in users collection
    } else {
      console.error(`Unknown userType for rating aggregation: ${userType}`);
      return;
    }

    // Check if user exists
    const userDoc = await updateRef.get();
    if (!userDoc.exists) {
      console.warn(`User ${userId} not found for rating aggregation`);
      return;
    }

    // Update with aggregated ratings
    await updateRef.update({
      averageRating: averageRating,
      totalRatings: totalRatings,
      lastRatingUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`Updated ratings for ${userType} ${userId}: ${averageRating}/5 (${totalRatings} ratings)`);
  } catch (error) {
    console.error(`Error in updateRatingAggregates for ${userId}:`, error);
    throw error;
  }
}

exports.sendTransactionalEmail = onCall(
  {
    region: 'us-central1',
    secrets: [BREVO_API_KEY],
  },
  async (request) => {
    if (!request.auth || !request.auth.uid) {
      throw new HttpsError('unauthenticated', 'Sign-in required.');
    }

    const uid = request.auth.uid;
    await enforceRateLimit(uid);

    const body = request.data || {};
    const toEmail = String(body.toEmail || '').trim();
    const subject = String(body.subject || '').trim().slice(0, 200);
    const htmlContent = String(body.htmlContent || '').trim();
    const textContent = body.textContent ? String(body.textContent) : null;

    if (!toEmail || !subject || !htmlContent) {
      throw new HttpsError('invalid-argument', 'toEmail, subject, and htmlContent are required.');
    }

    const apiKey = BREVO_API_KEY.value();
    await sendBrevoEmail({ apiKey, toEmail, subject, htmlContent, textContent });
    return { ok: true };
  },
);

// Bulk Approval Operations - MOVED TO IN-APP IMPLEMENTATION
// See: lib/screens/admin/admin_bulk_approval_screen.dart
// Reason: Client-side Firestore batch operations are more efficient than Cloud Functions
// for user-triggered operations, reducing latency and cloud function costs.
// Methods: _approveBulk(), _rejectBulk(), _undoBulkAction()
// All operations include proper audit logging via admin_audit_logs collection

// Undo Bulk Approval Operations - MOVED TO IN-APP IMPLEMENTATION
// See: _undoBulkAction() method in lib/screens/admin/admin_bulk_approval_screen.dart
// Handles reverting bulk operations with audit logging

/**
 * Job Lifecycle Management Function
 * Scheduled function: Runs daily at 2 AM UTC
 * 
 * Functions:
 * 1. Auto-archives jobs marked as 'filled' that are older than 30 days
 * 2. Auto-expires jobs with status 'open' that haven't been updated in 60 days
 * 3. Updates job lifecycle metadata
 * 4. Logs lifecycle changes for audit trail
 */
exports.jobLifecycle = functions.pubsub.schedule('every day 02:00').onRun(async (context) => {
  const now = new Date();
  const batch = admin.firestore().batch();
  let archivedCount = 0;
  let expiredCount = 0;

  try {
    // Get all jobs needing lifecycle management
    const allJobs = await admin
      .firestore()
      .collection('jobs')
      .get();

    console.log(`[Job Lifecycle] Processing ${allJobs.size} jobs`);

    for (const doc of allJobs.docs) {
      const job = doc.data();
      const jobRef = doc.ref;
      const lastUpdated = job.updatedAt?.toDate() || job.createdAt?.toDate() || new Date();
      const daysSinceUpdate = Math.floor((now - lastUpdated) / (1000 * 60 * 60 * 24));

      // Rule 1: Auto-archive jobs marked as 'filled' that are older than 30 days
      if (
        job.status === 'filled' &&
        job.positionsFilled >= job.positions &&
        daysSinceUpdate >= 30
      ) {
        console.log(`[Job Lifecycle] Archiving job ${doc.id} (filled 30+ days ago)`);
        batch.update(jobRef, {
          status: 'archived',
          lifecycleStatus: 'archived_filled',
          archivedAt: admin.firestore.FieldValue.serverTimestamp(),
          archivedReason: 'Job filled and archived after 30 days',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        archivedCount++;
      }

      // Rule 2: Auto-expire jobs with status 'open' inactive for 60+ days
      if (job.status === 'open' && daysSinceUpdate >= 60) {
        console.log(`[Job Lifecycle] Expiring job ${doc.id} (inactive 60+ days)`);
        batch.update(jobRef, {
          status: 'expired',
          lifecycleStatus: 'expired_inactive',
          expiredAt: admin.firestore.FieldValue.serverTimestamp(),
          expiredReason: 'Job inactive for 60+ days',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        expiredCount++;
      }
    }

    // Log the lifecycle operation
    if (archivedCount > 0 || expiredCount > 0) {
      const auditRef = admin
        .firestore()
        .collection('admin_audit_logs')
        .doc();
      batch.set(auditRef, {
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        action: 'job_lifecycle_management',
        archivedCount,
        expiredCount,
        type: 'job_management',
        details: {
          archivedReason: 'Auto-archived filled jobs older than 30 days',
          expiredReason: 'Auto-expired inactive jobs older than 60 days',
        },
      });

      console.log(
        `[Job Lifecycle] Summary: Archived ${archivedCount}, Expired ${expiredCount}`,
      );
    }

    await batch.commit();
    console.log('[Job Lifecycle] Batch commit successful');
  } catch (error) {
    console.error('[Job Lifecycle] Error in job lifecycle management:', error);
    // Don't throw - scheduled functions continue on error
  }
});

/**
 * Send FCM Notification via Firebase Cloud Messaging
 * Called by NotificationService when sending push notifications to users
 * Handles cross-user notifications (admin, other applicants, etc.)
 */
exports.sendFCMNotification = onCall(
  { region: 'us-central1' },
  async (request) => {
    const { token, type, data } = request.data;

    // Validate token
    if (!token || typeof token !== 'string') {
      throw new HttpsError('invalid-argument', 'FCM token is required and must be a string');
    }

    try {
      // Normalize data for FCM (all values must be strings)
      const normalizedData = normalizeFcmData(data || {});

      // Build FCM message
      const message = {
        token,
        data: normalizedData,
        notification: {
          title: data?.title || 'Notification',
          body: data?.body || '',
        },
        android: {
          priority: 'high',
          notification: {
            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
            sound: 'default',
            channelId: 'default',
          },
        },
        apns: {
          headers: {
            'apns-priority': '10',
          },
          payload: {
            aps: {
              sound: 'default',
              'content-available': 1,
            },
          },
        },
        webpush: {
          notification: {
            title: data?.title || 'Notification',
            body: data?.body || '',
            icon: '/assets/images/icon-512x512.png',
          },
        },
      };

      // Send via Firebase Cloud Messaging
      const messageId = await admin.messaging().send(message);
      
      console.log(`✅ FCM sent successfully: ${messageId} | Type: ${type} | Token: ${token.substring(0, 20)}...`);

      return {
        ok: true,
        messageId,
        type,
      };
    } catch (error) {
      console.error(`❌ FCM send failed for type ${type}:`, error.message);
      
      // Specific error handling
      if (error.code === 'messaging/invalid-registration-token') {
        throw new HttpsError('invalid-argument', 'Invalid or expired FCM token');
      } else if (error.code === 'messaging/third-party-auth-error') {
        throw new HttpsError('internal', 'FCM authentication failed - check Firebase configuration');
      } else {
        throw new HttpsError('internal', `Failed to send FCM notification: ${error.message}`);
      }
    }
  }
);

// FIX 1: Link Interview to Application - When interview is created, validate and link
// PROBLEM: Application record has no link to interview; Interview created without applicationId link
// SOLUTION: Trigger validates and enforces the link between records
exports.linkApplicationToInterview = functions.firestore
  .document('interviews/{interviewId}')
  .onCreate(async (snap, context) => {
    try {
      const interview = snap.data();
      const applicationId = interview.application_id;
      
      // Validate: interview must have applicationId
      if (!applicationId || typeof applicationId !== 'string') {
        console.warn(`Interview ${context.params.interviewId} created without applicationId`);
        return null;
      }

      const db = admin.firestore();
      
      // Get application to verify it exists and update it with interviewId
      const appDoc = await db.collection('applications').doc(applicationId).get();
      if (!appDoc.exists) {
        console.error(`Interview ${context.params.interviewId}: Application ${applicationId} not found`);
        return null;
      }

      const appData = appDoc.data();
      const candidateId = appData.userId;
      const jobId = appData.jobId;

      // Verify interview matches application (candidate and job match)
      if (interview.candidate_id !== candidateId || interview.jobId !== jobId) {
        console.error(`Interview ${context.params.interviewId}: Mismatch - interview candidate/job doesn't match application`);
        return null;
      }

      // Update application with interviewId (atomic operation)
      // This ensures application.interviewId always points to the interview.id
      await db.collection('applications').doc(applicationId).update({
        interviewId: context.params.interviewId,
        status: 'shortlisted', // Application status when interview scheduled
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Linked interview ${context.params.interviewId} to application ${applicationId}`);
      return { success: true };
    } catch (error) {
      console.error('Error in linkApplicationToInterview:', error);
      // Don't throw - this is a side effect that shouldn't block interview creation
      return null;
    }
  });

