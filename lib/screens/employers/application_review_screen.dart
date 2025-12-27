import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_app/models/application_model.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';
import 'package:freelance_app/services/ai/gemini_ai_service.dart';
import 'package:freelance_app/services/notifications/notification_service.dart';
import 'package:freelance_app/services/chat_service.dart';
import 'package:freelance_app/screens/chat/chat_screen.dart';
import 'package:freelance_app/services/auth/app_user_role.dart';
import 'package:freelance_app/widgets/reusable_widgets.dart';
import 'package:freelance_app/widgets/common/role_guard.dart';
import 'package:freelance_app/services/connectivity_service.dart';
import 'package:freelance_app/screens/employers/interview_scheduling_screen.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:freelance_app/widgets/common/standard_button.dart';
import 'package:freelance_app/widgets/common/contact_action_row.dart';
import 'package:freelance_app/screens/common/cv_document_viewer_screen.dart';
import 'package:freelance_app/screens/common/video_resume_viewer_screen.dart';
import 'package:freelance_app/services/firebase/firebase_storage_service.dart';
import 'package:freelance_app/widgets/dialogs/rate_freelancer_dialog.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';

class ApplicationReviewScreen extends StatefulWidget {
  final String applicationId;
  final String jobId;
  final String jobTitle;

  const ApplicationReviewScreen({
    super.key,
    required this.applicationId,
    required this.jobId,
    required this.jobTitle,
  });

  @override
  State<ApplicationReviewScreen> createState() =>
      _ApplicationReviewScreenState();
}

class _ApplicationReviewScreenState extends State<ApplicationReviewScreen>
    with ConnectivityAware {
  final _dbService = FirebaseDatabaseService();
  final _aiService = GeminiAIService();
  final _notificationService = NotificationService();
  final _storageService = FirebaseStorageService();
  ApplicationModel? _application;
  Map<String, dynamic>? _candidateProfile;
  Map<String, dynamic>? _jobData;
  Map<String, dynamic>? _aiAnalysis;
  bool _isLoading = true;
  bool _isAnalyzing = false;

  String? _candidateVideoResumeUrl;
  String? _candidateCvFileUrl;

  @override
  void initState() {
    super.initState();
    _loadApplication();
  }

  Future<void> _loadApplication() async {
    try {
      final appDoc = await _dbService.getApplication(widget.applicationId);
      if (appDoc == null) {
        if (mounted) {
          SnackbarHelper.showError(context, 'Application not found');
          Navigator.pop(context);
        }
        return;
      }

      final appData = appDoc.data() as Map<String, dynamic>;
      _application = ApplicationModel.fromMap(appData, widget.applicationId);

      // Load candidate profile
      final candidateDoc = await _dbService.getUser(_application!.userId);
      if (candidateDoc != null) {
        _candidateProfile = candidateDoc.data() as Map<String, dynamic>?;
      }

      // Load job data
      final jobDoc = await _dbService.getJob(widget.jobId);
      if (jobDoc != null) {
        _jobData = jobDoc.data() as Map<String, dynamic>?;
      }

      // Load CV if available
      final cvDoc = await _dbService.getCVByUserId(_application!.userId);
      if (cvDoc != null) {
        final cvData = cvDoc.data() as Map<String, dynamic>?;
        if (cvData != null && _candidateProfile != null) {
          _candidateProfile!['cv'] = cvData;
        }
      }

      // Extract video resume URL (from CV doc or user profile doc)
      final cvMap = (_candidateProfile?['cv'] as Map<String, dynamic>?) ??
          const <String, dynamic>{};
      final fromCv =
          (cvMap['videoResumeUrl'] ?? cvMap['video_resume_url'])?.toString();
      final fromUser = (_candidateProfile?['videoResumeUrl'] ??
              _candidateProfile?['video_resume_url'])
          ?.toString();
      _candidateVideoResumeUrl = (fromCv != null && fromCv.trim().isNotEmpty)
          ? fromCv.trim()
          : (fromUser != null && fromUser.trim().isNotEmpty)
              ? fromUser.trim()
              : null;

      // Best-effort: resolve candidate uploaded CV file URL from Storage.
      // (This only works if they actually uploaded a CV file to Storage.)
      try {
        _candidateCvFileUrl =
            await _storageService.getCVUrl(_application!.userId);
      } catch (_) {
        _candidateCvFileUrl = null;
      }

      // Auto-analyze with AI if not already analyzed
      if (_application!.aiMatchScore == null &&
          _candidateProfile != null &&
          _jobData != null) {
        await _analyzeWithAI();
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showError(context, 'Error loading application: $e');
      }
    }
  }

  Future<void> _analyzeWithAI() async {
    if (_candidateProfile == null || _jobData == null) return;

    setState(() => _isAnalyzing = true);

    try {
      final match = await _aiService.matchJobToCandidate(
        jobId: widget.jobId,                        // NEW: for caching
        candidateId: _application!.userId,          // NEW: for caching
        candidateProfile: _candidateProfile!,
        jobRequirements: _jobData!,
      );

      // Update application with AI analysis
      await _dbService.updateApplication(
        applicationId: widget.applicationId,
        data: {
          'aiMatchScore': match['matchScore'] as int?,
          'aiRecommendation': match['reasoning'] as String?,
        },
      );

      if (mounted) {
        setState(() {
          _aiAnalysis = match;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        debugPrint('AI analysis error: $e');
      }
    }
  }

  Future<void> _updateApplicationStatus(String status, {String? notes}) async {
    if (!await checkConnectivity(context,
        message: 'Cannot update application without internet.')) {
      return;
    }

    try {
      await _dbService.updateApplication(
        applicationId: widget.applicationId,
        data: {
          'status': status,
          'reviewedAt': DateTime.now().toIso8601String(),
          if (notes != null) 'reviewNotes': notes,
        },
      );

      // Send notification to candidate
      String notificationTitle;
      String notificationBody;
      String notificationType;

      switch (status) {
        case ApplicationStatus.approved:
          notificationTitle = 'Application Approved! 🎉';
          notificationBody =
              'Congratulations! Your application for "${widget.jobTitle}" has been approved. The employer may contact you for next steps.';
          notificationType = 'application_approved';
          break;
        case ApplicationStatus.rejected:
          notificationTitle = 'Application Update';
          notificationBody = notes != null && notes.isNotEmpty
              ? 'Your application for "${widget.jobTitle}" was not selected. Reason: $notes'
              : 'Your application for "${widget.jobTitle}" was not selected at this time.';
          notificationType = 'application_rejected';
          break;
        case ApplicationStatus.interviewScheduled:
          notificationTitle = 'Interview Scheduled 📅';
          notificationBody =
              'An interview has been scheduled for your application to "${widget.jobTitle}". Check your interviews section for details.';
          notificationType = 'interview_scheduled';
          break;
        case ApplicationStatus.shortlisted:
          notificationTitle = 'You\'ve Been Shortlisted! ⭐';
          notificationBody =
              'Great news! Your application for "${widget.jobTitle}" has been shortlisted. The employer will review your profile further.';
          notificationType = 'application_shortlisted';
          break;
        default:
          notificationTitle = 'Application Update';
          notificationBody =
              'Your application status for "${widget.jobTitle}" has been updated.';
          notificationType = 'application_status';
      }

      // Send in-app + email notification
      String? emailRecipient;
      try {
        // Get candidate email for rejection notifications
        if (status == ApplicationStatus.rejected && _application != null) {
          final candidateDoc = await _dbService.getUser(_application!.userId);
          emailRecipient = candidateDoc?.data() != null 
              ? (candidateDoc!.data() as Map<String, dynamic>)['email'] as String? 
              : null;
        }
      } catch (e) {
        debugPrint('Failed to get candidate email: $e');
      }

      await _notificationService.sendNotification(
        userId: _application!.userId,
        type: notificationType,
        title: notificationTitle,
        body: notificationBody,
        data: {
          'jobId': widget.jobId,
          'jobTitle': widget.jobTitle,
          'applicationId': widget.applicationId,
          'status': status,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
        sendEmail: true,
        emailRecipient: emailRecipient,
      );

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Application status updated');
        Navigator.pop(context, true); // Return true to refresh list
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error updating application: $e');
      }
    }
  }

  Future<void> _scheduleInterview() async {
    if (!await checkConnectivity(context,
        message: 'Cannot schedule interview without internet.')) {
      return;
    }

    if (!mounted) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InterviewSchedulingScreen(
          candidateId: _application!.userId,
          candidateName: _application!.applicantName,
          jobId: widget.jobId,
          jobTitle: widget.jobTitle,
          applicationId: widget.applicationId, // FIX 1: Pass applicationId to link records
        ),
      ),
    );

    if (result == true && mounted) {
      // Interview scheduled successfully
      // InterviewSchedulingScreen already:
      // - Created interview with application_id
      // - Updated application with interviewId
      // - Changed status to 'shortlisted'
      // Just refresh the UI and show success
      SnackbarHelper.showSuccess(context, 'Interview scheduled successfully!');
      Navigator.pop(context, true);
    }
  }

  Future<void> _hireApplicant() async {
    if (!await checkConnectivity(context,
        message: 'Cannot hire applicant without internet.')) {
      return;
    }

    if (!mounted) return;
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Dialog(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Processing hire...'),
            ],
          ),
        ),
      ),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // Client-side atomic transaction to hire applicant
      final db = FirebaseFirestore.instance;
      final result = await db.runTransaction<Map<String, dynamic>>((transaction) async {
        // Read job document
        final jobRef = db.collection('jobs').doc(widget.jobId);
        final jobSnapshot = await transaction.get(jobRef);
        
        if (!jobSnapshot.exists) {
          throw Exception('Job not found');
        }

        final jobData = jobSnapshot.data()!;
        final hiredApplicants = List<String>.from(jobData['hiredApplicants'] ?? []);
        final positionsFilled = (jobData['positionsFilled'] ?? 0) as int;
        final positionsAvailable = (jobData['positionsAvailable'] ?? 1) as int;
        final status = jobData['status'] as String?;

        // Validate job is not already filled
        if (status == 'filled' || positionsFilled >= positionsAvailable) {
          throw Exception('All positions for this job have already been filled.');
        }

        // Read application document
        final appRef = db.collection('applications').doc(widget.applicationId);
        final appSnapshot = await transaction.get(appRef);
        
        if (!appSnapshot.exists) {
          throw Exception('Application not found');
        }

        final appData = appSnapshot.data()!;
        final appStatus = appData['status'] as String?;
        final applicantId = appData['userId'] as String?;

        // Validate application is pending and applicant is not already hired
        if (appStatus != 'pending') {
          throw Exception('Application is not pending');
        }

        if (hiredApplicants.contains(applicantId)) {
          throw Exception('Applicant is already hired for this job');
        }

        if (applicantId == null || applicantId.isEmpty) {
          throw Exception('Invalid applicant ID');
        }

        // Atomic updates
        final newPositionsFilled = positionsFilled + 1;
        final newStatus = newPositionsFilled >= positionsAvailable ? 'filled' : jobData['status'];
        final newHiredApplicants = [...hiredApplicants, applicantId];

        // Update job: add applicant to hiredApplicants and increment positionsFilled
        final jobUpdate = {
          'hiredApplicants': newHiredApplicants,
          'positionsFilled': newPositionsFilled,
          'status': newStatus,
          'hiredAt': FieldValue.serverTimestamp(),
        };
        
        // Add completedAt when job is filled
        if (newPositionsFilled >= positionsAvailable) {
          jobUpdate['completedAt'] = FieldValue.serverTimestamp();
        }
        
        transaction.update(jobRef, jobUpdate);

        // Update application: mark as hired
        transaction.update(appRef, {
          'status': 'hired',
          'hiredAt': FieldValue.serverTimestamp(),
        });

        return {
          'success': true,
          'positionsFilled': newPositionsFilled,
          'positionsAvailable': positionsAvailable,
          'applicantId': applicantId,
        };
      });

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      SnackbarHelper.showSuccess(
        context,
        'Applicant hired successfully! ${result['positionsFilled']}/${result['positionsAvailable']} positions filled',
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      final errorMsg = e is FirebaseException 
        ? (e.message ?? e.code)
        : e.toString();
      SnackbarHelper.showError(context, 'Error hiring applicant: $errorMsg');
      debugPrint('Error hiring applicant: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allow: const {AppUserRole.employer},
      child: HintsWrapper(
        screenId: 'application_review',
        child: _isLoading
            ? const Scaffold(
                body: Center(
                  child: LoadingWidget(message: 'Loading application...'),
                ),
              )
            : _application == null
                ? const Scaffold(
                    body: Center(child: Text('Application not found')),
                  )
                : Scaffold(
                    resizeToAvoidBottomInset: true,
                    appBar: AppAppBar(
                      title: 'Review Application',
                      variant: AppBarVariant.primary,
                      actions: [
                        if (_isAnalyzing)
                          Padding(
                            padding: AppDesignSystem.paddingM,
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                      ],
                    ),
                    body: SingleChildScrollView(
                      padding: AppDesignSystem.paddingM,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCandidateInfo(),
                          AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
                          _buildAIAnalysis(),
                          AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
                          _buildApplicationDetails(),
                          AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
                          _buildActions(),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildCandidateInfo() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      padding: AppDesignSystem.paddingM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(
                imageUrl: _application!.applicantImage,
                name: _application!.applicantName,
                size: 64,
              ),
              AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _application!.applicantName,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    if (_application!.applicantEmail != null)
                      Text(
                        _application!.applicantEmail!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppDesignSystem.onSurfaceVariant(context)),
                      ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                    Text(
                      'Applied ${timeago.format(_application!.appliedAt)}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(_application!.status),
            ],
          ),
          if ((_candidateCvFileUrl != null &&
                  _candidateCvFileUrl!.isNotEmpty) ||
              (_candidateVideoResumeUrl != null &&
                  _candidateVideoResumeUrl!.isNotEmpty)) ...[
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_application!.status == ApplicationStatus.pending)
                  Row(
                    children: [
                      Expanded(
                        child: StandardButton(
                          label: 'Message Candidate',
                          onPressed: () async {
                            final chatService = ChatService();
                            final chatId = await chatService.getOrCreateChat(
                              FirebaseAuth.instance.currentUser!.uid,
                              _application!.userId,
                            );
                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                          chatId: chatId,
                                          otherUserName: _application!
                                              .applicantName, // We have name here
                                          otherUserId: _application!.userId,
                                        )),
                              );
                            }
                          },
                          type: StandardButtonType.secondary,
                          icon: Icons.message,
                        ),
                      ),
                      AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
                      Expanded(
                        child: StandardButton(
                          label: 'Shortlist',
                          onPressed: () => _updateApplicationStatus(
                              ApplicationStatus.shortlisted),
                          type: StandardButtonType.primary,
                        ),
                      ),
                    ],
                  ),
                if (_candidateCvFileUrl != null &&
                    _candidateCvFileUrl!.isNotEmpty)
                  StandardButton(
                    label: 'View CV',
                    icon: Icons.picture_as_pdf_outlined,
                    type: StandardButtonType.outlined,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CvDocumentViewerScreen(
                            cvUrl: _candidateCvFileUrl!,
                            title: '${_application!.applicantName} • CV',
                          ),
                        ),
                      );
                    },
                  ),
                if (_candidateVideoResumeUrl != null &&
                    _candidateVideoResumeUrl!.isNotEmpty)
                  StandardButton(
                    label: 'Play Video CV',
                    icon: Icons.play_circle_outline,
                    type: StandardButtonType.outlined,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VideoResumeViewerScreen(
                            videoUrl: _candidateVideoResumeUrl!,
                            title:
                                '${_application!.applicantName} • Video Resume',
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
          if (_application != null &&
              (_application!.coverLetter != null ||
                  _application!.bidAmount != null)) ...[
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
            const Text('Proposal',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
            Container(
              padding: AppDesignSystem.paddingS,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: AppDesignSystem.borderRadiusS,
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_application!.bidAmount != null) ...[
                    Row(children: [
                      Icon(Icons.monetization_on,
                          size: 16, color: Theme.of(context).colorScheme.tertiary),
                      AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
                      Text(
                        'Proposed Bid: BWP ${_application!.bidAmount!.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.tertiary),
                      ),
                    ]),
                    if (_application!.coverLetter != null) const Divider(),
                  ],
                  if (_application!.coverLetter != null)
                    Text(_application!.coverLetter!),
                ],
              ),
            ),
          ],
          if (_candidateProfile != null) ...[
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            ContactActionRow(
              email: _candidateProfile!['email'],
              phoneNumber: _candidateProfile!['phone'],
              compact: false,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final colorScheme = Theme.of(context).colorScheme;

    Color color;
    String label;
    IconData icon;

    switch (status) {
      case ApplicationStatus.approved:
        color = colorScheme.primary;
        label = 'Approved';
        icon = Icons.check_circle;
        break;
      case ApplicationStatus.rejected:
        color = colorScheme.error;
        label = 'Rejected';
        icon = Icons.cancel;
        break;
      case ApplicationStatus.interviewScheduled:
        color = colorScheme.tertiary;
        label = 'Interview';
        icon = Icons.calendar_today;
        break;
      default:
        color = colorScheme.onSurfaceVariant;
        label = 'Pending';
        icon = Icons.pending;
    }

    return Container(
      padding: AppDesignSystem.paddingSymmetric(
          horizontal: AppDesignSystem.spaceM,
          vertical: AppDesignSystem.spaceS - 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppDesignSystem.borderRadiusXL,
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          AppDesignSystem.horizontalSpace(AppDesignSystem.spaceXS),
          Text(
            label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAIAnalysis() {
    if (_isAnalyzing) {
      return AppCard(
        padding: AppDesignSystem.paddingM,
        child: Row(
          children: [
            CircularProgressIndicator(),
            AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
            Text('Analyzing candidate with AI...'),
          ],
        ),
      );
    }

    final score =
        _application!.aiMatchScore ?? _aiAnalysis?['matchScore'] as int?;
    if (score == null) {
      return AppCard(
        padding: AppDesignSystem.paddingM,
        child: Column(
          children: [
            const Text('AI Analysis Not Available'),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            StandardButton(
              label: 'Analyze with AI',
              icon: Icons.auto_awesome,
              type: StandardButtonType.secondary,
              fullWidth: true,
              onPressed: _analyzeWithAI,
            ),
          ],
        ),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final scoreColor = _getScoreColor(score);

    return AppCard(
      padding: AppDesignSystem.paddingM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: scoreColor),
              AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
              Text(
                'AI Match Analysis',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$score%',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: scoreColor,
                      ),
                    ),
                    Text(
                      'Match Score',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: AppDesignSystem.onSurfaceVariant(context)),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppDesignSystem.outlineVariant(context),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: AppDesignSystem.spaceM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_aiAnalysis?['matchingSkills'] != null)
                        Text(
                          '${(_aiAnalysis!['matchingSkills'] as List).length} matching skills',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      if (_aiAnalysis?['missingSkills'] != null)
                        Text(
                          '${(_aiAnalysis!['missingSkills'] as List).length} gaps',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: AppDesignSystem.onSurfaceVariant(context)),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_application!.aiRecommendation != null ||
              _aiAnalysis?['reasoning'] != null) ...[
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            const Divider(),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
            Text(
              _application!.aiRecommendation ??
                  _aiAnalysis?['reasoning'] as String? ??
                  '',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppDesignSystem.primary(context);
    if (score >= 60) return AppDesignSystem.tertiary(context);
    return AppDesignSystem.errorColor(context);
  }

  Widget _buildApplicationDetails() {
    final theme = Theme.of(context);

    return AppCard(
      padding: AppDesignSystem.paddingM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Application Details',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
          _buildDetailRow('Job Title', widget.jobTitle),
          _buildDetailRow(
              'Applied On', timeago.format(_application!.appliedAt)),
          if (_application!.reviewedAt != null)
            _buildDetailRow(
                'Reviewed On', timeago.format(_application!.reviewedAt!)),
          if (_application!.reviewNotes != null)
            _buildDetailRow('Notes', _application!.reviewNotes!),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: AppDesignSystem.spaceM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildActions() {
    // Determine application state
    final isPending = _application!.status == ApplicationStatus.pending;
    final isShortlisted = _application!.status == ApplicationStatus.shortlisted;
    final isHired = _application!.status == ApplicationStatus.hired;
    final hasInterview = _application!.interviewId != null && _application!.interviewId!.isNotEmpty;

    // PENDING status: Can Shortlist, Schedule Interview, or Reject
    if (isPending) {
      return AppCard(
        padding: AppDesignSystem.paddingM,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Next Step',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            StandardButton(
              label: 'Shortlist Candidate',
              icon: Icons.check_circle,
              type: StandardButtonType.primary,
              fullWidth: true,
              onPressed: () => _updateApplicationStatus(ApplicationStatus.shortlisted),
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            StandardButton(
              label: 'Schedule Interview',
              icon: Icons.calendar_today,
              type: StandardButtonType.secondary,
              fullWidth: true,
              onPressed: _scheduleInterview,
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            StandardButton(
              label: 'Reject Application',
              icon: Icons.close,
              type: StandardButtonType.danger,
              fullWidth: true,
              onPressed: () => _showRejectDialog(),
            ),
          ],
        ),
      );
    }

    // SHORTLISTED without interview: Can schedule interview or hire
    if (isShortlisted && !hasInterview) {
      return AppCard(
        padding: AppDesignSystem.paddingM,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shortlisted Candidate',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            StandardButton(
              label: 'Schedule Interview',
              icon: Icons.calendar_today,
              type: StandardButtonType.primary,
              fullWidth: true,
              onPressed: _scheduleInterview,
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            StandardButton(
              label: 'Hire Directly',
              icon: Icons.person_add,
              type: StandardButtonType.secondary,
              fullWidth: true,
              onPressed: _hireApplicant,
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            StandardButton(
              label: 'Reject Application',
              icon: Icons.close,
              type: StandardButtonType.danger,
              fullWidth: true,
              onPressed: () => _showRejectDialog(),
            ),
          ],
        ),
      );
    }

    // SHORTLISTED with interview: Can view interview or cancel
    if (isShortlisted && hasInterview) {
      return AppCard(
        padding: AppDesignSystem.paddingM,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Interview Scheduled',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            StandardButton(
              label: 'View Interview Details',
              icon: Icons.info_outlined,
              type: StandardButtonType.primary,
              fullWidth: true,
              onPressed: () => _viewInterviewDetails(),
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            StandardButton(
              label: 'Reschedule Interview',
              icon: Icons.edit_calendar,
              type: StandardButtonType.secondary,
              fullWidth: true,
              onPressed: _scheduleInterview,
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            StandardButton(
              label: 'Cancel Interview',
              icon: Icons.close,
              type: StandardButtonType.danger,
              fullWidth: true,
              onPressed: () => _showCancelInterviewDialog(),
            ),
          ],
        ),
      );
    }

    // HIRED status
    if (isHired) {
      return AppCard(
        padding: AppDesignSystem.paddingM,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Candidate Hired',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            StandardButton(
              label: 'Mark Job Complete & Rate',
              icon: Icons.star,
              type: StandardButtonType.primary,
              fullWidth: true,
              onPressed: () => _showRateDialog(),
            ),
          ],
        ),
      );
    }

    // For other statuses (rejected, etc.)
    return AppCard(
      padding: AppDesignSystem.paddingM,
      child: Text(
        'Application Status: ${_application!.status}',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  void _viewInterviewDetails() {
    if (_application!.interviewId == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Interview ID: ${_application!.interviewId}')),
    );
  }

  Future<void> _showCancelInterviewDialog() async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Interview'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to cancel this interview?'),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason for cancellation (Required)',
                hintText: 'Explain why you are cancelling...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Interview'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Interview'),
          ),
        ],
      ),
    );

    if (confirmed == true && reasonController.text.trim().isNotEmpty) {
      await _cancelInterview(reasonController.text.trim());
      reasonController.dispose();
    }
  }

  Future<void> _cancelInterview(String reason) async {
    if (_application!.interviewId == null) return;

    try {
      await _dbService.updateInterview(
        interviewId: _application!.interviewId!,
        data: {
          'status': 'Cancelled',
          'cancel_reason': reason,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      await _dbService.updateApplication(
        applicationId: widget.applicationId,
        data: {
          'interviewId': null,
          'interviewDate': null,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      await _notificationService.sendNotification(
        userId: _application!.userId,
        type: 'interview_cancelled',
        title: 'Interview Cancelled',
        body: 'Your interview for "${widget.jobTitle}" has been cancelled.\nReason: $reason',
        data: {
          'interviewId': _application!.interviewId,
          'jobId': widget.jobId,
          'reason': reason,
        },
        sendEmail: true,
      );

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Interview cancelled');
        _loadApplication();
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Failed to cancel interview: $e');
      }
    }
  }

  Future<void> _showRejectDialog() async {
    final reasonController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to reject this application?'),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'Provide feedback to the candidate...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          StandardButton(
            label: 'Cancel',
            type: StandardButtonType.text,
            onPressed: () => Navigator.pop(context, false),
          ),
          StandardButton(
            label: 'Reject',
            type: StandardButtonType.danger,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (result == true) {
      await _updateApplicationStatus(
        ApplicationStatus.rejected,
        notes: reasonController.text.isEmpty ? null : reasonController.text,
      );
    }
  }

  void _showRateDialog() {
    showDialog(
      context: context,
      builder: (context) => RateFreelancerDialog(
        freelancerId: _application!.userId,
        candidateId: _application!.userId,
        freelancerName: _application!.applicantName,
        jobId: widget.jobId,
        jobTitle: widget.jobTitle,
      ),
    );
  }
}
