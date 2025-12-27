import 'package:flutter/material.dart';
import 'package:freelance_app/models/user_model.dart';
import 'package:freelance_app/screens/job_seekers/job_seekers_home.dart';
import 'package:freelance_app/screens/employers/employers_home.dart';
import 'package:freelance_app/screens/trainers/trainers_home.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/micro_interactions.dart';
import 'package:freelance_app/screens/search/search_screen.dart';
import 'package:freelance_app/screens/profile/profile.dart';
import 'package:freelance_app/screens/profile/profile_company.dart';
import 'package:freelance_app/screens/activity/applicants.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';

/// Main Navigation Controller
/// Handles role-based navigation for the app
class MainNavigation extends StatefulWidget {
  final UserModel? user;
  
  const MainNavigation({super.key, this.user});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late UserRole _userRole;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final _authService = FirebaseAuthService();

  @override
  void initState() {
    super.initState();
    _userRole = widget.user?.role ?? UserRole.jobSeeker;

    _animationController = AnimationController(
      duration: MicroInteractions.normal,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: MicroInteractions.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;

    // Fade out current screen
    _animationController.reverse().then((_) {
      setState(() {
        _currentIndex = index;
      });
      // Fade in new screen
      _animationController.forward();
    });
  }

  List<Widget> _getScreens() {
    final currentUserId = _authService.getCurrentUser()?.uid ?? '';
    
    switch (_userRole) {
      case UserRole.jobSeeker:
        return [
          const JobSeekersHomeScreen(),
          const Search(), // Job Discovery - Search Screen
          _buildPlaceholderScreen(
            icon: Icons.school,
            title: 'Learning Hub',
            subtitle: 'Skill up and advance your career',
            color: Theme.of(context).colorScheme.secondary,
          ),
          currentUserId.isNotEmpty
              ? ProfilePage(userID: currentUserId) // My Profile
              : _buildPlaceholderScreen(
                  icon: Icons.person,
                  title: 'My Profile',
                  subtitle: 'Please log in to view your profile',
                  color: Theme.of(context).colorScheme.tertiary,
                ),
        ];
      case UserRole.employer:
        return [
          const EmployersHomeScreen(),
          const ApplicantsApp(jobId: null), // Candidates - Show all applicants
          _buildInterviewListScreen(), // Interviews - List of scheduled interviews
          CompanyProfileScreen(userId: null), // Company Profile - Current user's profile
        ];
      case UserRole.trainer:
        return [
          const TrainersHomeScreen(),
          _buildPlaceholderScreen(
            icon: Icons.video_library,
            title: 'My Courses',
            subtitle: 'Create and manage your courses',
            color: Theme.of(context).colorScheme.primary,
          ),
          _buildPlaceholderScreen(
            icon: Icons.live_tv,
            title: 'Live Sessions',
            subtitle: 'Host and manage live training',
            color: Theme.of(context).colorScheme.secondary,
          ),
          _buildPlaceholderScreen(
            icon: Icons.person,
            title: 'Trainer Profile',
            subtitle: 'Showcase your expertise',
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ];
    }
  }

  /// Build interview list screen for employers
  Widget _buildInterviewListScreen() {
    final currentUserId = _authService.getCurrentUser()?.uid;
    
    if (currentUserId == null) {
      return _buildPlaceholderScreen(
        icon: Icons.calendar_today,
        title: 'Interviews',
        subtitle: 'Please log in to view interviews',
        color: Theme.of(context).colorScheme.secondary,
      );
    }

    // Return a simple screen that shows interview scheduling options
    // For now, we'll show the scheduling screen with a note that they can view scheduled interviews
    return Scaffold(
      appBar: AppAppBar(
        title: 'Interviews',
        variant: AppBarVariant.primary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: AppDesignSystem.spaceL),
            Text(
              'Interview Management',
              style: AppDesignSystem.headlineLarge(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDesignSystem.spaceM),
            Text(
              'Schedule interviews from candidate applications',
              style: AppDesignSystem.bodyLarge(context).copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDesignSystem.spaceXL),
            Padding(
              padding: AppDesignSystem.paddingHorizontal(AppDesignSystem.spaceL),
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigate to candidates screen where they can schedule interviews
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ApplicantsApp(jobId: null),
                    ),
                  );
                },
                icon: const Icon(Icons.people),
                label: const Text('View Candidates'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  padding: AppDesignSystem.paddingM,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderScreen({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDesignSystem.spaceXXL),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusCircular),
              ),
              child: Icon(
                icon,
                size: 80,
                color: color,
              ),
            ),
            const SizedBox(height: AppDesignSystem.spaceL),
            Text(
              title,
              style: AppDesignSystem.headlineLarge(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDesignSystem.spaceM),
            Text(
              subtitle,
              style: AppDesignSystem.bodyLarge(context).copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDesignSystem.spaceXL),
            Text(
              'Coming Soon',
              style: AppDesignSystem.labelLarge(context).copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<NavigationDestination> _getNavigationDestinations() {
    final colorScheme = Theme.of(context).colorScheme;

    switch (_userRole) {
      case UserRole.jobSeeker:
        return [
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
            selectedIcon: Icon(
              Icons.home,
              color: colorScheme.primary,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.work_outline,
              color: colorScheme.onSurfaceVariant,
            ),
            selectedIcon: Icon(
              Icons.work,
              color: colorScheme.primary,
            ),
            label: 'Jobs',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.school_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
            selectedIcon: Icon(
              Icons.school,
              color: colorScheme.primary,
            ),
            label: 'Learn',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.person_outline,
              color: colorScheme.onSurfaceVariant,
            ),
            selectedIcon: Icon(
              Icons.person,
              color: colorScheme.primary,
            ),
            label: 'Profile',
          ),
        ];
      case UserRole.employer:
        return [
          NavigationDestination(
            icon: Icon(
              Icons.dashboard_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
            selectedIcon: Icon(
              Icons.dashboard,
              color: colorScheme.primary,
            ),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.people_outline,
              color: colorScheme.onSurfaceVariant,
            ),
            selectedIcon: Icon(
              Icons.people,
              color: colorScheme.primary,
            ),
            label: 'Candidates',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.calendar_today_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
            selectedIcon: Icon(
              Icons.calendar_today,
              color: colorScheme.primary,
            ),
            label: 'Interviews',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.person_outline,
              color: colorScheme.onSurfaceVariant,
            ),
            selectedIcon: Icon(
              Icons.person,
              color: colorScheme.primary,
            ),
            label: 'Profile',
          ),
        ];
      case UserRole.trainer:
        return [
          NavigationDestination(
            icon: Icon(
              Icons.dashboard_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
            selectedIcon: Icon(
              Icons.dashboard,
              color: colorScheme.primary,
            ),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.video_library_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
            selectedIcon: Icon(
              Icons.video_library,
              color: colorScheme.primary,
            ),
            label: 'Courses',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.live_tv_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
            selectedIcon: Icon(
              Icons.live_tv,
              color: colorScheme.primary,
            ),
            label: 'Live',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.person_outline,
              color: colorScheme.onSurfaceVariant,
            ),
            selectedIcon: Icon(
              Icons.person,
              color: colorScheme.primary,
            ),
            label: 'Profile',
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = _getScreens();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onTabTapped,
          backgroundColor: colorScheme.surfaceContainer.withValues(alpha: 0.95),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          height: 80,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          animationDuration: MicroInteractions.normal,
          destinations: _getNavigationDestinations(),
        ),
      ),
    );
  }
}

