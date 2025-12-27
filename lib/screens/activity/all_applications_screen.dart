import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/screens/activity/applicant_card.dart';
import 'package:freelance_app/widgets/common/common_widgets.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';

/// Screen to view all applications received by a company (employer)
/// across all their job postings
class AllApplicationsScreen extends StatefulWidget {
  const AllApplicationsScreen({super.key});

  @override
  State<AllApplicationsScreen> createState() => _AllApplicationsScreenState();
}

class _AllApplicationsScreenState extends State<AllApplicationsScreen> {
  final _authService = FirebaseAuthService();
  final _dbService = FirebaseDatabaseService();
  String? nameForposted;
  String? userImageForPosted;
  String? addressForposted;
  List<Map<String, dynamic>> _applicants = [];
  List<Map<String, dynamic>> _filteredApplicants = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, pending, accepted, rejected

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

  Future<void> _loadApplications() async {
    try {
      final user = _authService.getCurrentUser();
      if (user == null) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      // Get all jobs for this employer
      final jobsResult = await _dbService.getUserJobs(user.uid);
      final jobIds = jobsResult.docs.map((doc) => doc.id).toList();

      if (jobIds.isEmpty) {
        if (mounted) {
          setState(() {
            _applicants = [];
            _filteredApplicants = [];
            _isLoading = false;
          });
        }
        return;
      }

      // Get applications for all these jobs
      List<Map<String, dynamic>> allApplicants = [];

      for (final jobId in jobIds) {
        try {
          final result = await _dbService.getApplicationsByJob(jobId);
          
          for (final doc in result.docs) {
            final data = doc.data() as Map<String, dynamic>;
            allApplicants.add({
              ...data,
              'id': doc.id,
              'jobId': jobId,
              'timeapplied':
                  data['appliedAt'] ?? DateTime.now().toIso8601String(),
            });
          }
        } catch (e) {
          debugPrint('Error loading applicants for job $jobId: $e');
        }
      }

      // Sort by date (newest first)
      allApplicants.sort((a, b) {
        final dateA = _parseDate(a['timeapplied']);
        final dateB = _parseDate(b['timeapplied']);
        return dateB.compareTo(dateA);
      });

      if (mounted) {
        setState(() {
          _applicants = allApplicants;
          _applyFilter();
        });
      }
    } catch (e) {
      debugPrint('Error loading applications: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  DateTime _parseDate(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    if (dateValue is Timestamp) return dateValue.toDate();
    if (dateValue is String && dateValue.isNotEmpty) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return DateTime.now();
      }
    }
    if (dateValue is DateTime) return dateValue;
    return DateTime.now();
  }

  void _applyFilter() {
    if (_selectedFilter == 'all') {
      _filteredApplicants = _applicants;
    } else {
      _filteredApplicants = _applicants
          .where((app) => (app['status'] ?? 'pending') == _selectedFilter)
          .toList();
    }
    _isLoading = false;
  }

  @override
  void initState() {
    super.initState();
    getMyData();
    _loadApplications();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppAppBar(
        title: 'All Applications',
        variant: AppBarVariant.primary,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
                _applyFilter();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Applications'),
              ),
              const PopupMenuItem(
                value: 'pending',
                child: Text('Pending'),
              ),
              const PopupMenuItem(
                value: 'accepted',
                child: Text('Accepted'),
              ),
              const PopupMenuItem(
                value: 'rejected',
                child: Text('Rejected'),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: AppDesignSystem.paddingM,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _filteredApplicants.isEmpty
                ? EmptyState(
                    icon: Icons.people_outline,
                    title: 'No applications',
                    message: _applicants.isEmpty
                        ? 'No one has applied for your job postings yet.'
                        : 'No ${_selectedFilter == "all" ? "" : _selectedFilter} applications to display.',
                  )
                : ListView.separated(
                    itemBuilder: (context, index) {
                      final applicant = _filteredApplicants[index];
                      final appliedDate = _parseDate(applicant['timeapplied']);

                      return Applicant(
                        applicationId: applicant['id'] as String? ?? '',
                        name: applicant['applicantName'] as String? ??
                            applicant['name'] as String? ??
                            'Unknown',
                        profilePic: applicant['applicantImage'] as String? ??
                            applicant['user_image'] as String? ??
                            '',
                        date: appliedDate,
                        jobId: applicant['jobId'] as String? ?? '',
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
                    itemCount: _filteredApplicants.length,
                  ),
      ),
    );
  }
}
