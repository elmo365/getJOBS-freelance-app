import 'package:flutter/material.dart';
import 'package:freelance_app/utils/app_theme.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';
import 'package:freelance_app/services/notifications/notification_service.dart';
import 'package:freelance_app/widgets/common/snackbar_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freelance_app/services/connectivity_service.dart';
import 'package:freelance_app/services/email_service.dart';
import 'package:freelance_app/services/ai/gemini_ai_service.dart';
import 'package:freelance_app/screens/common/cv_document_viewer_screen.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';
import 'package:freelance_app/widgets/common/standard_button.dart';
import 'package:freelance_app/services/auth/app_user_role.dart';
import 'package:freelance_app/widgets/common/role_guard.dart';
import 'package:freelance_app/screens/admin/widgets/admin_company_card.dart';
import 'package:freelance_app/screens/admin/screens/admin_company_details_screen.dart';
import 'package:freelance_app/screens/admin/widgets/admin_job_card.dart';
import 'package:freelance_app/screens/admin/screens/admin_job_details_screen.dart';

class AdminApprovalScreen extends StatefulWidget {
  const AdminApprovalScreen({super.key});

  @override
  State<AdminApprovalScreen> createState() => _AdminApprovalScreenState();
}

class _AdminApprovalScreenState extends State<AdminApprovalScreen>
    with SingleTickerProviderStateMixin, ConnectivityAware {
  late TabController _tabController;
  final _dbService = FirebaseDatabaseService();
  final _notificationService = NotificationService();
  final _emailService = EmailService();
  final _geminiService = GeminiAIService();

  List<DocumentSnapshot> _pendingCompanies = [];
  List<DocumentSnapshot> _pendingJobs = [];
  bool _isLoadingCompanies = true;
  bool _isLoadingJobs = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPendingCompanies();
    _loadPendingJobs();
  }

  void _showKycDocsDialog(DocumentSnapshot company) {
    final companyData = company.data() as Map<String, dynamic>? ?? {};
    final companyName = companyData['company_name'] as String? ?? 'Company';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('KYC Documents: $companyName'),
        content: SizedBox(
          width: 520,
          child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance
                .collection('company_kyc')
                .doc(company.id)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: AppDesignSystem.paddingL,
                  child: const Center(child: CircularProgressIndicator()),
                );
              }

              final data = snapshot.data?.data() ?? {};
              final status = (data['status'] as String?) ?? 'draft';
              final documents = (data['documents'] is Map<String, dynamic>)
                  ? (data['documents'] as Map<String, dynamic>)
                  : <String, dynamic>{};

              Widget row(String key, String label) {
                String? url;
                final doc = documents[key];
                if (doc is Map) {
                  final u = doc['url'];
                  if (u is String && u.isNotEmpty) url = u;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(child: Text(label)),
                      Text(url != null ? 'Uploaded' : 'Missing'),
                      AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
                      if (url != null)
                        StandardButton(
                          label: 'View',
                          type: StandardButtonType.text,
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              this.context,
                              MaterialPageRoute(
                                builder: (_) => CvDocumentViewerScreen(
                                  title: label,
                                  cvUrl: url!,
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('KYC status: $status'),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                    row('cipa_certificate', 'CIPA Certificate'),
                    row('cipa_extract', 'CIPA Extract'),
                    row('burs_tin', 'BURS TIN Evidence'),
                    row('proof_of_address', 'Proof of Address'),
                    row('authority_letter', 'Authority Letter (optional)'),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          StandardButton(
            label: 'Close',
            type: StandardButtonType.text,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingCompanies() async {
    setState(() => _isLoadingCompanies = true);
    try {
      final users = await _dbService.searchUsers(
        isCompany: true,
        approvalStatus: 'pending',
      );
      setState(() {
        _pendingCompanies = users.docs;
        _isLoadingCompanies = false;
      });
    } catch (e) {
      setState(() => _isLoadingCompanies = false);
      if (mounted) {
        SnackbarHelper.showError(context, 'Error loading companies: $e');
      }
    }
  }

  Future<void> _loadPendingJobs() async {
    setState(() => _isLoadingJobs = true);
    try {
      // Pending jobs should not be filtered by `status == active`.
      // Companies submit jobs with `status == pending`, and admins must be able to review them.
      final jobs = await _dbService
          .getCollection('jobs')
          .where('status', isEqualTo: 'pending')
          .where('isVerified', isEqualTo: false)
          .limit(1000)
          .get();
      setState(() {
        _pendingJobs = jobs.docs;
        _isLoadingJobs = false;
      });
    } catch (e) {
      setState(() => _isLoadingJobs = false);
      if (mounted) {
        SnackbarHelper.showError(context, 'Error loading jobs: $e');
      }
    }
  }

  Future<void> _approveCompany(String companyId, String companyName) async {
    if (!await checkConnectivity(context,
        message:
            'Cannot approve company without internet. Please connect and try again.')) {
      return;
    }

    try {
      // Require KYC submission before approval
      final kycDoc = await FirebaseFirestore.instance
          .collection('company_kyc')
          .doc(companyId)
          .get();
      final kyc = kycDoc.data() ?? {};
      final kycStatus = (kyc['status'] as String?) ?? 'draft';
      if (kycStatus != 'submitted') {
        if (mounted) {
          SnackbarHelper.showError(context,
              'Cannot approve: company has not submitted KYC documents.');
        }
        return;
      }

      // Update company status
      await _dbService.updateUser(
        userId: companyId,
        data: {
          'isApproved': true,
          'approvalStatus': 'approved',
          'approvalDate': DateTime.now().toIso8601String(),
        },
      );

      await FirebaseFirestore.instance
          .collection('company_kyc')
          .doc(companyId)
          .set({
        'status': 'approved',
        'reviewedAt': FieldValue.serverTimestamp(),
        'rejectionReason': FieldValue.delete(),
      }, SetOptions(merge: true));

      // Notify company (email handled server-side)
      await _notificationService.sendNotification(
        userId: companyId,
        type: 'company_approval',
        title: 'Company Approved! ✅',
        body:
            'Congratulations! Your company "$companyName" has been approved. You can now post jobs, use AI candidate suggestions, and access all employer features.',
        data: {'companyId': companyId, 'companyName': companyName},
        sendEmail: true,
      );

      // Audit Log
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await _dbService.logAdminAction(
          adminId: currentUser.uid,
          action: 'approve_company',
          targetId: companyId,
          targetType: 'company',
          metadata: {'companyName': companyName},
        );
      }

      if (mounted) {
        SnackbarHelper.showSuccess(
            context, 'Company approved! Confirmation email sent.');
        _loadPendingCompanies();
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error approving company: $e');
      }
    }
  }

  Future<void> _rejectCompany(
      String companyId, String companyName, String reason) async {
    if (!await checkConnectivity(context,
        message:
            'Cannot reject company without internet. Please connect and try again.')) {
      return;
    }

    try {
      await _dbService.updateUser(
        userId: companyId,
        data: {
          'isApproved': false,
          'approvalStatus': 'rejected',
          'rejectionReason': reason,
          'approvalDate': DateTime.now().toIso8601String(),
        },
      );

      await FirebaseFirestore.instance
          .collection('company_kyc')
          .doc(companyId)
          .set({
        'status': 'rejected',
        'reviewedAt': FieldValue.serverTimestamp(),
        'rejectionReason': reason,
      }, SetOptions(merge: true));

      await _notificationService.sendNotification(
        userId: companyId,
        type: 'company_rejected',
        title: 'Company Verification Rejected',
        body:
            'Your company verification application was rejected. Please review the reason below and resubmit your documents.',
        data: {
          'companyId': companyId,
          'reason': reason,
          'companyName': companyName
        },
        sendEmail: true,
      );

      // Audit Log
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await _dbService.logAdminAction(
          adminId: currentUser.uid,
          action: 'reject_company',
          targetId: companyId,
          targetType: 'company',
          metadata: {
            'companyName': companyName,
            'reason': reason,
          },
        );
      }

      if (mounted) {
        SnackbarHelper.showSuccess(
            context, 'Company rejected. Notification sent.');
        _loadPendingCompanies();
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error rejecting company: $e');
      }
    }
  }

  Future<void> _approveJob(DocumentSnapshot job) async {
    try {
      final jobData = job.data() as Map<String, dynamic>? ?? {};
      final jobTitle = (jobData['title'] as String?) ?? 'Job';
      final employerId = (jobData['userId'] ?? jobData['id'])?.toString();

      await _dbService.updateJob(
        jobId: job.id,
        data: {
          'isApproved': true,
          'approvalStatus': 'approved',
          'approvalDate': DateTime.now().toIso8601String(),
          'status': 'active',
          'isVerified': true,
          'rejectionReason': FieldValue.delete(),
        },
      );

      if (employerId != null) {
        await _notificationService.sendNotification(
          userId: employerId,
          type: 'job_approval',
          title: 'Job Approved! ✅',
          body:
              'Your job posting "$jobTitle" has been approved and is now live. Job seekers can now view and apply for this position.',
          data: {'jobId': job.id, 'jobTitle': jobTitle},
          sendEmail: true,
        );
      }

      // Audit Log
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await _dbService.logAdminAction(
          adminId: currentUser.uid,
          action: 'approve_job',
          targetId: job.id,
          targetType: 'job',
          metadata: {'jobTitle': jobTitle, 'employerId': employerId},
        );
      }

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Job approved successfully!');
        _loadPendingJobs();
      }

      // Trigger AI Matching for Candidates (After Approval)
      _triggerAIMatching(job.id, jobTitle, jobData['description'] ?? '');
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error approving job: $e');
      }
    }
  }

  /// Triggers AI Job Matching to notify candidates
  Future<void> _triggerAIMatching(
      String jobId, String jobTitle, String jobDescription) async {
    debugPrint('🤖 Starting AI Job Matching for Approved Job: $jobId');

    try {
      final potentialCandidates = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'job_seeker')
          .limit(10) // Broaden search slightly for approved jobs
          .get();

      for (var doc in potentialCandidates.docs) {
        final userData = doc.data();
        final userId = doc.id;
        final userEmail = userData['email'] as String?;
        final userName = userData['name'] as String? ?? 'Job Seeker';

        try {
          final matchResult = await _geminiService.matchJobToCandidate(
            jobId: doc.id,
            candidateId: userId,
            candidateProfile: userData,
            jobRequirements: {
              'title': jobTitle,
              'description': jobDescription,
            },
          );

          final score = matchResult['matchScore'] as int? ?? 0;
          final reasoning = matchResult['reasoning'] as String? ??
              'Your skills align with this new role.';

          if (score > 65) {
            // Slightly lower threshold to ensure some notifications go out
            debugPrint('Notification sent to $userName ($score%)');

            await _notificationService.sendNotification(
              userId: userId,
              type: 'job_match',
              title: 'New Job Alert! 🎯',
              body: '$jobTitle matches your profile. Apply now!',
              data: {'jobId': jobId, 'matchScore': score},
              sendEmail: false,
              actionUrl: '/job/$jobId',
            );

            if (userEmail != null) {
              await _emailService.sendJobMatchEmail(
                toEmail: userEmail,
                candidateName: userName,
                jobTitle: jobTitle,
                companyName: 'Approved Employer', // Fetch real name if possible
                matchReason: reasoning,
                jobLink: 'https://botsjobsconnect.com/job/$jobId',
              );
            }
          }
        } catch (e) {
          debugPrint('AI matching failed for user $userId: $e');
          // Continue to next candidate - AI failed for this one
        }
      }
    } catch (e) {
      debugPrint('Error in AI matching batch: $e');
      // Background task - log and continue
    }
  }

  Future<void> _rejectJob(DocumentSnapshot job, String reason) async {
    try {
      final jobData = job.data() as Map<String, dynamic>? ?? {};
      final jobTitle = (jobData['title'] as String?) ?? 'Job';
      final employerId = (jobData['userId'] ?? jobData['id'])?.toString();

      await _dbService.updateJob(
        jobId: job.id,
        data: {
          'isApproved': false,
          'approvalStatus': 'rejected',
          'rejectionReason': reason,
          'approvalDate': DateTime.now().toIso8601String(),
          'status': 'rejected',
          'isVerified': false,
        },
      );

      if (employerId != null) {
        await _notificationService.sendNotification(
          userId: employerId,
          type: 'job_rejected',
          title: 'Job Rejected',
          body:
              'Your job posting "$jobTitle" was rejected. Please review the reason below and edit your job posting to resubmit.',
          data: {'jobId': job.id, 'jobTitle': jobTitle, 'reason': reason},
          sendEmail: true,
        );
      }

      // Audit Log
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await _dbService.logAdminAction(
          adminId: currentUser.uid,
          action: 'reject_job',
          targetId: job.id,
          targetType: 'job',
          metadata: {
            'jobTitle': jobTitle,
            'employerId': employerId,
            'reason': reason,
          },
        );
      }

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Job rejected');
        _loadPendingJobs();
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error rejecting job: $e');
      }
    }
  }

  void _showRejectDialog(String companyId, String companyName) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject $companyName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide a reason for rejection:'),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g., Invalid registration documents',
                border: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusS,
                ),
              ),
            ),
          ],
        ),
        actions: [
          StandardButton(
            label: 'Cancel',
            type: StandardButtonType.text,
            onPressed: () => Navigator.pop(context),
          ),
          StandardButton(
            label: 'Reject',
            type: StandardButtonType.danger,
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                SnackbarHelper.showError(context, 'Please provide a reason');
                return;
              }
              Navigator.pop(context);
              _rejectCompany(companyId, companyName, reason);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return RoleGuard(
      allow: const {AppUserRole.admin},
      title: 'Admin only',
      message:
          'Company and job approvals are only available to administrators.',
      child: HintsWrapper(
        screenId: 'admin_approval',
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppAppBar(
            title: 'Admin Approvals',
            variant: AppBarVariant.primary, // Blue background with white text
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.business),
                      AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
                      const Text('Companies'),
                      if (_pendingCompanies.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.error,
                            borderRadius: AppDesignSystem.borderRadiusM,
                          ),
                          child: Text(
                            '${_pendingCompanies.length}',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onError,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.work),
                      AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
                      const Text('Jobs'),
                      if (_pendingJobs.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.error,
                            borderRadius: AppDesignSystem.borderRadiusM,
                          ),
                          child: Text(
                            '${_pendingJobs.length}',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onError,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              indicatorColor: colorScheme.primary,
              labelColor: colorScheme.primary,
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildCompaniesTab(),
              _buildJobsTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompaniesTab() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_isLoadingCompanies) {
      return Center(
          child: CircularProgressIndicator(color: colorScheme.primary));
    }

    if (_pendingCompanies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: colorScheme.tertiary),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            Text(
              'No pending companies',
              style:
                  textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
            Text(
              'All company registrations are processed',
              style: textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPendingCompanies,
      child: ListView.builder(
        padding: EdgeInsets.all(AppTheme.spacingM),
        itemCount: _pendingCompanies.length,
        itemBuilder: (context, index) {
          final company = _pendingCompanies[index];
          final data = company.data() as Map<String, dynamic>? ?? {};
          final companyName = data['company_name'] ?? 'Company';

          return AdminCompanyCard(
            company: data,
            docId: company.id,
            status: 'pending',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminCompanyDetailsScreen(
                    company: data,
                    docId: company.id,
                    status: 'pending',
                    onApprove: () async {
                      Navigator.pop(context);
                      await _approveCompany(company.id, companyName);
                    },
                    onReject: () async {
                      Navigator.pop(context);
                      _showRejectDialog(company.id, companyName);
                    },
                    onRevoke: () {}, // Not applicable for pending
                    onReapprove: () {}, // Not applicable for pending
                    onViewKyc: () => _showKycDocsDialog(company),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildJobsTab() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_isLoadingJobs) {
      return Center(
          child: CircularProgressIndicator(color: colorScheme.primary));
    }

    if (_pendingJobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: colorScheme.tertiary),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            Text(
              'No pending jobs',
              style:
                  textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
            Text(
              'All job posts are reviewed',
              style: textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPendingJobs,
      child: ListView.builder(
        padding: EdgeInsets.all(AppTheme.spacingM),
        itemCount: _pendingJobs.length,
        itemBuilder: (context, index) {
          final job = _pendingJobs[index];
          final data = job.data() as Map<String, dynamic>? ?? {};

          return AdminJobCard(
            job: data,
            status: 'pending',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminJobDetailsScreen(
                    job: data,
                    onApprove: () async {
                      Navigator.pop(context);
                      await _approveJob(job);
                    },
                    onReject: (reason) async {
                      Navigator.pop(context);
                      await _rejectJob(job, reason);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
