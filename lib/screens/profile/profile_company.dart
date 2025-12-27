import 'package:flutter/material.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:freelance_app/widgets/profile_widgets.dart';
import 'package:freelance_app/screens/user/login_screen.dart';
import 'package:freelance_app/widgets/common/standard_button.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';
import 'package:freelance_app/utils/colors.dart';
import 'package:freelance_app/screens/homescreen/sidebar.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';

class CompanyProfileScreen extends StatefulWidget {
  final String? userId;

  const CompanyProfileScreen({
    super.key,
    this.userId,
  });

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  final _authService = FirebaseAuthService();
  final _dbService = FirebaseDatabaseService();

  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isSameUser = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final currentUser = _authService.getCurrentUser();
      final targetUserId = widget.userId ?? currentUser?.uid;

      if (targetUserId == null) {
        setState(() => _isLoading = false);
        return;
      }

      _isSameUser = currentUser?.uid == targetUserId;

      final userDoc = await _dbService.getUser(targetUserId);

      if (userDoc != null) {
        setState(() {
          _userData = userDoc.data() as Map<String, dynamic>? ?? {};
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_userData == null || _userData!.isEmpty) {
      return Scaffold(
        appBar: AppAppBar(
          title: 'Company Profile',
          variant: AppBarVariant.primary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.business_outlined,
                size: 64,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
              Text(
                'Company data not found',
                style: AppDesignSystem.bodyLarge(context),
              ),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
              Text(
                'Please check your connection and try again',
                style: AppDesignSystem.bodySmall(context).copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Fetch all company data from database - handle both camelCase and snake_case
    final companyName = _userData!['company_name'] as String? ??
        _userData!['companyName'] as String? ??
        _userData!['name'] as String? ??
        '';
    final email = _userData!['email'] as String? ?? '';
    final phoneNumber = _userData!['phone_number'] as String? ??
        _userData!['phoneNumber'] as String? ??
        _userData!['phone'] as String? ??
        '';
    final location = _userData!['location'] as String? ??
        _userData!['address'] as String? ??
        '';
    final industry = _userData!['industry'] as String? ?? '';
    final website = _userData!['website'] as String? ?? '';
    final description = _userData!['company_description'] as String? ??
        _userData!['companyDescription'] as String? ??
        '';
    // Check both user_image and company_logo for image
    final imageUrl = _userData!['company_logo'] as String? ??
        _userData!['user_image'] as String? ??
        _userData!['imageUrl'] as String? ??
        '';
    final approvalStatus = _userData!['approvalStatus'] as String? ??
        _userData!['approval_status'] as String? ??
        '';
    final registrationNumber = _userData!['registration_number'] as String? ??
        _userData!['registrationNumber'] as String? ??
        '';
    final rating = _userData!['rating'] != null
        ? (_userData!['rating'] as num?)?.toDouble()
        : null;
    final ratingCount = _userData!['rating_count'] as int? ??
        _userData!['ratingCount'] as int? ??
        0;

    return HintsWrapper(
      screenId: 'company_profile',
      child: Scaffold(
        backgroundColor: botsSuperLightGrey, // Match Job Seeker Dashboard
        drawer: const SideBar(),
        appBar: AppAppBar(
          title: companyName.isNotEmpty ? companyName : 'Company Profile',
          variant: AppBarVariant.primary,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Profile Hero Section
                Padding(
                  padding:
                      AppDesignSystem.paddingHorizontal(AppDesignSystem.spaceL),
                  child: AppDesignSystem.heroCard(
                    context: context,
                    backgroundColor: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.zero,
                    child: Column(
                      children: [
                        // Profile Image
                        Container(
                          width: AppDesignSystem.profileImageSize,
                          height: AppDesignSystem.profileImageSize,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                                AppDesignSystem.radiusCircular),
                            border: Border.all(
                              color: colorScheme.surface.withValues(alpha: 0.9),
                              width: AppDesignSystem.profileImageBorderWidth,
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
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: colorScheme.surface
                                            .withValues(alpha: 0.9),
                                        child: Icon(
                                          Icons.business,
                                          size: AppDesignSystem.iconSizeLarge,
                                          color: colorScheme.primary,
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: colorScheme.primary
                                        .withValues(alpha: 0.1),
                                    child: Icon(
                                      Icons.business,
                                      size: AppDesignSystem.iconSizeLarge,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                          ),
                        ),
                        AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
                        if (companyName.isNotEmpty)
                          Text(
                            companyName,
                            style:
                                AppDesignSystem.headlineSmall(context).copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                            textAlign: TextAlign.center,
                          )
                        else
                          Text(
                            'Company Name Not Available',
                            style: AppDesignSystem.bodyLarge(context).copyWith(
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                        ProfileApprovalBadge(status: approvalStatus),
                        if (industry.isNotEmpty) ...[
                          AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                          Text(
                            industry,
                            style: AppDesignSystem.bodyLarge(context).copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        // Rating display if available
                        if (rating != null && ratingCount > 0) ...[
                          AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                rating.toStringAsFixed(1),
                                style: AppDesignSystem.bodyMedium(context)
                                    .copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '($ratingCount)',
                                style:
                                    AppDesignSystem.bodySmall(context).copyWith(
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
                if (email.isNotEmpty)
                  Padding(
                    padding: AppDesignSystem.paddingSymmetric(
                      horizontal: AppDesignSystem.spaceL,
                      vertical: AppDesignSystem.spaceS,
                    ),
                    child: ProfileInfoCard(
                      icon: Icons.email_rounded,
                      label: 'Email',
                      value: email,
                      color: colorScheme.primary,
                    ),
                  ),
                if (phoneNumber.isNotEmpty)
                  Padding(
                    padding: AppDesignSystem.paddingSymmetric(
                      horizontal: AppDesignSystem.spaceL,
                      vertical: AppDesignSystem.spaceS,
                    ),
                    child: ProfileInfoCard(
                      icon: Icons.phone_rounded,
                      label: 'Phone',
                      value: phoneNumber,
                      color: colorScheme.tertiary,
                    ),
                  ),
                if (location.isNotEmpty)
                  Padding(
                    padding: AppDesignSystem.paddingSymmetric(
                      horizontal: AppDesignSystem.spaceL,
                      vertical: AppDesignSystem.spaceS,
                    ),
                    child: ProfileInfoCard(
                      icon: Icons.location_on_rounded,
                      label: 'Location',
                      value: location,
                      color: colorScheme.secondary,
                    ),
                  ),
                if (website.isNotEmpty)
                  Padding(
                    padding: AppDesignSystem.paddingSymmetric(
                      horizontal: AppDesignSystem.spaceL,
                      vertical: AppDesignSystem.spaceS,
                    ),
                    child: ProfileInfoCard(
                      icon: Icons.language_rounded,
                      label: 'Website',
                      value: website,
                      color: colorScheme.primary,
                      onTap: () => _launchURL(website),
                    ),
                  ),
                if (registrationNumber.isNotEmpty)
                  Padding(
                    padding: AppDesignSystem.paddingSymmetric(
                      horizontal: AppDesignSystem.spaceL,
                      vertical: AppDesignSystem.spaceS,
                    ),
                    child: ProfileInfoCard(
                      icon: Icons.badge_rounded,
                      label: 'Registration Number',
                      value: registrationNumber,
                      color: colorScheme.secondary,
                    ),
                  ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
                if (description.isNotEmpty) ...[
                  Padding(
                    padding: AppDesignSystem.paddingHorizontal(
                        AppDesignSystem.spaceL),
                    child: ProfileSectionCard(
                      title: 'About Us',
                      icon: Icons.info_rounded,
                      child: Text(
                        description,
                        style: AppDesignSystem.bodyMedium(context).copyWith(
                          height: AppDesignSystem.lineHeightBody,
                        ),
                      ),
                    ),
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceXL),
                ],

                if (!_isSameUser && approvalStatus == 'approved') ...[
                  Padding(
                    padding: AppDesignSystem.paddingHorizontal(
                        AppDesignSystem.spaceL),
                    child: Row(
                      children: [
                        if (phoneNumber.isNotEmpty) ...[
                          Expanded(
                            child: ProfileActionButton(
                              icon: Icons.call_rounded,
                              label: 'Call',
                              color: colorScheme.tertiary,
                              onPressed: () =>
                                  ProfileUtils.makeCall(context, phoneNumber),
                            ),
                          ),
                          AppDesignSystem.horizontalSpace(
                              AppDesignSystem.spaceM),
                        ],
                        if (email.isNotEmpty)
                          Expanded(
                            child: ProfileActionButton(
                              icon: Icons.email_rounded,
                              label: 'Email',
                              color: colorScheme.primary,
                              onPressed: () =>
                                  ProfileUtils.sendEmail(context, email),
                            ),
                          ),
                      ],
                    ),
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceXL),
                ],
                if (_isSameUser) ...[
                  Padding(
                    padding: AppDesignSystem.paddingHorizontal(
                        AppDesignSystem.spaceL),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _handleLogout(context),
                        icon: const Icon(Icons.logout_rounded),
                        label: Text(
                          'Sign Out',
                          style: AppDesignSystem.buttonText(context),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.error,
                          foregroundColor: colorScheme.onError,
                          minimumSize: Size(double.infinity,
                              AppDesignSystem.buttonHeightStandard),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppDesignSystem.borderRadiusL,
                          ),
                        ),
                      ),
                    ),
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceXL),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    try {
      String urlToLaunch = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        urlToLaunch = 'https://$url';
      }

      final uri = Uri.parse(urlToLaunch);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open website')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening website: $e')),
      );
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          StandardButton(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context, false),
            type: StandardButtonType.text,
          ),
          StandardButton(
            label: 'Sign Out',
            onPressed: () => Navigator.pop(context, true),
            type: StandardButtonType.danger,
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _authService.logout();
      if (!mounted) return;
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}
