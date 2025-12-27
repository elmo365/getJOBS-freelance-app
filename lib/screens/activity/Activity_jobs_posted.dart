import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'jobs_card.dart';
import 'package:freelance_app/utils/app_theme.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';

class Posted extends StatefulWidget {
  const Posted({super.key});

  @override
  State<Posted> createState() => _PostedState();
}

class _PostedState extends State<Posted> {
  final _authService = FirebaseAuthService();
  final _dbService = FirebaseDatabaseService();
  String? nameForposted;
  String? userImageForPosted;
  String? addressForposted;
  List<Map<String, dynamic>> _jobs = [];
  bool _isLoading = true;

  void getMyData() async {
    try {
      final user = _authService.getCurrentUser();
      if (user == null) return;

      final userDoc = await _dbService.getUser(user.uid);
      if (userDoc == null) {
        debugPrint('User document does not exist');
        return;
      }

      if (!mounted) return;

      final data = userDoc.data() as Map<String, dynamic>? ?? {};
      setState(() {
        nameForposted = data['name'] as String? ?? 'Unknown User';
        userImageForPosted = data['user_image'] as String? ?? '';
        addressForposted = data['address'] as String? ?? 'Address not set';
      });
    } catch (e) {
      debugPrint('Error getting user data: $e');
    }
  }

  Future<void> _loadUserJobs() async {
    try {
      final user = _authService.getCurrentUser();
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final result = await _dbService.getJobsByCompany(
        userId: user.uid,
        limit: 50,
      );

      if (mounted) {
        setState(() {
          _jobs = result.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              ...data,
              'job_id': doc.id,
              'created': data['createdAt'] ?? DateTime.now().toIso8601String(),
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading jobs: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    getMyData();
    _loadUserJobs();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_jobs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXXL),
        child: Center(
          child: Image.asset('assets/images/empty.png'),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(
        top: 0,
        bottom: AppTheme.spacingM,
        left: AppTheme.spacingM,
        right: AppTheme.spacingM,
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _jobs.length,
        itemBuilder: (BuildContext context, int index) {
          final job = _jobs[index];
          final jobId = job['job_id'] as String? ?? '';

          // Parse date
          DateTime jobDate;
          try {
            final dateStr = job['created'] as String?;
            if (dateStr != null) {
              jobDate = DateTime.parse(dateStr);
            } else {
              jobDate = DateTime.now();
            }
          } catch (e) {
            jobDate = DateTime.now();
          }

          // Parse deadline
          DateTime? deadline;
          try {
            final deadlineData =
                job['deadlineDate'] ?? job['deadline_timestamp'];
            if (deadlineData is Timestamp) {
              deadline = deadlineData.toDate();
            } else if (deadlineData is String) {
              deadline = DateTime.tryParse(deadlineData);
            }
          } catch (e) {
            // No deadline or parsing error
          }

          return Job(
            jobID: jobId,
            contactName: job['name'] as String? ?? 'Unknown',
            contactImage: job['user_image'] as String? ?? '',
            jobTitle: job['title'] as String? ??
                job['jobTitle'] as String? ??
                'No Title',
            uploadedBy: job['userId'] as String? ?? job['id'] as String? ?? '',
            date: jobDate,
            type: 'posted',
            deadline: deadline,
            onUpdate: () {
              // Refresh job list after deadline changes
              _loadUserJobs();
            },
          );
        },
      ),
    );
  }
}
