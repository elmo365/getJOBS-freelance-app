import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/screens/activity/applicant_card.dart';
import 'package:freelance_app/widgets/common/common_widgets.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';

class ApplicantsApp extends StatefulWidget {
  final String? jobId;
  const ApplicantsApp({super.key, this.jobId});

  @override
  State<ApplicantsApp> createState() => _ApplicantsAppState();
}

class _ApplicantsAppState extends State<ApplicantsApp> {
  final _authService = FirebaseAuthService();
  final _dbService = FirebaseDatabaseService();
  String? nameForposted;
  String? userImageForPosted;
  String? addressForposted;
  List<Map<String, dynamic>> _applicants = [];
  bool _isLoading = true;

  void getMyData() async {
    try {
      final user = _authService.getCurrentUser();
      if (user == null) return;

      final userDoc = await _dbService.getUser(user.uid);
      if (userDoc == null) return;

      final data = userDoc.data() as Map<String, dynamic>? ?? {};
      if (mounted) {
        setState(() {
          nameForposted = data['name'] as String?;
          userImageForPosted = data['user_image'] as String?;
          addressForposted = data['address'] as String?;
        });
      }
    } catch (e) {
      debugPrint('Error getting user data: $e');
    }
  }

  Future<void> _loadApplicants() async {
    try {
      if (widget.jobId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final result = await _dbService.getApplicationsByJob(widget.jobId!);

      if (mounted) {
        setState(() {
          _applicants = result.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              ...data,
              'id': doc.id,
              'timeapplied':
                  data['appliedAt'] ?? DateTime.now().toIso8601String(),
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading applicants: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    getMyData();
    _loadApplicants();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppAppBar(
        title: 'Bots Jobs Connect',
        variant: AppBarVariant.primary,
        centerTitle: true,
      ),
      body: Padding(
        padding: AppDesignSystem.paddingM,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _applicants.isEmpty
                ? EmptyState(
                    icon: Icons.people_outline,
                    title: 'No applicants yet',
                    message: 'No one has applied for this job posting yet. Share the job to get more applicants.',
                  )
                : ListView.separated(
                    itemBuilder: (context, index) {
                      final applicant = _applicants[index];
                      DateTime appliedDate;
                      final timeApplied = applicant['timeapplied'] ?? applicant['appliedAt'];
                      if (timeApplied != null) {
                        if (timeApplied is Timestamp) {
                          appliedDate = timeApplied.toDate();
                        } else if (timeApplied is String && timeApplied.isNotEmpty) {
                          try {
                            appliedDate = DateTime.parse(timeApplied);
                          } catch (e) {
                            appliedDate = DateTime.now();
                          }
                        } else if (timeApplied is DateTime) {
                          appliedDate = timeApplied;
                        } else {
                          appliedDate = DateTime.now();
                        }
                      } else {
                        appliedDate = DateTime.now();
                      }

                      return Applicant(
                        applicationId: applicant['id'] as String? ?? '',
                        name: applicant['applicantName'] as String? ??
                            applicant['name'] as String? ??
                            'Unknown',
                        profilePic: applicant['applicantImage'] as String? ??
                            applicant['user_image'] as String? ??
                            '',
                        date: appliedDate,
                        jobId: widget.jobId ?? '',
                        jobTitle: applicant['jobTitle'] as String? ?? 'Job',
                        status: applicant['status'] as String?,
                        userId: applicant['userId'] as String?,
                      );
                    },
                    separatorBuilder: (context, index) {
                      return Divider(
                        thickness: 1,
                        color: colorScheme.outlineVariant,
                      );
                    },
                    itemCount: _applicants.length,
                  ),
      ),
    );
  }
}
