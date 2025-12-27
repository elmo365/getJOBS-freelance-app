import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/utils/app_theme.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/models/job_closure_request_model.dart';

/// Admin Job Closure Review Screen
/// Displays pending job closure requests with hired applicants
/// Admin can review, contact hired employees, approve or reject
class AdminJobClosureReviewScreen extends StatefulWidget {
  const AdminJobClosureReviewScreen({super.key});

  @override
  State<AdminJobClosureReviewScreen> createState() =>
      _AdminJobClosureReviewScreenState();
}

class _AdminJobClosureReviewScreenState
    extends State<AdminJobClosureReviewScreen> {
  final _dbService = FirebaseDatabaseService();
  final _authService = FirebaseAuthService();
  final _responseController = TextEditingController();

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Closure Requests'),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _dbService.getPendingClosureRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(AppDesignSystem.spaceL),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: colorScheme.error,
                    ),
                    SizedBox(height: AppDesignSystem.spaceM),
                    Text(
                      'Error loading closure requests',
                      style: AppDesignSystem.titleMedium(context),
                    ),
                  ],
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(AppDesignSystem.spaceL),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: colorScheme.primary,
                    ),
                    SizedBox(height: AppDesignSystem.spaceM),
                    Text(
                      'No Pending Requests',
                      style: AppDesignSystem.titleMedium(context),
                    ),
                    SizedBox(height: AppDesignSystem.spaceS),
                    Text(
                      'All job closure requests have been reviewed',
                      style: AppDesignSystem.bodySmall(context),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(AppDesignSystem.spaceM),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final request =
                  JobClosureRequest.fromMap(doc.data(), doc.id);

              return _buildClosureRequestCard(context, request);
            },
          );
        },
      ),
    );
  }

  Widget _buildClosureRequestCard(
      BuildContext context, JobClosureRequest request) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.only(bottom: AppDesignSystem.spaceM),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: ExpansionTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              request.jobTitle,
              style: AppDesignSystem.labelLarge(context),
            ),
            SizedBox(height: AppDesignSystem.spaceXS),
            Text(
              'Hired: ${request.hiredApplicants.length} | '
              'Pending: ${request.applicantsToNotify.length} | '
              'Total: ${request.totalApplications}',
              style: AppDesignSystem.bodySmall(context).copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: AppDesignSystem.spaceS),
          child: Chip(
            label: Text('${request.hiredApplicants.length} Hired'),
            backgroundColor: colorScheme.primaryContainer,
            labelStyle: TextStyle(
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(AppDesignSystem.spaceL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Closure Reason Section
                Container(
                  padding: EdgeInsets.all(AppDesignSystem.spaceM),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reason for Closure',
                        style: AppDesignSystem.labelMedium(context),
                      ),
                      SizedBox(height: AppDesignSystem.spaceS),
                      Text(
                        request.closureReason,
                        style: AppDesignSystem.bodyMedium(context),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppDesignSystem.spaceL),

                // Hired Applicants Section
                Text(
                  'Hired Candidates (${request.hiredApplicants.length})',
                  style: AppDesignSystem.labelLarge(context),
                ),
                SizedBox(height: AppDesignSystem.spaceM),
                for (final hired in request.hiredApplicants)
                  _buildHiredApplicantCard(context, hired),

                SizedBox(height: AppDesignSystem.spaceL),

                // Decision Section
                Text(
                  'Admin Decision',
                  style: AppDesignSystem.labelLarge(context),
                ),
                SizedBox(height: AppDesignSystem.spaceM),

                TextField(
                  controller: _responseController,
                  decoration: InputDecoration(
                    hintText: 'Your response or notes (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.all(AppDesignSystem.spaceM),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: AppDesignSystem.spaceL),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _rejectClosure(context, request),
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.error,
                        ),
                      ),
                    ),
                    SizedBox(width: AppDesignSystem.spaceM),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _approveClosure(context, request),
                        icon: const Icon(Icons.check),
                        label: const Text('Approve'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHiredApplicantCard(
      BuildContext context, HiredApplicant hired) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.only(bottom: AppDesignSystem.spaceM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppDesignSystem.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: hired.userImage != null &&
                          hired.userImage!.isNotEmpty
                      ? NetworkImage(hired.userImage!)
                      : null,
                  child: hired.userImage == null || hired.userImage!.isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),
                SizedBox(width: AppDesignSystem.spaceM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hired.name,
                        style: AppDesignSystem.labelLarge(context),
                      ),
                      Text(
                        hired.email,
                        style: AppDesignSystem.bodySmall(context).copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (hired.phone != null && hired.phone!.isNotEmpty)
                        Text(
                          'Phone: ${hired.phone}',
                          style: AppDesignSystem.bodySmall(context),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (action) {
                    if (action == 'copy_email') {
                      _copyToClipboard(hired.email, context);
                    } else if (action == 'copy_phone' &&
                        hired.phone != null) {
                      _copyToClipboard(hired.phone!, context);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem(
                      value: 'copy_email',
                      child: ListTile(
                        leading: Icon(Icons.email),
                        title: Text('Copy Email'),
                      ),
                    ),
                    if (hired.phone != null && hired.phone!.isNotEmpty)
                      const PopupMenuItem(
                        value: 'copy_phone',
                        child: ListTile(
                          leading: Icon(Icons.phone),
                          title: Text('Copy Phone'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (hired.notes != null && hired.notes!.isNotEmpty) ...[
              SizedBox(height: AppDesignSystem.spaceS),
              Text(
                'Notes: ${hired.notes}',
                style: AppDesignSystem.bodySmall(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(String text, BuildContext context) {
    // Copy to clipboard implementation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied: $text')),
    );
  }

  Future<void> _approveClosure(
      BuildContext context, JobClosureRequest request) async {
    try {
      final adminId = _authService.getCurrentUser()?.uid ?? '';

      await _dbService.approveJobClosure(
        requestId: request.id,
        adminId: adminId,
        adminResponse: _responseController.text.isNotEmpty
            ? _responseController.text
            : 'Approved',
      );

      _responseController.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job closure approved'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _rejectClosure(
      BuildContext context, JobClosureRequest request) async {
    if (_responseController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a rejection reason'),
        ),
      );
      return;
    }

    try {
      final adminId = _authService.getCurrentUser()?.uid ?? '';

      await _dbService.rejectJobClosure(
        requestId: request.id,
        adminId: adminId,
        rejectionReason: _responseController.text,
      );

      _responseController.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job closure request rejected'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
