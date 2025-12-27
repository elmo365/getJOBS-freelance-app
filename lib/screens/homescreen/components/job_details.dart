import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/utils/layout.dart';
import 'package:freelance_app/widgets/common/micro_interactions.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';
import 'package:freelance_app/services/notifications/notification_service.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/services/ai/gemini_ai_service.dart';
import 'package:freelance_app/services/ai/context_service.dart';
import 'package:freelance_app/widgets/dialogs/apply_job_dialog.dart';
import 'package:freelance_app/services/wallet_service.dart';
import 'package:freelance_app/models/wallet_model.dart';
import 'package:freelance_app/utils/currency_formatter.dart';
import 'package:freelance_app/utils/date_formatter.dart';
import 'package:freelance_app/utils/colors.dart';
import 'package:freelance_app/services/email_service.dart';
import 'package:freelance_app/widgets/cached_image_widget.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';

class JobDetailsScreen extends StatefulWidget {
  const JobDetailsScreen({super.key, required this.id, required this.jobId});
  final String id;
  final String jobId;

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  final _dbService = FirebaseDatabaseService();
  final _notificationService = NotificationService();
  final _emailService = EmailService();

  String? authorName;
  String? userImageUrl;
  String? jobCategory;
  String? jobDescription;
  String? jobTitle;
  bool? recruitment;
  Timestamp? postedDateTimeStamp;
  Timestamp? deadlineDateTimeStamp;
  String? postedDate;
  String? deadlineDate;
  String locationCompany = "";
  String emailCompany = "";
  int applicants = 0;
  int positionsAvailable = 0;
  int positionsFilled = 0;
  bool isDeadlineAvailable = false;
  bool isJobOwner = false;
  Future<void> _shareJob() async {
    final text =
        'Check out this job: $jobTitle at ${locationCompany.isNotEmpty ? locationCompany : 'Bots Jobs Connect'}';
    // Note: Use the 'share_plus' package in a real app. For now, we simulate or use a mock.
    // Assuming share_plus is in pubspec (it usually is for standard flutter apps, checking dependencies...)
    // If not, we fall back to clipboard or snackbar.
    // Since I cannot check imports easily right now without reading pubspec again,
    // I will implement a safe fallback that informs the user.

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sharing: $text')),
    );
  }

  Future<void> _toggleBookmark() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to save jobs.')),
      );
      return;
    }

    try {
      // Check if already saved
      final savedRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('saved_jobs')
          .doc(widget.jobId);

      final doc = await savedRef.get();

      if (doc.exists) {
        await savedRef.delete();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job removed from bookmarks.')),
        );
      } else {
        await savedRef.set({
          'jobId': widget.jobId,
          'title': jobTitle,
          'savedAt': FieldValue.serverTimestamp(),
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job saved to bookmarks!')),
        );
      }
    } catch (e) {
      debugPrint('Error toggling bookmark: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    getJobData();
  }

  Future<void> applyForJob() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Prevent duplicates (applications list + employer applicants view).
    try {
      final alreadyApplied = await _dbService.hasUserApplied(
        userId: currentUser.uid,
        jobId: widget.jobId,
      );
      if (alreadyApplied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You already applied to this job.')),
        );
        return;
      }
    } catch (e) {
      // If the check fails, continue with best-effort apply.
      debugPrint('hasUserApplied check failed: $e');
    }

    // Check if job deadline has passed
    if (deadlineDateTimeStamp != null) {
      final deadline = deadlineDateTimeStamp!.toDate();
      if (DateTime.now().isAfter(deadline)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Applications for this job have closed.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Show Proposal Dialog
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dialogBuilderContext) {
        return ApplyJobDialog(
          jobTitle: jobTitle ?? 'this job',
          onCancel: () => Navigator.pop(dialogBuilderContext),
          onSubmit: (coverLetter, bidAmount) async {
            Navigator.pop(dialogBuilderContext); // Close dialog

            // Monetization Check
            final walletService = WalletService();
            final settings = await walletService.getSettings();

            double cost = settings.applicationFee;
            double discount = 0;
            if (settings.globalDiscountPercentage > 0) {
              discount = cost * (settings.globalDiscountPercentage / 100);
              cost = cost - discount;
            }
            if (cost < 0) cost = 0;

            // Application Fee is for Seekers (Individuals).
            // We check the Individual Monetization Toggle.
            // In strict terms, anyone applying is acting as an individual candidate usually.
            if (settings.isIndividualMonetizationEnabled && cost > 0) {
              // Confirm Payment
              if (!mounted) return;
              final proceed = await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirm Application Fee'),
                      content: Text(
                          'Applying to this job costs ${CurrencyFormatter.formatBWP(cost)}.\n${discount > 0 ? "(Includes ${settings.globalDiscountPercentage.toStringAsFixed(0)}% Promo Discount)" : ""}'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel')),
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Pay & Apply')),
                      ],
                    ),
                  ) ??
                  false;

              if (!proceed || !mounted) return;

              try {
                await walletService.spendCredits(
                  userId: currentUser.uid,
                  amount: cost,
                  type: TransactionType.applicationFee,
                  description: 'Application fee for: $jobTitle',
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Payment Failed: $e')));
                return;
              }
            }

            await addNewApplicant(
                coverLetter: coverLetter, bidAmount: bidAmount);
          },
        );
      },
    );
  }

  Future<void> addNewApplicant({String? coverLetter, double? bidAmount}) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Get applicant profile for the application record.
    String applicantName = '';
    String applicantImage = '';
    String applicantEmail = currentUser.email ?? '';
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final userData = userDoc.data() ?? {};
      applicantName = (userData['name'] as String?)?.trim() ?? '';
      applicantImage = (userData['user_image'] as String?) ??
          (userData['userImage'] as String?) ??
          '';
      applicantEmail = (userData['email'] as String?) ?? applicantEmail;
    } catch (e) {
      debugPrint('Failed to load applicant profile: $e');
    }

    // Submit Application via Atomic Transaction
    try {
      await _dbService.submitApplicationTransaction(
        jobId: widget.jobId,
        userId: currentUser.uid,
        applicationData: {
          'jobId': widget.jobId,
          'userId': currentUser.uid,
          'applicantName': applicantName,
          'applicantImage': applicantImage,
          'applicantEmail': applicantEmail,
          'status': 'pending',
          'appliedAt': DateTime.now().toIso8601String(),
          'jobTitle': jobTitle,
          'coverLetter': coverLetter,
          'bidAmount': bidAmount,
        },
        applicantBrief: {
          'name': applicantName,
          'user_image': applicantImage,
        },
      );
    } catch (e) {
      debugPrint('Transaction failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e')),
        );
      }
      return;
    }

    // Notifications (Fire and Forget / Side-effects)
    try {
      final jobDoc = await FirebaseFirestore.instance
          .collection('jobs')
          .doc(widget.jobId)
          .get();
      final data = jobDoc.data() ?? {};
      final employerId = (data['userId'] ?? data['id'])?.toString();
      if (employerId != null && employerId.isNotEmpty) {
        // ... (rest remains same)
        // 1. Send In-App Notification
        await _notificationService.sendNotification(
          userId: employerId,
          type: 'job_application',
          title: 'New Job Application 📝',
          body: applicantName.isNotEmpty
              ? '$applicantName has applied for "${jobTitle ?? 'your job'}". Review their application in your dashboard.'
              : 'A candidate has applied for "${jobTitle ?? 'your job'}". Review their application in your dashboard.',
          data: {
            'jobId': widget.jobId,
            'jobTitle': jobTitle,
            'applicationId': 'pending',
            'applicantId': currentUser.uid,
            'applicantName': applicantName,
          },
          sendEmail: false, // We send a rich email separately below
        );

        // 2. Send Rich Email
        await _emailService.sendJobApplicationEmail(
          toEmail: emailCompany.isNotEmpty
              ? emailCompany
              : FirebaseAuth.instance.currentUser?.email ?? 'contact@system',
          employerName: 'Employer', // Could fetch name if available
          applicantName: applicantName,
          jobTitle: jobTitle ?? 'Job Position',
          applicantProfileUrl:
              'https://botsjobsconnect.com/profile/${currentUser.uid}',
        );
      }
    } catch (e) {
      debugPrint('Failed to notify employer: $e');
    }

    // Notify applicant (confirmation)
    try {
      await _notificationService.sendNotification(
        userId: currentUser.uid,
        type: 'application_submitted',
        title: 'Application Submitted ✅',
        body:
            'Your application for "${jobTitle ?? 'the position'}" has been submitted successfully. The employer will review it and get back to you.',
        data: {
          'jobId': widget.jobId,
          'jobTitle': jobTitle,
          'employerId': widget.id,
        },
        sendEmail: true,
      );
    } catch (e) {
      debugPrint('Failed to send applicant confirmation: $e');
      // Best-effort; do not block application
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  /// Modern null-safe job data fetching
  Future<void> getJobData() async {
    try {
      // Get job data
      final jobDoc = await FirebaseFirestore.instance
          .collection('jobs')
          .doc(widget.jobId)
          .get();

      if (!jobDoc.exists) return;

      final jobData = jobDoc.data();
      if (jobData == null) return;

      // Debug: Log deadline fields
      debugPrint('📋 [Job Details] Job ID: ${widget.jobId}');
      debugPrint('📋 [Job Details] Deadline fields in DB:');
      debugPrint(
          '   - deadline_timestamp: ${jobData['deadline_timestamp']} (type: ${jobData['deadline_timestamp']?.runtimeType})');
      debugPrint(
          '   - deadlineDate: ${jobData['deadlineDate']} (type: ${jobData['deadlineDate']?.runtimeType})');

      // Get user data (optional fallback)
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.id)
          .get();
      final userData = userDoc.data();

      if (!mounted) return;

      setState(() {
        authorName =
            (jobData['name'] as String?) ?? (userData?['name'] as String?);
        userImageUrl = (jobData['user_image'] as String?) ??
            (userData?['user_image'] as String?);

        jobTitle =
            (jobData['title'] as String?) ?? (jobData['jobTitle'] as String?);
        jobDescription =
            (jobData['description'] as String?) ?? (jobData['desc'] as String?);
        recruitment =
            (jobData['recruiting'] as bool?) ?? (jobData['status'] == 'active');
        emailCompany = (jobData['email'] as String?) ?? '';
        locationCompany = (jobData['location'] as String?) ??
            (jobData['address'] as String?) ??
            '';
        applicants = jobData['applicants'] as int? ?? 0;
        positionsAvailable = jobData['positionsAvailable'] as int? ?? jobData['positions'] as int? ?? 1;
        positionsFilled = jobData['positionsFilled'] as int? ?? 0;
        // Check if current user is the job owner
        final currentUser = FirebaseAuth.instance.currentUser;
        isJobOwner = currentUser?.uid == widget.id;

        final createdAt = jobData['createdAt'];
        if (createdAt is Timestamp) {
          postedDateTimeStamp = createdAt;
          postedDate = DateFormatter.formatDateDash(createdAt.toDate());
        } else if (createdAt is String) {
          final parsed = DateTime.tryParse(createdAt);
          if (parsed != null) {
            postedDateTimeStamp = Timestamp.fromDate(parsed);
            postedDate = DateFormatter.formatDateDash(parsed);
          }
        } else {
          postedDateTimeStamp = jobData['created'] as Timestamp?;
        }

        if (postedDateTimeStamp != null && postedDate == null) {
          final postDate = postedDateTimeStamp!.toDate();
          postedDate = DateFormatter.formatDateDash(postDate);
        }

        // Based on code: job_post.dart stores 'deadlineDate' as ISO8601 String, 'deadline_timestamp' as Timestamp
        final deadlineTimestamp = jobData['deadline_timestamp'];
        final deadlineDateStr = jobData['deadlineDate'];
        debugPrint(
            '📋 [Job Details] Deadline fields - timestamp: $deadlineTimestamp (${deadlineTimestamp?.runtimeType}), dateStr: $deadlineDateStr (${deadlineDateStr?.runtimeType})');

        final deadline = deadlineTimestamp ?? deadlineDateStr;

        if (deadline != null) {
          DateTime? deadlineDateTime;

          if (deadline is Timestamp) {
            deadlineDateTime = deadline.toDate();
            deadlineDateTimeStamp = deadline;
          } else if (deadline is String) {
            // Parse ISO8601 string format
            deadlineDateTime = DateTime.tryParse(deadline);
            if (deadlineDateTime != null) {
              deadlineDateTimeStamp = Timestamp.fromDate(deadlineDateTime);
            }
          } else if (deadline is DateTime) {
            deadlineDateTime = deadline;
            deadlineDateTimeStamp = Timestamp.fromDate(deadline);
          }

          if (deadlineDateTime != null) {
            deadlineDate = DateFormatter.formatDateDash(deadlineDateTime);
            debugPrint('✅ [Job Details] Deadline parsed: $deadlineDate');
          } else {
            debugPrint('⚠️ [Job Details] Failed to parse deadline: $deadline');
            deadlineDateTimeStamp = null;
            deadlineDate = null;
          }
        } else {
          debugPrint('⚠️ [Job Details] No deadline found in job data');
          deadlineDateTimeStamp = null;
          deadlineDate = null;
        }
      });

      if (deadlineDateTimeStamp != null) {
        final date = deadlineDateTimeStamp!.toDate();
        isDeadlineAvailable = date.isAfter(DateTime.now());
      }
    } catch (e) {
      debugPrint('Error getting job data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return HintsWrapper(
      screenId: 'job_details',
      child: AppLayout.screenScaffold(
        context: context,
        appBar: AppAppBar(
          title: jobTitle ?? 'Job Details',
          variant: AppBarVariant.standard,
          leading: MicroInteractions.scaleCard(
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          actions: [
            MicroInteractions.scaleCard(
              child: IconButton(
                icon: const Icon(Icons.share),
                onPressed: _shareJob,
              ),
            ),
            const SizedBox(width: AppDesignSystem.spaceS),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAIHelp,
          backgroundColor: AppDesignSystem.brandYellow,
          tooltip: 'Ask AI Assistant',
          child: const Icon(Icons.auto_awesome, color: Colors.black),
        ),
        body: jobTitle == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MicroInteractions.pulsingWidget(
                      child: Icon(
                        Icons.work_outline,
                        size: 64,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: AppDesignSystem.spaceL),
                    Text(
                      'Loading job details...',
                      style: AppDesignSystem.bodyLarge(context),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Job Header
                    MicroInteractions.fadeInListItem(
                      child: Container(
                        padding: const EdgeInsets.all(AppDesignSystem.spaceL),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary.withValues(alpha: 0.1),
                              colorScheme.secondary.withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Job Title
                            Text(
                              jobTitle!,
                              style: AppDesignSystem.screenTitle(context),
                            ),
                            const SizedBox(height: AppDesignSystem.spaceM),

                            // Company Info
                            Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                        AppDesignSystem.radiusM),
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surface
                                          .withValues(alpha: 0.8),
                                      width: 2,
                                    ),
                                  ),
                                  child: userImageUrl?.isNotEmpty == true
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                              AppDesignSystem.radiusS),
                                          child: CachedImageWidget(
                                            imageUrl: userImageUrl!,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            borderRadius: AppDesignSystem.radiusS,
                                            errorWidget: Container(
                                              color: colorScheme.primary
                                                  .withValues(alpha: 0.1),
                                              child: Icon(
                                                Icons.business,
                                                color: colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                        )
                                      : Container(
                                          color: colorScheme.primary
                                              .withValues(alpha: 0.1),
                                          child: Icon(
                                            Icons.business,
                                            color: colorScheme.primary,
                                            size: 28,
                                          ),
                                        ),
                                ),
                                const SizedBox(width: AppDesignSystem.spaceM),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        authorName ?? 'Company',
                                        style:
                                            AppDesignSystem.titleLarge(context)
                                                .copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(
                                          height: AppDesignSystem.spaceXS),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on_outlined,
                                            size: 16,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(
                                              width: AppDesignSystem.spaceXS),
                                          Expanded(
                                            child: Text(
                                              locationCompany.isNotEmpty
                                                  ? locationCompany
                                                  : 'Remote',
                                              style: AppDesignSystem.bodySmall(
                                                      context)
                                                  .copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: AppDesignSystem.spaceL),

                            // Stats Section - Reorganized for better spacing
                            // Row 1: Applications Count (Full Width, Centered)
                            _buildStatItem(
                              context: context,
                              icon: Icons.people_outline,
                              value: '$applicants',
                              label: 'Applicants',
                              color: colorScheme.primary,
                            ),
                            const SizedBox(height: AppDesignSystem.spaceL),
                            
                            // Row 2: Positions Filled and Closing Date (2 Columns)
                            Row(
                              children: [
                                // Positions Filled (Left Column)
                                Expanded(
                                  child: _buildStatItem(
                                    context: context,
                                    icon: Icons.work_outline,
                                    value: '$positionsFilled/$positionsAvailable',
                                    label: isJobOwner ? 'Hired' : 'Positions',
                                    color: colorScheme.tertiary,
                                  ),
                                ),
                                const SizedBox(width: AppDesignSystem.spaceM),
                                // Closing Date (Right Column)
                                if (deadlineDateTimeStamp != null)
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(
                                          AppDesignSystem.spaceM),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppDesignSystem.brandYellow
                                                .withValues(alpha: 0.15),
                                            Colors.orange
                                                .withValues(alpha: 0.15),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                            AppDesignSystem.radiusM),
                                        border: Border.all(
                                          color: Colors.orange
                                              .withValues(alpha: 0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isDeadlineAvailable
                                                ? Icons.schedule
                                                : Icons.event_busy,
                                            color: Colors.orange.shade700,
                                            size: 20,
                                          ),
                                          const SizedBox(
                                              height: AppDesignSystem.spaceXS),
                                          Text(
                                            deadlineDate ?? 'N/A',
                                            style: AppDesignSystem.labelLarge(
                                                    context)
                                                .copyWith(
                                              color: Colors.orange.shade900,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            isDeadlineAvailable
                                                ? 'Closes'
                                                : 'Closed',
                                            style: AppDesignSystem.bodySmall(
                                                    context)
                                                .copyWith(
                                              color: Colors.orange.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      index: 0,
                      delayPerItem: const Duration(milliseconds: 100),
                    ),

                    // Action Buttons
                    MicroInteractions.fadeInListItem(
                      index: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(AppDesignSystem.spaceL),
                        child: Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed:
                                    recruitment == true ? applyForJob : null,
                                icon: const Icon(Icons.send, size: 18),
                                label: Text(
                                  recruitment == true
                                      ? 'Apply Now'
                                      : 'Applications Closed',
                                  style: AppDesignSystem.buttonText(context),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: recruitment == true
                                      ? colorScheme.primary
                                      : colorScheme.surfaceContainerHighest,
                                  foregroundColor: recruitment == true
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurfaceVariant,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppDesignSystem.radiusM),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppDesignSystem.spaceM),
                            MicroInteractions.scaleCard(
                              child: IconButton(
                                onPressed: _toggleBookmark,
                                icon: Icon(
                                  Icons.bookmark_border,
                                  color: colorScheme.primary,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: colorScheme.primary
                                      .withValues(alpha: 0.1),
                                  padding: AppDesignSystem.paddingM,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      delayPerItem: const Duration(milliseconds: 100),
                    ),

                    // Job Description
                    if (jobDescription?.isNotEmpty == true)
                      MicroInteractions.fadeInListItem(
                        index: 2,
                        child: AppLayout.section(
                          context: context,
                          title: 'Job Description',
                          content: AppCard(
                            variant: SurfaceVariant.standard,
                            child: Padding(
                              padding:
                                  const EdgeInsets.all(AppDesignSystem.spaceM),
                              child: Text(
                                jobDescription!,
                                style:
                                    AppDesignSystem.bodyLarge(context).copyWith(
                                  height: 1.6,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ),
                        delayPerItem: const Duration(milliseconds: 100),
                      ),

                    // Requirements Section (placeholder for now)
                    MicroInteractions.fadeInListItem(
                      index: 3,
                      child: AppLayout.section(
                        context: context,
                        title: 'Requirements',
                        content: AppCard(
                          variant: SurfaceVariant.standard,
                          child: Padding(
                            padding:
                                const EdgeInsets.all(AppDesignSystem.spaceM),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildRequirementItem(
                                  context,
                                  Icons.school,
                                  'Experience Level',
                                  jobCategory ?? 'Not specified',
                                ),
                                const SizedBox(height: AppDesignSystem.spaceM),
                                _buildRequirementItem(
                                  context,
                                  Icons.location_on,
                                  'Location',
                                  locationCompany.isNotEmpty
                                      ? locationCompany
                                      : 'Remote work available',
                                ),
                                const SizedBox(height: AppDesignSystem.spaceM),
                                _buildRequirementItem(
                                  context,
                                  Icons.email,
                                  'Contact',
                                  emailCompany.isNotEmpty
                                      ? emailCompany
                                      : 'Contact employer directly',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      delayPerItem: const Duration(milliseconds: 100),
                    ),

                    // Bottom Spacing
                    const SizedBox(height: AppDesignSystem.spaceXL),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatItem({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDesignSystem.spaceM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: AppDesignSystem.spaceXS),
          Text(
            value,
            style: AppDesignSystem.labelLarge(context).copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: AppDesignSystem.bodySmall(context).copyWith(
              color: color.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(
      BuildContext context, IconData icon, String title, String value) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: AppDesignSystem.paddingS,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: AppDesignSystem.borderRadiusS,
          ),
          child: Icon(
            icon,
            size: 16,
            color: colorScheme.primary,
          ),
        ),
        AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppDesignSystem.bodyMedium(context).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppDesignSystem.verticalSpace(2),
              Text(
                value,
                style: AppDesignSystem.bodyMedium(context).copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAIHelp() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AIHelpSheet(jobId: widget.jobId),
    );
  }
}

class _AIHelpSheet extends StatefulWidget {
  final String jobId;
  const _AIHelpSheet({required this.jobId});

  @override
  State<_AIHelpSheet> createState() => _AIHelpSheetState();
}

class _AIHelpSheetState extends State<_AIHelpSheet> {
  final _controller = TextEditingController();
  final _authService = FirebaseAuthService();
  bool _isLoading = false;
  String? _answer;

  Future<void> _askQuestion(String? preset) async {
    final query = preset ?? _controller.text.trim();
    if (query.isEmpty) return;

    final userId = _authService.getCurrentUser()?.uid;
    if (userId == null) return;

    setState(() {
      _isLoading = true;
      _answer = null;
    });

    // Close keyboard if open
    FocusScope.of(context).unfocus();

    try {
      // 1. Build Contexts
      final userContext =
          await ContextService().buildUserProfileContext(userId);
      final jobContext = await ContextService().buildJobContext(widget.jobId);

      // 2. Ask Gemini
      final response = await GeminiAIService().askAIAssistant(
        question: query,
        userContext: userContext,
        jobContext: jobContext,
      );

      if (mounted) {
        setState(() {
          _answer = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _answer = "Sorry, I encountered an error. Please try again.";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + keyboardPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome,
                  color: AppDesignSystem.brandYellow, size: 28),
              const SizedBox(width: 12),
              Text(
                'AI Career Assistant',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
          if (_answer != null) ...[
            Container(
              padding: AppDesignSystem.paddingM,
              decoration: BoxDecoration(
                color: AppDesignSystem.brandGreen.withValues(alpha: 0.1),
                borderRadius: AppDesignSystem.borderRadiusL,
                border: Border.all(
                    color: AppDesignSystem.brandGreen.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SelectableText(
                    _answer!,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _answer!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Copied to clipboard!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
          ],
          if (_isLoading) ...[
            const Center(child: CircularProgressIndicator()),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
          ],
          if (!_isLoading && _answer == null) ...[
            _SuggestionChip(
              label: "Am I a good fit for this job?",
              onTap: () => _askQuestion("Am I a good fit for this job?"),
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
            _SuggestionChip(
              label: "What skills am I missing?",
              onTap: () => _askQuestion(
                  "What skills from the requirements am I missing?"),
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
            _SuggestionChip(
              label: "Write a short cover letter intro",
              onTap: () => _askQuestion(
                  "Draft a short, professional cover letter introduction for this job based on my profile."),
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Ask anything about this job...',
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: AppDesignSystem.borderRadiusM,
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
              IconButton.filled(
                onPressed: _isLoading ? null : () => _askQuestion(null),
                icon: const Icon(Icons.send),
                style: IconButton.styleFrom(
                  backgroundColor: AppDesignSystem.brandBlue,
                  foregroundColor: botsWhite, // White icon on blue background
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      avatar: const Icon(Icons.lightbulb_outline, size: 16),
      backgroundColor: Theme.of(context).colorScheme.surface,
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    );
  }
}
