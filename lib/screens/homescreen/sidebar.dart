import 'package:flutter/material.dart';
import 'package:freelance_app/screens/activity/activity.dart';
import 'package:freelance_app/screens/plugins_hub/plugins_hub.dart' show PluginsHub;
import 'package:freelance_app/screens/admin/admin_approval_screen.dart';
import 'package:freelance_app/screens/admin/admin_login_screen.dart';
import 'package:freelance_app/screens/admin/admin_panel_screen.dart';
import 'package:freelance_app/screens/admin/web_admin_login.dart';
import 'package:freelance_app/screens/employers/job_posting_screen.dart';
import 'package:freelance_app/screens/employers/candidate_suggestions_screen.dart';
import 'package:freelance_app/screens/employers/interview_scheduling_screen.dart';
import 'package:freelance_app/screens/job_seekers/job_matching_screen.dart';
import 'package:freelance_app/screens/job_seekers/cv_builder_screen.dart';
import 'package:freelance_app/screens/job_seekers/video_resume_screen.dart';
import 'package:freelance_app/screens/job_seekers/interview_coach_screen.dart';
import 'package:freelance_app/screens/job_seekers/interview_management_job_seeker_screen.dart';
import 'package:freelance_app/screens/job_seekers/application_management_screen.dart';
import 'package:freelance_app/screens/employers/application_management_screen.dart';
import 'package:freelance_app/screens/notifications/notifications_screen.dart';
import 'package:freelance_app/screens/profile/profile.dart';
import 'package:freelance_app/screens/wallet/user_wallet_screen.dart';
import 'package:freelance_app/screens/search/search_screen.dart';
import 'package:freelance_app/screens/trainers/courses_screen.dart';
import 'package:freelance_app/screens/trainers/live_sessions_screen.dart';
import 'package:freelance_app/screens/trainers/trainer_application_screen.dart';
import 'package:freelance_app/services/notifications/notification_service.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import '../../config/user_state.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:freelance_app/services/monetization_visibility_service.dart';
import 'package:freelance_app/screens/chat/chat_list_screen.dart';

class SideBar extends StatefulWidget {
  const SideBar({super.key});

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  final _authService = FirebaseAuthService();
  final _dbService = FirebaseDatabaseService();
  final _notificationService = NotificationService();
  String _userName = '';
  String _userEmail = '';
  String _userImage = '';
  String? _userId;
  bool _isAdmin = false;
  bool _isCompany = false;
  bool _isTrainer = false;
  bool _isJobSeeker = false;
  bool _isLoading = true;
  bool _showWallet = false; // Controls visibility of Wallet Menu Item

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _authService.getCurrentUser();
      if (user != null) {
        final userDoc = await _dbService.getUser(user.uid);
        final userData = userDoc?.data() as Map<String, dynamic>? ?? {};
        
        final isCompanyUser = userData['isCompany'] == true ||
            userData['userType'] == 'employer';
        
        final monetizationService = MonetizationVisibilityService();
        final showWallet = await monetizationService.isWalletVisible();

        if (mounted) {
          setState(() {
            _userId = user.uid;
            _userName = isCompanyUser
                ? (userData['company_name'] as String? ??
                    userData['name'] as String? ??
                    'Company')
                : (userData['name'] as String? ?? 'User');
            _userEmail = user.email ?? '';
            _userImage = (userData['user_image'] as String? ??
                userData['company_logo'] as String? ??
                '');
            _isAdmin = userData['isAdmin'] == true;
            _isTrainer = userData['userType'] == 'trainer' ||
                userData['isTrainer'] == true ||
                userData['isMentor'] == true;
            _isCompany = isCompanyUser;
            _isJobSeeker = !_isAdmin && !_isCompany && !_isTrainer;
            
            _showWallet = showWallet;

            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Stream<int> _getUnreadCount() {
    if (_userId == null) {
      return Stream.value(0);
    }
    return _notificationService.getUnreadCount(_userId!);
  }

  String _getRoleLabel() {
    if (_isAdmin) return 'Administrator';
    if (_isCompany) return 'Employer';
    if (_isTrainer) return 'Trainer / Mentor';
    return 'Job Seeker';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Drawer(
        backgroundColor: colorScheme.surface,
        child: Column(
          children: [
            // User Header - Solid color, no shadows (2025 Frame-1 style)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDesignSystem.spaceL),
              decoration: BoxDecoration(
                color: AppDesignSystem.brandBlue, // BOTS Blue (balanced)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile photo with proper loading (Frame-1 style: white border)
                  Container(
                    padding: AppDesignSystem.paddingXS,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(34),
                      child: _userImage.isNotEmpty
                          ? Image.network(
                              _userImage,
                              width: 68,
                              height: 68,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 68,
                                  height: 68,
                                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.2),
                                  child: Icon(
                                    _isCompany ? Icons.business : Icons.person,
                                    size: 36,
                                    color: Theme.of(context).colorScheme.surface,
                                  ),
                                );
                              },
                            )
                          : Container(
                              width: 68,
                              height: 68,
                              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.2),
                              child: Icon(
                                _isCompany ? Icons.business : Icons.person,
                                size: 36,
                                color: Theme.of(context).colorScheme.surface,
                              ),
                            ),
                    ),
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                  Text(
                    _isLoading ? 'Loading...' : _userName,
                    style: AppDesignSystem.titleMedium(context).copyWith(
                      color: Theme.of(context).colorScheme.surface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                  Text(
                    _isLoading ? '' : _userEmail,
                    style: AppDesignSystem.bodySmall(context).copyWith(
                      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
                    ),
                  ),
                  // Role badge - shows correct role (Frame-1 style: white badge)
                  if (!_isLoading) ...[
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                    Container(
                      padding: AppDesignSystem.paddingSymmetric(
                        horizontal: AppDesignSystem.spaceM,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.2),
                        borderRadius: AppDesignSystem.borderRadiusL,
                      ),
                      child: Text(
                        _getRoleLabel(),
                        style: AppDesignSystem.labelSmall(context).copyWith(
                          color: Theme.of(context).colorScheme.surface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                    vertical: AppDesignSystem.spaceM),
                children: [
                  // Profile
                  _MenuItem(
                    icon: Icons.person,
                    title: 'My Profile',
                    color: colorScheme.primary,
                    onTap: () {
                      final user = _authService.getCurrentUser();
                      if (user != null) {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfilePage(userID: user.uid),
                          ),
                        );
                      }
                    },
                  ),

                  // Notifications
                  StreamBuilder<int>(
                    stream: _getUnreadCount(),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return _MenuItem(
                        icon: Icons.notifications,
                        title: 'Notifications',
                        color: colorScheme.tertiary,
                        badge: count > 0 ? count.toString() : null,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const NotificationsScreen()),
                          );
                        },
                      );
                    },
                  ),

                  // Wallet
                  if (_showWallet)
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text('My Wallet'),
                onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserWalletScreen()),
                );
              },
            ),
          ListTile(
            leading: const Icon(Icons.message),
            title: const Text('Messages'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatListScreen()),
              );
            },
          ),

                  // Job Seeker Menu Items
                  if (_isJobSeeker) ...[
                    Divider(
                      color: colorScheme.outlineVariant,
                      thickness: 1,
                      indent: AppDesignSystem.spaceM,
                      endIndent: AppDesignSystem.spaceM,
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: AppDesignSystem.spaceM,
                        top: AppDesignSystem.spaceS,
                        bottom: AppDesignSystem.spaceS,
                      ),
                      child: Text(
                        'JOB SEEKER',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    _MenuItem(
                      icon: Icons.work_outline,
                      title: 'Browse Jobs',
                      color: colorScheme.primary,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const Search()),
                        );
                      },
                    ),
                    _MenuItem(
                      icon: Icons.auto_awesome,
                      title: 'Smart Job Matching',
                      color: colorScheme.tertiary,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const JobMatchingScreen()),
                        );
                      },
                    ),
                    _MenuItem(
                      icon: Icons.description,
                      title: 'CV Builder',
                      color: colorScheme.secondary,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CVBuilderScreen()),
                        );
                      },
                    ),
                    _MenuItem(
                      icon: Icons.videocam,
                      title: 'Video Resume',
                      color: colorScheme.primary,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const VideoResumeScreen()),
                        );
                      },
                    ),
                    _MenuItem(
                      icon: Icons.psychology,
                      title: 'AI Interview Coach',
                      color: Colors.deepPurple,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const InterviewCoachScreen()),
                        );
                      },
                    ),
                    _MenuItem(
                      icon: Icons.history,
                      title: 'Manage Applications',
                      color: colorScheme.tertiary,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ApplicationManagementJobSeekerScreen()),
                        );
                      },
                    ),
                    _MenuItem(
                      icon: Icons.calendar_today,
                      title: 'My Interviews',
                      color: AppDesignSystem.brandGreen,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const InterviewManagementJobSeekerScreen()),
                        );
                      },
                    ),
                    _MenuItem(
                      icon: Icons.school,
                      title: 'Apply as Trainer',
                      color: Colors.amber,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const TrainerApplicationScreen()),
                        );
                      },
                    ),
                  ],

                  // Employer Menu Items
                  if (_isCompany) ...[
                    Divider(
                      color: colorScheme.outlineVariant,
                      thickness: 1,
                      indent: AppDesignSystem.spaceM,
                      endIndent: AppDesignSystem.spaceM,
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: AppDesignSystem.spaceM,
                        top: AppDesignSystem.spaceS,
                        bottom: AppDesignSystem.spaceS,
                      ),
                      child: Text(
                        'EMPLOYER',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    _MenuItem(
                      icon: Icons.add_circle_outline,
                      title: 'Post a Job',
                      color: colorScheme.secondary,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const JobPostingScreen()),
                        );
                      },
                    ),
                    _MenuItem(
                      icon: Icons.people,
                      title: 'View Applications',
                      color: colorScheme.primary,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ApplicationManagementScreen()),
                        );
                      },
                    ),
                    _MenuItem(
                      icon: Icons.auto_awesome,
                      title: 'AI Candidate Suggestions',
                      color: colorScheme.tertiary,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const CandidateSuggestionsScreen()),
                        );
                      },
                    ),
                    _MenuItem(
                      icon: Icons.calendar_today,
                      title: 'Schedule Interview',
                      color: colorScheme.secondary,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const InterviewSchedulingScreen()),
                        );
                      },
                    ),
                  ],

                  if (_isTrainer) ...[
                    Divider(
                      color: colorScheme.outlineVariant,
                      thickness: 1,
                      indent: AppDesignSystem.spaceM,
                      endIndent: AppDesignSystem.spaceM,
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: AppDesignSystem.spaceM,
                        top: AppDesignSystem.spaceS,
                        bottom: AppDesignSystem.spaceS,
                      ),
                      child: Text(
                        'TRAINER',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    _MenuItem(
                      icon: Icons.video_library,
                      title: 'My Courses',
                      color: colorScheme.primary,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CoursesScreen()),
                        );
                      },
                    ),
                    _MenuItem(
                      icon: Icons.live_tv,
                      title: 'Live Sessions',
                      color: colorScheme.tertiary,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LiveSessionsScreen()),
                        );
                      },
                    ),
                  ],

                  // Common Menu Items
                  Divider(
                    color: colorScheme.outlineVariant,
                    thickness: 1,
                    indent: AppDesignSystem.spaceM,
                    endIndent: AppDesignSystem.spaceM,
                  ),
                  _MenuItem(
                    icon: Icons.history,
                    title: 'My Activity',
                    color: colorScheme.primary,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const JobsActivity()),
                      );
                    },
                  ),
                  _MenuItem(
                    icon: Icons.extension,
                    title: 'Plugins',
                    color: colorScheme.tertiary,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PluginsHub()),
                      );
                    },
                  ),

                  // Admin Section
                  if (_isAdmin) ...[
                    Divider(
                      color: colorScheme.outlineVariant,
                      thickness: 1,
                      indent: AppDesignSystem.spaceM,
                      endIndent: AppDesignSystem.spaceM,
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: AppDesignSystem.spaceM,
                        top: AppDesignSystem.spaceS,
                        bottom: AppDesignSystem.spaceS,
                      ),
                      child: Text(
                        'ADMIN',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    _MenuItem(
                      icon: Icons.admin_panel_settings,
                      title: 'Admin Panel',
                      color: colorScheme.secondary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AdminPanelScreen()),
                        );
                      },
                    ),
                    _MenuItem(
                      icon: Icons.verified_user, // Kept original icon
                      title: 'Approvals',
                      color: colorScheme.secondary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AdminApprovalScreen()),
                        );
                      },
                    ),
                    _MenuItem(
                      icon: Icons.admin_panel_settings,
                      title: 'Admin Hub',
                      color: colorScheme.secondary, // Added color for consistency
                      onTap: () {
                        // Navigate to Hub if exists
                        Navigator.pop(context); // Added pop for consistency
                        // Example navigation if AdminHubScreen exists:
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(builder: (_) => const AdminHubScreen()),
                        // );
                      },
                    ),
                  ],

                  Divider(
                    color: colorScheme.outlineVariant,
                    thickness: 1,
                    indent: AppDesignSystem.spaceM,
                    endIndent: AppDesignSystem.spaceM,
                  ),

                  if (_isAdmin) ...[
                    Padding(
                      padding: EdgeInsets.only(
                        left: AppDesignSystem.spaceM,
                        top: AppDesignSystem.spaceS,
                        bottom: AppDesignSystem.spaceS,
                      ),
                      child: Text(
                        'ADMIN ACCESS',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    _MenuItem(
                      icon: Icons.admin_panel_settings,
                      title: 'Admin Login',
                      color: colorScheme.primary,
                      onTap: () async {
                        Navigator.pop(context);
                        await _authService.logout();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminLoginScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                    ),
                    if (kIsWeb)
                      _MenuItem(
                        icon: Icons.web,
                        title: 'Web Admin Login',
                        color: colorScheme.tertiary,
                        onTap: () async {
                          Navigator.pop(context);
                          await _authService.logout();
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const WebAdminLogin(),
                              ),
                              (route) => false,
                            );
                          }
                        },
                      ),
                    Divider(
                      color: colorScheme.outlineVariant,
                      thickness: 1,
                      indent: AppDesignSystem.spaceM,
                      endIndent: AppDesignSystem.spaceM,
                    ),
                  ],

                  _MenuItem(
                    icon: Icons.info_outline,
                    title: 'About',
                    color: colorScheme.onSurfaceVariant,
                    onTap: () {
                      Navigator.pop(context);
                      _showAboutDialog(context);
                    },
                  ),
                  _MenuItem(
                    icon: Icons.logout,
                    title: 'Logout',
                    color: colorScheme.error,
                    onTap: () async {
                      await _authService.logout();
                      if (context.mounted) {
                        Navigator.pop(context);
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const UserState()),
                          (route) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            // App Version
            Padding(
              padding: EdgeInsets.all(AppDesignSystem.spaceM),
              child: Text(
                'BotsJobsConnect v1.0',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final screenWidth = MediaQuery.of(context).size.width;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: screenWidth > 600 ? 40 : 20, // More padding on larger screens
          vertical: 24,
        ),
        contentPadding: AppDesignSystem.paddingM,
        title: Row(
          children: [
            Icon(Icons.info_outline, color: colorScheme.primary),
            SizedBox(width: AppDesignSystem.spaceS),
            Flexible(
              child: Text(
                'About BotsJobsConnect',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: screenWidth > 600 ? 500 : screenWidth * 0.9, // Responsive max width
            maxHeight: MediaQuery.of(context).size.height * 0.7, // Max 70% of screen height
          ),
          child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'BotsJobsConnect is your comprehensive platform for connecting job seekers, employers, and trainers.',
                style: textTheme.bodyMedium,
              ),
              SizedBox(height: AppDesignSystem.spaceM),
              Text(
                'Features:',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: AppDesignSystem.spaceS),
              _AboutFeature('🔍 Job Search & Matching'),
              _AboutFeature('📝 CV Builder'),
              _AboutFeature('🎥 Video Resumes'),
              _AboutFeature('🧠 AI Interview Coach'),
              _AboutFeature('💼 Company Verification'),
              _AboutFeature('📚 Training & Courses'),
              _AboutFeature('🚀 Gigs & Opportunities'),
            ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(AppDesignSystem.spaceS),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      trailing: badge != null
          ? Badge(
              label: Text(badge!),
              child: const SizedBox.shrink(),
            )
          : null,
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppDesignSystem.spaceM,
        vertical: 4,
      ),
    );
  }
}

class _AboutFeature extends StatelessWidget {
  final String text;

  const _AboutFeature(this.text);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: AppDesignSystem.spaceS),
      child: Row(
        children: [
          AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
          Expanded(
            child: Text(
              text,
              style: textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
