import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:freelance_app/models/trainer_application_model.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';
import 'package:freelance_app/widgets/common/standard_button.dart';
import 'package:freelance_app/widgets/common/snackbar_helper.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:url_launcher/url_launcher.dart';

/// Admin screen to review and approve/reject trainer applications
class AdminTrainerApprovalScreen extends StatefulWidget {
  const AdminTrainerApprovalScreen({super.key});

  @override
  State<AdminTrainerApprovalScreen> createState() =>
      _AdminTrainerApprovalScreenState();
}

class _AdminTrainerApprovalScreenState
    extends State<AdminTrainerApprovalScreen>
    with SingleTickerProviderStateMixin {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<List<TrainerApplicationModel>> _getApplicationsByStatus(
      String status) {
    return _firestore
        .collection('trainerApplications')
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TrainerApplicationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> _approveApplication(
      TrainerApplicationModel application) async {
    final adminNotes = await _showApprovalDialog(context);
    if (adminNotes == null) return;

    try {
      final batch = _firestore.batch();
      final appRef = _firestore
          .collection('trainerApplications')
          .doc(application.applicationId);
      final userRef = _firestore.collection('users').doc(application.userId);

      // Update application status
      batch.update(appRef, {
        'status': 'approved',
        'approvedAt': Timestamp.now(),
        'approvedByAdminId': _auth.currentUser!.uid,
        'adminNotes': adminNotes,
      });

      // Add trainer role to user
      batch.update(userRef, {
        'roles': FieldValue.arrayUnion(['trainer']),
      });

      await batch.commit();

      // Send notification
      await _firestore.collection('notifications').add({
        'userId': application.userId,
        'type': 'trainer_approved',
        'title': 'Trainer Application Approved',
        'message': 'Your trainer application has been approved!',
        'read': false,
        'createdAt': Timestamp.now(),
      });

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Trainer application approved');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error approving application: $e');
      }
    }
  }

  Future<void> _rejectApplication(TrainerApplicationModel application) async {
    final reason = await _showRejectionDialog(context);
    if (reason == null) return;

    try {
      await _firestore
          .collection('trainerApplications')
          .doc(application.applicationId)
          .update({
        'status': 'rejected',
        'rejectedAt': Timestamp.now(),
        'rejectionReason': reason,
      });

      // Send notification
      await _firestore.collection('notifications').add({
        'userId': application.userId,
        'type': 'trainer_rejected',
        'title': 'Trainer Application Rejected',
        'message': 'Your trainer application was not approved. Reason: $reason',
        'read': false,
        'createdAt': Timestamp.now(),
      });

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Trainer application rejected');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error rejecting application: $e');
      }
    }
  }

  Future<String?> _showApprovalDialog(BuildContext context) {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Trainer'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Add approval notes (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showRejectionDialog(BuildContext context) {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Application'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Reason for rejection',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: controller.text.isEmpty
                ? null
                : () => Navigator.pop(context, controller.text),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: 'Trainer Applications',
        variant: AppBarVariant.primary,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppDesignSystem.spaceL),
            child: SearchBar(
              onChanged: (value) => setState(() => _searchQuery = value),
              leading: const Icon(Icons.search),
              hintText: 'Search by name or email...',
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Pending'),
              Tab(text: 'Approved'),
              Tab(text: 'Rejected'),
            ],
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildApplicationsList('pending'),
                _buildApplicationsList('approved'),
                _buildApplicationsList('rejected'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsList(String status) {
    return StreamBuilder<List<TrainerApplicationModel>>(
      stream: _getApplicationsByStatus(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final applications = snapshot.data ?? [];
        final filtered = applications
            .where((app) =>
                app.userName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                app.userEmail
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()))
            .toList();

        if (filtered.isEmpty) {
          return Center(
            child: Text(
              'No $status applications',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppDesignSystem.spaceL),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            return _buildApplicationCard(filtered[index], status);
          },
        );
      },
    );
  }

  Widget _buildApplicationCard(
      TrainerApplicationModel application, String status) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppDesignSystem.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User avatar
              CircleAvatar(
                radius: 32,
                backgroundImage: application.userImage != null
                    ? NetworkImage(application.userImage!)
                    : null,
                child: application.userImage == null
                    ? Text(application.userName.isNotEmpty
                        ? application.userName[0].toUpperCase()
                        : '?')
                    : null,
              ),
              SizedBox(width: AppDesignSystem.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.userName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: AppDesignSystem.spaceXS),
                    Text(
                      application.userEmail,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: AppDesignSystem.spaceXS),
                    Text(
                      DateFormat('MMM dd, yyyy')
                          .format(application.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppDesignSystem.spaceM),

          // Bio section
          Text(
            'Professional Bio',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: AppDesignSystem.spaceXS),
          Text(
            application.bio,
            style: theme.textTheme.bodySmall,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: AppDesignSystem.spaceM),

          // Certifications section
          Text(
            'Teaching Certifications (${application.certifications.length})',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: AppDesignSystem.spaceXS),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: application.certifications.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppDesignSystem.spaceXS),
                child: Row(
                  children: [
                    Icon(Icons.description_outlined,
                        size: 18, color: colorScheme.primary),
                    SizedBox(width: AppDesignSystem.spaceS),
                    Expanded(
                      child: Text(
                        'Certificate ${index + 1}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final url = application.certifications[index];
                        if (await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(Uri.parse(url),
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      child: const Text('View'),
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: AppDesignSystem.spaceM),

          // Courses section
          Text(
            'Training Areas',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: AppDesignSystem.spaceXS),
          Wrap(
            spacing: AppDesignSystem.spaceS,
            runSpacing: AppDesignSystem.spaceXS,
            children: application.courses
                .map((course) => Chip(
                      label: Text(course, style: theme.textTheme.labelSmall),
                      backgroundColor: colorScheme.secondaryContainer,
                      visualDensity: VisualDensity.compact,
                    ))
                .toList(),
          ),

          // Admin notes (if approved/rejected)
          if (status != 'pending' && application.adminNotes != null) ...[
            SizedBox(height: AppDesignSystem.spaceM),
            Container(
              padding: const EdgeInsets.all(AppDesignSystem.spaceM),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius:
                    BorderRadius.circular(AppDesignSystem.radiusM),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Notes',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: AppDesignSystem.spaceXS),
                  Text(
                    application.adminNotes ?? '',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],

          // Rejection reason (if rejected)
          if (status == 'rejected' && application.rejectionReason != null) ...[
            SizedBox(height: AppDesignSystem.spaceM),
            Container(
              padding: const EdgeInsets.all(AppDesignSystem.spaceM),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(AppDesignSystem.radiusM),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rejection Reason',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: AppDesignSystem.spaceXS),
                  Text(
                    application.rejectionReason ?? '',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: AppDesignSystem.spaceM),

          // Action buttons
          if (status == 'pending') ...[
            Row(
              children: [
                Expanded(
                  child: StandardButton(
                    label: 'Approve',
                    icon: Icons.check,
                    type: StandardButtonType.primary,
                    onPressed: () => _approveApplication(application),
                  ),
                ),
                SizedBox(width: AppDesignSystem.spaceM),
                Expanded(
                  child: StandardButton(
                    label: 'Reject',
                    icon: Icons.close,
                    type: StandardButtonType.secondary,
                    onPressed: () => _rejectApplication(application),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppDesignSystem.spaceM),
          ],

          // Contact row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final email = application.userEmail;
                    if (await canLaunchUrl(Uri(scheme: 'mailto', path: email))) {
                      await launchUrl(Uri(scheme: 'mailto', path: email));
                    }
                  },
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('Email'),
                ),
              ),
              SizedBox(width: AppDesignSystem.spaceS),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final phone = application.userEmail;
                    if (await canLaunchUrl(Uri(scheme: 'tel', path: phone))) {
                      await launchUrl(Uri(scheme: 'tel', path: phone));
                    }
                  },
                  icon: const Icon(Icons.phone_outlined),
                  label: const Text('Call'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
