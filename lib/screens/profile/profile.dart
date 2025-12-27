import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_app/config/user_state.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';
import 'package:freelance_app/services/notifications/notification_service.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/utils/layout.dart';
import 'package:freelance_app/widgets/common/micro_interactions.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/page_transitions.dart';
import 'package:freelance_app/screens/homescreen/sidebar.dart';
import 'package:freelance_app/screens/notifications/notifications_screen.dart';
import 'package:freelance_app/screens/user/edit_profile_screen.dart';
import 'package:freelance_app/widgets/profile_widgets.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:freelance_app/utils/colors.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';
import 'package:freelance_app/widgets/ratings_widget.dart';
import 'package:freelance_app/widgets/user_rating_card.dart';
import 'package:freelance_app/screens/user/my_ratings_screen.dart';

class ProfilePage extends StatefulWidget {
  final String userID;

  const ProfilePage({super.key, required this.userID});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirebaseDatabaseService _dbService = FirebaseDatabaseService();
  final NotificationService _notificationService = NotificationService();

  String? _currentUserId;

  bool _isLoading = false;
  String phoneNumber = "";
  String email = "";
  String address = "";
  String? name;
  String imageUrl = "";
  String joinedAt = "";
  bool _isSameUser = false;
  Map<String, dynamic> _userData = {};
  bool _isAdmin = false;
  bool _isCompany = false;
  bool _isTrainer = false;

  String _getRoleLabel() {
    if (_isAdmin) return 'Administrator';
    if (_isCompany) return 'Employer';
    if (_isTrainer) return 'Trainer / Mentor';
    return 'Job Seeker';
  }

  Stream<int> _getUnreadCount() {
    if (_currentUserId == null) {
      return Stream.value(0);
    }
    return _notificationService.getUnreadCount(_currentUserId!);
  }

  Future<void> getUserData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get user document from Appwrite
      final userDoc = await _dbService.getUser(widget.userID);

      if (userDoc == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final data = userDoc.data() as Map<String, dynamic>? ?? {};

      setState(() {
        _userData = data;
        email = data['email'] as String? ?? '';
        // For companies, use company_name; for others use name
        final isCompanyUser =
            data['isCompany'] == true || data['userType'] == 'employer';
        name = isCompanyUser
            ? (data['company_name'] as String? ??
                data['name'] as String? ??
                'Company')
            : (data['name'] as String? ?? 'User');
        phoneNumber = data['phone_number'] as String? ?? '';
        address = data['address'] as String? ?? '';
        // Load profile image - check both user_image and company_logo
        imageUrl = data['user_image'] as String? ??
            data['company_logo'] as String? ??
            '';

        // Set role flags
        _isAdmin = data['isAdmin'] == true;
        _isTrainer = data['userType'] == 'trainer' ||
            data['isTrainer'] == true ||
            data['isMentor'] == true;
        _isCompany = isCompanyUser;

        // Format joined date from Firestore createdAt
        final userData = userDoc.data() as Map<String, dynamic>? ?? {};
        final createdAt = userData['createdAt'];
        DateTime? joinedDate;
        if (createdAt != null) {
          if (createdAt is Timestamp) {
            joinedDate = createdAt.toDate();
          } else if (createdAt is String && createdAt.isNotEmpty) {
            joinedDate = DateTime.tryParse(createdAt);
          } else if (createdAt is DateTime) {
            joinedDate = createdAt;
          }
        }
        if (joinedDate != null) {
          joinedAt = ProfileUtils.formatDate(joinedDate);
        }
      });

      // Check if viewing own profile
      final currentUser = _authService.getCurrentUser();
      if (currentUser != null) {
        setState(() {
          _isSameUser = currentUser.uid == widget.userID;
        });
      }

      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Error getting user data: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          userId: widget.userID,
          currentData: _userData,
        ),
      ),
    );

    // Reload profile if changes were saved
    if (result == true) {
      getUserData();
    }
  }

  @override
  void initState() {
    super.initState();
    _currentUserId = _authService.getCurrentUser()?.uid;
    getUserData();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return HintsWrapper(
      screenId: 'profile',
      child: Scaffold(
        backgroundColor: botsSuperLightGrey, // Match Job Seeker Dashboard
        drawer: const SideBar(),
        appBar: AppAppBar(
          title: name ?? 'Profile',
          variant: AppBarVariant.primary,
          actions: [
            // Notifications
            StreamBuilder<int>(
              stream: _getUnreadCount(),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () {
                        context.pushModern(
                          page: const NotificationsScreen(),
                          type: RouteType.fadeSlide,
                        );
                      },
                    ),
                    if (count > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            count > 9 ? '9+' : '$count',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onError,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            // Edit button (only for own profile)
            if (_isSameUser && !_isLoading)
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: _navigateToEditProfile,
              ),
          ],
        ),
        body: SafeArea(
          child: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MicroInteractions.pulsingWidget(
                        child: Icon(
                          Icons.person,
                          size: 64,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: AppDesignSystem.spaceL),
                      Text(
                        'Loading profile...',
                        style: AppDesignSystem.bodyLarge(context),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // Modern Hero Header Section (Frame-1.webp style)
                      MicroInteractions.fadeInListItem(
                        child: AppDesignSystem.heroCard(
                          context: context,
                          primaryColor: AppDesignSystem
                              .brandYellow, // BOTS Yellow (balanced, not green)
                          // No rounding - square corners
                          borderRadius: BorderRadius.zero,
                          child: Column(
                            children: [
                              // Profile Image - Use actual image when available, not avatar
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                      AppDesignSystem.radiusCircular),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surface
                                        .withValues(alpha: 0.9),
                                    width: 4,
                                  ),
                                  boxShadow: AppDesignSystem.lightShadow,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                      AppDesignSystem.radiusCircular),
                                  child: imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Container(
                                              color: colorScheme.primary
                                                  .withValues(alpha: 0.1),
                                              child: Icon(
                                                Icons.person,
                                                size: 48,
                                                color: colorScheme.primary,
                                              ),
                                            );
                                          },
                                        )
                                      : Container(
                                          color: colorScheme.primary
                                              .withValues(alpha: 0.1),
                                          child: Icon(
                                            Icons.person,
                                            size: 48,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: AppDesignSystem.spaceL),

                              // Name and Role (white text on vivid blue gradient)
                              Text(
                                name ?? 'User Name',
                                style: AppDesignSystem.screenTitle(context)
                                    .copyWith(
                                  color: Theme.of(context).colorScheme.surface,
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppDesignSystem.spaceS),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppDesignSystem.spaceM,
                                  vertical: AppDesignSystem.spaceXS,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surface
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(
                                      AppDesignSystem.radiusL),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surface
                                        .withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _getRoleLabel(),
                                  style: AppDesignSystem.labelMedium(context)
                                      .copyWith(
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                              // Joined Date
                              if (joinedAt.isNotEmpty) ...[
                                const SizedBox(height: AppDesignSystem.spaceM),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surface
                                          .withValues(alpha: 0.9),
                                    ),
                                    const SizedBox(
                                        width: AppDesignSystem.spaceXS),
                                    Text(
                                      'Joined $joinedAt',
                                      style: AppDesignSystem.bodySmall(context)
                                          .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surface
                                            .withValues(alpha: 0.85),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        index: 0,
                        delayPerItem: const Duration(milliseconds: 100),
                      ),

                      // Contact Information Section
                      MicroInteractions.fadeInListItem(
                        child: AppLayout.section(
                          context: context,
                          title: 'Contact Information',
                          content: AppCard(
                            variant: SurfaceVariant.standard,
                            borderRadius: BorderRadius.zero,
                            child: Column(
                              children: [
                                // Email
                                _buildContactItem(
                                  context,
                                  icon: Icons.email_rounded,
                                  label: 'Email',
                                  value: email,
                                  color: colorScheme.primary,
                                ),

                                // Phone
                                _buildContactItem(
                                  context,
                                  icon: Icons.phone_rounded,
                                  label: 'Phone',
                                  value: phoneNumber,
                                  color: colorScheme.tertiary,
                                ),

                                // Address
                                if (address.isNotEmpty)
                                  _buildContactItem(
                                    context,
                                    icon: Icons.location_on_rounded,
                                    label: 'Address',
                                    value: address,
                                    color: colorScheme.secondary,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        index: 1,
                        delayPerItem: const Duration(milliseconds: 100),
                      ),

                      // Quick Contact (if not own profile)
                      if (!_isSameUser) ...[
                        MicroInteractions.fadeInListItem(
                          child: AppLayout.section(
                            context: context,
                            title: 'Quick Contact',
                            content: Row(
                              children: [
                                Expanded(
                                  child: _buildContactButton(
                                    context,
                                    icon: FontAwesome.whatsapp,
                                    label: 'WhatsApp',
                                    color: colorScheme.tertiary,
                                    onTap: () => ProfileUtils.openWhatsApp(
                                        context, phoneNumber),
                                  ),
                                ),
                                const SizedBox(width: AppDesignSystem.spaceM),
                                Expanded(
                                  child: _buildContactButton(
                                    context,
                                    icon: Icons.email_rounded,
                                    label: 'Email',
                                    color: colorScheme.primary,
                                    onTap: () => ProfileUtils.sendEmail(
                                      context,
                                      email,
                                      subject: 'Regarding Job Opportunity',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppDesignSystem.spaceM),
                                Expanded(
                                  child: _buildContactButton(
                                    context,
                                    icon: Icons.phone_rounded,
                                    label: 'Call',
                                    color: colorScheme.tertiary,
                                    onTap: () => ProfileUtils.makeCall(
                                        context, phoneNumber),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          index: 2,
                          delayPerItem: const Duration(milliseconds: 100),
                        ),
                      ],

                      // Ratings Section - Show User Rating Card First
                      MicroInteractions.fadeInListItem(
                        child: AppLayout.section(
                          context: context,
                          title: 'Your Rating',
                          content: UserRatingCard(
                            userId: widget.userID,
                            userType: _isCompany ? 'company' : 'jobSeeker',
                          ),
                        ),
                        index: 3,
                        delayPerItem: const Duration(milliseconds: 100),
                      ),

                      // Recent Ratings Section
                      MicroInteractions.fadeInListItem(
                        child: AppLayout.section(
                          context: context,
                          title: _isCompany
                              ? 'Reviews from Job Seekers'
                              : 'Reviews from Companies',
                          content: RatingsWidget(
                            userId: widget.userID,
                            userType: _isCompany ? 'company' : 'jobSeeker',
                            isOwnProfile: _isSameUser,
                          ),
                        ),
                        index: 4,
                        delayPerItem: const Duration(milliseconds: 100),
                      ),

                      // Account Actions (if own profile)
                      if (_isSameUser) ...[
                        MicroInteractions.fadeInListItem(
                          index: 5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppDesignSystem.spaceM,
                                vertical: AppDesignSystem.spaceM),
                            child: Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppDesignSystem.brandGreen,
                                        AppDesignSystem.brandGreen.withValues(alpha: 0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppDesignSystem.brandGreen.withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const MyRatingsScreen(),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppDesignSystem.spaceL,
                                          vertical: AppDesignSystem.spaceM,
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.rate_review_outlined,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            const SizedBox(width: AppDesignSystem.spaceM),
                                            Text(
                                              'My Ratings',
                                              style: AppDesignSystem.buttonText(context).copyWith(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(
                                              Icons.arrow_forward,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Logout
                        MicroInteractions.fadeInListItem(
                          index: 6,
                          child: Container(
                            padding:
                                const EdgeInsets.all(AppDesignSystem.spaceL),
                            child: FilledButton.icon(
                              onPressed: () async {
                                final navigator = Navigator.of(context);
                                await ProfileLogoutDialog.show(
                                  context,
                                  () async {
                                    await _authService.logout();
                                    if (!mounted) return;
                                    navigator.pop();
                                    navigator.pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) => UserState(),
                                      ),
                                    );
                                  },
                                );
                              },
                              icon: const Icon(Icons.logout),
                              label: Text(
                                'Logout',
                                style: AppDesignSystem.buttonText(context),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: colorScheme.error,
                                foregroundColor: colorScheme.onError,
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppDesignSystem.radiusM),
                                ),
                              ),
                            ),
                          ),
                          delayPerItem: const Duration(milliseconds: 100),
                        ),
                        const SizedBox(height: AppDesignSystem.spaceXL),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildContactItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.spaceM,
        vertical: AppDesignSystem.spaceS,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDesignSystem.spaceS),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: AppDesignSystem.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppDesignSystem.bodySmall(context).copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                AppDesignSystem.verticalSpace(2),
                Text(
                  value.isNotEmpty ? value : 'Not provided',
                  style: AppDesignSystem.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return MicroInteractions.scaleOnTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppDesignSystem.spaceM),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: AppDesignSystem.spaceXS),
            Text(
              label,
              style: AppDesignSystem.labelSmall(context).copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
