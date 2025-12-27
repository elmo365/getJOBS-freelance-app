import 'package:flutter/material.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/screens/homescreen/sidebar.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';
import 'activity_jobs_posted.dart';
import 'activity_jobs_taken.dart';

class JobsActivity extends StatefulWidget {
  const JobsActivity({super.key});

  @override
  State<JobsActivity> createState() => _JobsActivityState();
}

class _JobsActivityState extends State<JobsActivity> {
  final _authService = FirebaseAuthService();
  final _dbService = FirebaseDatabaseService();
  bool _isLoading = true;
  bool _isCompany = false;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final user = _authService.getCurrentUser();
      if (user == null) {
        setState(() {
          _isLoading = false;
          _isCompany = false; // Default to job seeker
        });
        return;
      }

      final userDoc = await _dbService.getUser(user.uid);
      if (userDoc == null) {
        setState(() {
          _isLoading = false;
          _isCompany = false; // Default to job seeker view
        });
        return;
      }

      final data = userDoc.data() as Map<String, dynamic>? ?? {};
      final isCompanyUser = data['isCompany'] == true ||
          data['userType'] == 'employer';

      setState(() {
        _isCompany = isCompanyUser;
        // Companies see "Jobs Posted", job seekers see "Jobs Taken"
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isCompany = false; // Default to job seeker view
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return HintsWrapper(
        screenId: 'activity',
        child: Scaffold(
        drawer: const SideBar(),
        appBar: AppAppBar(
          title: 'My Activity',
          variant: AppBarVariant.primary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: colorScheme.primary),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
              Text(
                'Loading...',
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
      );
    }

    // Show role-specific content
    if (_isCompany) {
      // Companies see "Jobs Posted"
      return HintsWrapper(
        screenId: 'activity',
        child: Scaffold(
        drawer: const SideBar(),
        appBar: AppAppBar(
          title: 'My Activity',
          variant: AppBarVariant.primary,
        ),
        body: Posted(),
      ),
      );
    } else {
      // Job Seekers see "Jobs Taken" (applications)
      return HintsWrapper(
        screenId: 'activity',
        child: Scaffold(
        drawer: const SideBar(),
        appBar: AppAppBar(
          title: 'My Activity',
          variant: AppBarVariant.primary,
        ),
        body: Taken(),
      ),
      );
    }
  }
}
