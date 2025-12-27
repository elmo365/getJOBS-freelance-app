import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';
import 'package:freelance_app/utils/app_theme.dart';
import 'package:freelance_app/screens/homescreen/components/job_details.dart';

class Taken extends StatefulWidget {
  const Taken({super.key});

  @override
  State<Taken> createState() => _TakenState();
}

class _TakenState extends State<Taken> {
  final _authService = FirebaseAuthService();
  final _dbService = FirebaseDatabaseService();
  List<Map<String, dynamic>> _applications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    try {
      final user = _authService.getCurrentUser();
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final result = await _dbService.getApplicationsByUser(
        userId: user.uid,
        limit: 50,
      );

      if (mounted) {
        setState(() {
          _applications = result.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              ...data,
              'id': doc.id,
              'appliedAt': data['appliedAt'] ?? 
                  data['createdAt']?.toString() ?? 
                  DateTime.now().toIso8601String(),
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading applications: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_applications.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXXL),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.work_outline,
                size: 64,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
              Text(
                'No Applications Yet',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
              Text(
                'Start applying to jobs to see them here',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadApplications,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        itemCount: _applications.length,
        itemBuilder: (context, index) {
          final application = _applications[index];
          final jobId = application['jobId'] as String? ?? '';
          final jobTitle = application['jobTitle'] as String? ?? 
              application['title'] as String? ?? 
              'Unknown Job';
          final status = application['status'] as String? ?? 'pending';
          
          DateTime appliedDate;
          final appliedAt = application['appliedAt'];
          if (appliedAt != null) {
            if (appliedAt is Timestamp) {
              appliedDate = appliedAt.toDate();
            } else if (appliedAt is String && appliedAt.isNotEmpty) {
              try {
                appliedDate = DateTime.parse(appliedAt);
              } catch (e) {
                appliedDate = DateTime.now();
              }
            } else if (appliedAt is DateTime) {
              appliedDate = appliedAt;
            } else {
              appliedDate = DateTime.now();
            }
          } else {
            appliedDate = DateTime.now();
          }

          Color statusColor;
          String statusText;
          switch (status.toLowerCase()) {
            case 'accepted':
            case 'approved':
              statusColor = colorScheme.tertiary;
              statusText = 'Accepted';
              break;
            case 'rejected':
            case 'declined':
              statusColor = colorScheme.error;
              statusText = 'Rejected';
              break;
            default:
              statusColor = colorScheme.secondary;
              statusText = 'Pending';
          }

          return Card(
            margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: InkWell(
              onTap: jobId.isNotEmpty
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => JobDetailsScreen(
                            id: application['employerId'] as String? ?? '',
                            jobId: jobId,
                          ),
                        ),
                      );
                    }
                  : null,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                jobTitle,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                              Text(
                                'Applied: ${_formatDate(appliedDate)}',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            statusText,
                            style: textTheme.labelSmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
