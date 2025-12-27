// ignore_for_file: constant_identifier_names, deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// FREE Email Service using Brevo (formerly Sendinblue)
/// Perfect for Botswana and African countries!
///
/// SETUP (2 minutes):
/// 1. Sign up at brevo.com (FREE - 300 emails/day!)
/// 2. Get API Key: Settings → SMTP & API → API Keys → Create
/// 3. Paste API key below in BREVO_API_KEY
/// 4. Update FROM_EMAIL

class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  // ═══════════════════════════════════════════════════════════════
  // CONFIGURATION - UPDATE THESE
  // ═══════════════════════════════════════════════════════════════

  /// The email that will appear in "From" field (can be any email)
  static const String FROM_EMAIL = 'noreply@botsjobsconnect.com';
  static const String FROM_NAME = 'BotsJobsConnect';

  /// Set to false to just log emails (testing), true to actually send
  static const bool PRODUCTION_MODE = true; // Enabled for production

  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  // ═══════════════════════════════════════════════════════════════

  /// Send email via Brevo API
  Future<bool> _sendEmail({
    required String toEmail,
    required String subject,
    required String htmlContent,
    String? plainTextContent,
  }) async {
    if (!PRODUCTION_MODE) {
      _logEmail(toEmail, subject, plainTextContent ?? htmlContent);
      return true;
    }

    try {
      final callable = _functions.httpsCallable('sendTransactionalEmail');
      final result = await callable.call(<String, dynamic>{
        'toEmail': toEmail,
        'subject': subject,
        'htmlContent': htmlContent,
        if (plainTextContent != null) 'textContent': plainTextContent,
      });

      final data = result.data;
      final ok = (data is Map) ? (data['ok'] == true) : true;
      if (ok) {
        debugPrint('✅ Email sent successfully to $toEmail (via server)');
      }
      return ok;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ sendTransactionalEmail failed: ${e.code} ${e.message}');
      return false;
    } catch (e) {
      debugPrint('❌ Error sending email via server: $e');
      return false;
    }
  }

  /// Log email to console (development mode)
  void _logEmail(String toEmail, String subject, String content) {
    debugPrint('''
    
    ═══════════════════════════════════════════════════════════════
    📧 EMAIL (DEVELOPMENT MODE - NOT ACTUALLY SENT)
    ═══════════════════════════════════════════════════════════════
    To: $toEmail
    From: $FROM_EMAIL ($FROM_NAME)
    Subject: $subject
    
    ${content.length > 500 ? '${content.substring(0, 500)}...' : content}
    ═══════════════════════════════════════════════════════════════
    
    💡 To send real emails:
    1. Sign up at brevo.com (FREE - 300 emails/day)
    2. Get API key from Brevo dashboard
    3. Update BREVO_API_KEY in email_service.dart
    4. Set PRODUCTION_MODE = true
    
    ✨ Brevo works great in Botswana and all African countries!
    ═══════════════════════════════════════════════════════════════
    ''');
  }

  /// Send company registration notification to an admin email.
  Future<bool> sendCompanyRegistrationNotification({
    required String adminEmail,
    required String companyName,
    required String companyEmail,
    required String registrationNumber,
    required String industry,
    required String website,
    required String companyId,
  }) async {
    final subject = '🏢 New Company Registration: $companyName';

    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; }
    .header { background: linear-gradient(135deg, #4461AD 0%, #0F6850 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
    .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
    .info-box { background: white; padding: 20px; margin: 20px 0; border-radius: 8px; border-left: 4px solid #EFC018; }
    .info-row { margin: 10px 0; }
    .label { font-weight: bold; color: #4461AD; }
    .button { display: inline-block; background: #0F6850; color: white; padding: 15px 30px; text-decoration: none; border-radius: 8px; margin: 20px 0; }
    .warning { background: #FFF3CD; border-left: 4px solid #EFC018; padding: 15px; margin: 20px 0; border-radius: 4px; }
  </style>
</head>
<body>
  <div class="header">
    <h1>🏢 New Company Registration</h1>
    <p>Requires Your Approval</p>
  </div>
  
  <div class="content">
    <p>A new company has registered on BotsJobsConnect and is awaiting your approval.</p>
    
    <div class="info-box">
      <div class="info-row"><span class="label">Company Name:</span> $companyName</div>
      <div class="info-row"><span class="label">Email:</span> $companyEmail</div>
      <div class="info-row"><span class="label">Registration #:</span> $registrationNumber</div>
      <div class="info-row"><span class="label">Industry:</span> $industry</div>
      <div class="info-row"><span class="label">Website:</span> <a href="$website">$website</a></div>
      <div class="info-row"><span class="label">Company ID:</span> $companyId</div>
    </div>
    
    <div class="warning">
      <strong>⚠️ Important:</strong> Please verify the company's registration documents and legitimacy before approval.
    </div>
    
    <center>
      <a href="https://yourapp.com/admin/approvals" class="button">Review in Admin Panel</a>
    </center>
  </div>
</body>
</html>
    ''';

    return await _sendEmail(
      toEmail: adminEmail,
      subject: subject,
      htmlContent: htmlContent,
    );
  }

  /// Send approval email to company
  Future<bool> sendCompanyApprovalEmail({
    required String toEmail,
    required String companyName,
  }) async {
    final subject = '✅ Your Company Has Been Approved!';

    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; }
    .header { background: linear-gradient(135deg, #0F6850 0%, #4461AD 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
    .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
    .success-icon { font-size: 60px; text-align: center; margin: 20px 0; }
    .features { background: white; padding: 20px; margin: 20px 0; border-radius: 8px; }
    .feature { margin: 15px 0; padding-left: 30px; position: relative; }
    .feature:before { content: '✓'; position: absolute; left: 0; color: #0F6850; font-weight: bold; font-size: 20px; }
    .button { display: inline-block; background: #EFC018; color: #000; padding: 15px 30px; text-decoration: none; border-radius: 8px; margin: 20px 0; font-weight: bold; }
  </style>
</head>
<body>
  <div class="header">
    <div class="success-icon">🎉</div>
    <h1>Congratulations!</h1>
    <p>Your Company Has Been Approved</p>
  </div>
  
  <div class="content">
    <p>Dear $companyName team,</p>
    <p>Great news! Your company registration on <strong>BotsJobsConnect</strong> has been approved.</p>
    
    <div class="features">
      <h3 style="color: #4461AD; margin-top: 0;">You can now:</h3>
      <div class="feature">Post unlimited job listings</div>
      <div class="feature">Search and browse candidate profiles</div>
      <div class="feature">Schedule interviews with applicants</div>
      <div class="feature">Access all employer features</div>
    </div>
    
    <center>
      <a href="https://yourapp.com/login" class="button">Log In & Start Posting Jobs</a>
    </center>
    
    <p>Best regards,<br><strong>The BotsJobsConnect Team</strong></p>
  </div>
</body>
</html>
    ''';

    return await _sendEmail(
      toEmail: toEmail,
      subject: subject,
      htmlContent: htmlContent,
    );
  }

  /// Send rejection email to company
  Future<bool> sendCompanyRejectionEmail({
    required String toEmail,
    required String companyName,
    required String reason,
  }) async {
    final subject = 'Update on Your Company Registration';

    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; }
    .header { background: #f8d7da; color: #721c24; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
    .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
    .reason-box { background: #fff3cd; border-left: 4px solid #ffc107; padding: 20px; margin: 20px 0; border-radius: 4px; }
    .support-box { background: white; padding: 20px; margin: 20px 0; border-radius: 8px; text-align: center; }
  </style>
</head>
<body>
  <div class="header">
    <h1>Company Registration Update</h1>
  </div>
  
  <div class="content">
    <p>Dear $companyName team,</p>
    <p>After careful review, we were unable to approve your company registration at this time.</p>
    
    <div class="reason-box">
      <strong>Reason:</strong><br>$reason
    </div>
    
    <div class="support-box">
      <h3 style="margin-top: 0; color: #4461AD;">Need Help?</h3>
      <p>Contact: <a href="mailto:support@botsjobsconnect.com">support@botsjobsconnect.com</a></p>
    </div>
    
    <p>Best regards,<br><strong>The BotsJobsConnect Team</strong></p>
  </div>
</body>
</html>
    ''';

    return await _sendEmail(
      toEmail: toEmail,
      subject: subject,
      htmlContent: htmlContent,
    );
  }

  /// Send job approval notification
  Future<bool> sendJobApprovalEmail({
    required String toEmail,
    required String jobTitle,
  }) async {
    final subject = '✅ Job Post Approved: $jobTitle';

    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; }
    .header { background: linear-gradient(135deg, #0F6850 0%, #4461AD 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
    .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
    .job-title { background: white; padding: 20px; margin: 20px 0; border-radius: 8px; border-left: 4px solid #0F6850; font-size: 18px; font-weight: bold; }
  </style>
</head>
<body>
  <div class="header">
    <h1>✅ Job Post Approved!</h1>
  </div>
  
  <div class="content">
    <p>Your job post has been approved and is now live on BotsJobsConnect.</p>
    <div class="job-title">📋 $jobTitle</div>
    <p>Job seekers can now find and apply to this position.</p>
    <p>Best regards,<br><strong>The BotsJobsConnect Team</strong></p>
  </div>
</body>
</html>
    ''';

    return await _sendEmail(
      toEmail: toEmail,
      subject: subject,
      htmlContent: htmlContent,
    );
  }
  /// Send job application email to employer
  Future<bool> sendJobApplicationEmail({
    required String toEmail,
    required String employerName,
    required String applicantName,
    required String jobTitle,
    required String applicantProfileUrl,
  }) async {
    final subject = 'New Application: $jobTitle';

    final htmlContent = '''
<!DOCTYPE html>
<html>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
  <div style="background: #0F6850; color: white; padding: 20px; text-align: center;">
    <h1>New Applicant! 🚀</h1>
  </div>
  <div style="padding: 20px; background: #f9f9f9;">
    <p>Dear $employerName,</p>
    <p><strong>$applicantName</strong> has just applied for your job posting: <strong>$jobTitle</strong>.</p>
    
    <div style="background: white; padding: 15px; margin: 20px 0; border-radius: 5px; border-left: 4px solid #0F6850;">
      <h3>Applicant Summary</h3>
      <p>Name: $applicantName</p>
      <p>Position: $jobTitle</p>
    </div>

    <center>
      <a href="$applicantProfileUrl" style="background: #0F6850; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">View Application</a>
    </center>
  </div>
</body>
</html>
    ''';

    return await _sendEmail(
      toEmail: toEmail,
      subject: subject,
      htmlContent: htmlContent,
    );
  }

  /// Send interview invitation email to candidate
  Future<bool> sendInterviewInviteEmail({
    required String toEmail,
    required String candidateName,
    required String employerName,
    required String jobTitle,
    required String interviewDate,
    required String interviewTime,
    required String interviewType,
    String? location,
    String? meetingLink,
  }) async {
    final subject = 'Interview Invitation: $jobTitle at $employerName';

    final htmlContent = '''
<!DOCTYPE html>
<html>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
  <div style="background: #4461AD; color: white; padding: 20px; text-align: center;">
    <h1>Interview Invitation 🤝</h1>
  </div>
  <div style="padding: 20px; background: #f9f9f9;">
    <p>Dear $candidateName,</p>
    <p>We are pleased to invite you to an interview for the <strong>$jobTitle</strong> position at <strong>$employerName</strong>.</p>
    
    <div style="background: white; padding: 15px; margin: 20px 0; border-radius: 5px; border-left: 4px solid #4461AD;">
      <h3>Interview Details</h3>
      <p><strong>Date:</strong> $interviewDate</p>
      <p><strong>Time:</strong> $interviewTime</p>
      <p><strong>Type:</strong> $interviewType</p>
      ${location != null ? '<p><strong>Location:</strong> $location</p>' : ''}
      ${meetingLink != null ? '<p><strong>Link:</strong> <a href="$meetingLink">$meetingLink</a></p>' : ''}
    </div>

    <p>Please make sure to be on time.</p>
  </div>
</body>
</html>
    ''';

    return await _sendEmail(
      toEmail: toEmail,
      subject: subject,
      htmlContent: htmlContent,
    );
  }
  /// Send AI Job Match email to candidate
  Future<bool> sendJobMatchEmail({
    required String toEmail,
    required String candidateName,
    required String jobTitle,
    required String companyName,
    required String matchReason,
    required String jobLink,
  }) async {
    final subject = '🔥 New Job Match: $jobTitle';

    final htmlContent = '''
<!DOCTYPE html>
<html>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
  <div style="background: linear-gradient(135deg, #EFC018 0%, #0F6850 100%); color: white; padding: 20px; text-align: center;">
    <h1>Perfect Match Found! 🎯</h1>
  </div>
  <div style="padding: 20px; background: #f9f9f9;">
    <p>Hi $candidateName,</p>
    <p>Our AI has found a new position that strongly matches your profile!</p>
    
    <div style="background: white; padding: 20px; margin: 20px 0; border-radius: 10px; box-shadow: 0 2px 5px rgba(0,0,0,0.1);">
      <h2 style="color: #0F6850; margin-top: 0;">$jobTitle</h2>
      <h3 style="color: #666; margin-top: 5px;">at $companyName</h3>
      
      <div style="margin-top: 15px; padding: 10px; background: #E8F5E9; border-radius: 5px; color: #1B5E20;">
        <strong>Why it's a match:</strong><br>
        $matchReason
      </div>
    </div>

    <center>
      <a href="$jobLink" style="background: #0F6850; color: white; padding: 15px 30px; text-decoration: none; border-radius: 30px; font-weight: bold; display: inline-block;">View Job & Apply</a>
    </center>
  </div>
</body>
</html>
    ''';

    return await _sendEmail(
      toEmail: toEmail,
      subject: subject,
      htmlContent: htmlContent,
    );
  }

  /// Send Admin Alert for New Job
  Future<bool> sendAdminNewJobAlert({
    required String adminEmail,
    required String companyName,
    required String jobTitle,
    required String jobId,
  }) async {
    final subject = '📢 New Job Pending Approval: $jobTitle';

    final htmlContent = '''
<!DOCTYPE html>
<html>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
  <div style="background: #333; color: white; padding: 15px; text-align: center;">
    <h1>Admin Alert 🛡️</h1>
  </div>
  <div style="padding: 20px; background: #f9f9f9;">
    <p><strong>$companyName</strong> has posted a new job: <strong>$jobTitle</strong>.</p>
    <p>It is currently awaiting approval.</p>
    <p>Job ID: $jobId</p>
    <center>
      <a href="https://botsjobsconnect.com/admin/jobs/$jobId" style="background: #333; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">Review Now</a>
    </center>
  </div>
</body>
</html>
    ''';
    
    return await _sendEmail(
      toEmail: adminEmail,
      subject: subject,
      htmlContent: htmlContent,
    );
  }
}
