import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/models/plugin_model.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';
import 'package:freelance_app/services/auth/user_role_service.dart';
import 'package:freelance_app/services/plugins/plugin_navigation_service.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';
import 'package:freelance_app/widgets/common/common_widgets.dart';

class PluginsHub extends StatefulWidget {
  const PluginsHub({super.key});

  @override
  State<PluginsHub> createState() => _PluginsHubState();
}

class _PluginsHubState extends State<PluginsHub> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _dbService = FirebaseDatabaseService();
  List<PluginModel> _plugins = [];
  bool _isLoading = true;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadPlugins();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final userDoc = await _dbService.getUser(user.uid);
      if (userDoc != null && mounted) {
        final userData = userDoc.data() as Map<String, dynamic>? ?? {};
        final role = UserRoleService.fromUserData(userData);
        setState(() {
          _userRole = role.toString().split('.').last; // Convert enum to string
        });
      }
    } catch (e) {
      debugPrint('Error loading user role: $e');
    }
  }

  Future<void> _loadPlugins() async {
    try {
      // Try to load from Firestore first (production mode)
      final pluginsSnapshot = await _firestore
          .collection('plugins')
          .where('isEnabled', isEqualTo: true)
          .orderBy('order')
          .get();

      if (pluginsSnapshot.docs.isNotEmpty) {
        // Load from Firestore (dynamic/production)
        final plugins = pluginsSnapshot.docs
            .map((doc) => PluginModel.fromMap(doc.data(), doc.id))
            .where((plugin) => plugin.isAccessibleForRole(_userRole))
            .toList();
        
        if (mounted) {
          setState(() {
            _plugins = plugins;
            _isLoading = false;
          });
        }
        return;
      }
    } catch (e) {
      debugPrint('Error loading plugins from Firestore: $e');
    }

    // Fallback: Use default plugins (backward compatibility)
    if (mounted) {
      setState(() {
        _plugins = _getDefaultPlugins();
        _isLoading = false;
      });
    }
  }

  List<PluginModel> _getDefaultPlugins() {
    // Default plugins configuration (fallback)
    return [
      PluginModel(
        id: 'gig_space',
        title: 'Gig Space',
        subtitle: 'Freelance opportunities',
        icon: Icons.work_outline,
        color: AppDesignSystem.accent1,
        route: 'gig_space',
        order: 1,
      ),
      PluginModel(
        id: 'courses',
        title: 'Courses',
        subtitle: 'Learn new skills',
        icon: Icons.video_library,
        color: AppDesignSystem.accent2,
        route: 'courses',
        order: 2,
      ),
      PluginModel(
        id: 'hustle_space',
        title: 'Hustle Space',
        subtitle: 'Quick opportunities',
        icon: Icons.flash_on,
        color: AppDesignSystem.accent3,
        route: 'hustle_space',
        order: 3,
      ),
      PluginModel(
        id: 'tenders_portal',
        title: 'Tenders Portal',
        subtitle: 'Business contracts',
        icon: Icons.description,
        color: AppDesignSystem.accent2,
        route: 'tenders_portal',
        order: 4,
      ),
      PluginModel(
        id: 'youth_opportunities',
        title: 'Youth Opportunities',
        subtitle: 'For young people',
        icon: Icons.school,
        color: AppDesignSystem.accent2,
        route: 'youth_opportunities',
        order: 5,
      ),
      PluginModel(
        id: 'news_corner',
        title: 'News Corner',
        subtitle: 'Latest updates',
        icon: Icons.newspaper,
        color: AppDesignSystem.accent1,
        route: 'news_corner',
        order: 6,
      ),
      PluginModel(
        id: 'blue_pages',
        title: 'Blue Pages',
        subtitle: 'Business Directory',
        icon: Icons.business_center,
        color: AppDesignSystem.brandBlue,
        route: 'blue_pages',
        order: 7,
      ),
    ];
  }

  void _navigateToPlugin(PluginModel plugin) {
    // Dynamic navigation - no hardcoding
    // All navigation handled by PluginNavigationService
    final navService = PluginNavigationService();
    navService.navigateToPlugin(context, plugin);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppAppBar(
        title: 'Plugins Hub',
        variant: AppBarVariant.primary, // Blue background with white text
      ),
      body: HintsWrapper(
        screenId: 'plugins_hub',
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _plugins.isEmpty
              ? EmptyState(
                  icon: Icons.extension_outlined,
                  title: 'No plugins available',
                  message: 'Plugins will appear here once they are configured by administrators.',
                )
              : GridView.count(
                  crossAxisCount: 2,
                  padding: AppDesignSystem.paddingL,
                  crossAxisSpacing: AppDesignSystem.spaceM,
                  mainAxisSpacing: AppDesignSystem.spaceM,
                  childAspectRatio: 0.85,
                  children: _plugins.map((plugin) {
                    // Calculate appropriate text/icon color based on background brightness
                    // Light colors (like yellow) need dark text, dark colors (like blue/green) need light text
                    // Uses AppDesignSystem pattern: ThemeData.estimateBrightnessForColor for contrast calculation
                    final brightness = ThemeData.estimateBrightnessForColor(plugin.color);
                    final isDarkBackground = brightness == Brightness.dark;
                    // Use AppDesignSystem colors
                    final textColor = isDarkBackground ? AppDesignSystem.brandWhite : AppDesignSystem.brandBlack;
                    final iconColor = isDarkBackground ? AppDesignSystem.brandWhite : AppDesignSystem.brandBlack;
                    // Alpha values follow AppDesignSystem patterns (similar to coloredShadow uses 0.25, cardShadow uses 0.05)
                    final iconCircleColor = isDarkBackground 
                        ? AppDesignSystem.brandWhite.withValues(alpha: 0.3) // Matches AppDesignSystem opacity patterns
                        : AppDesignSystem.brandBlack.withValues(alpha: 0.1); // Matches AppDesignSystem opacity patterns
                    final iconCircleBorder = isDarkBackground
                        ? AppDesignSystem.brandWhite.withValues(alpha: 0.5)
                        : AppDesignSystem.brandBlack.withValues(alpha: 0.2);
                    final textShadowColor = isDarkBackground
                        ? AppDesignSystem.brandBlack.withValues(alpha: 0.2) // Matches AppDesignSystem shadow opacity patterns
                        : AppDesignSystem.brandWhite.withValues(alpha: 0.3);
                    
                    return GestureDetector(
                      onTap: () => _navigateToPlugin(plugin),
                      child: Container(
                        padding: AppDesignSystem.paddingM,
                        decoration: BoxDecoration(
                          color: plugin.color, // Solid color from color scheme
                          borderRadius: BorderRadius.circular(AppDesignSystem.radiusL),
                          boxShadow: AppDesignSystem.coloredShadow(plugin.color), // Colored shadow matching card color
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Icon and title row
                            Row(
                              children: [
                                Container(
                                  width: AppDesignSystem.spaceXL,
                                  height: AppDesignSystem.spaceXL,
                                  decoration: BoxDecoration(
                                    color: iconCircleColor, // Adaptive circle color based on background
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: iconCircleBorder, // Adaptive border color
                                      width: 1.5, // Standard border width (matches AppDesignSystem border patterns)
                                    ),
                                  ),
                                  child: Icon(
                                    plugin.icon,
                                    color: iconColor, // Adaptive icon color for proper contrast
                                    size: AppDesignSystem.spaceM,
                                  ),
                                ),
                                AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
                                Expanded(
                                  child: Text(
                                    plugin.title,
                                    style: AppDesignSystem.labelMedium(context).copyWith(
                                      color: textColor, // Adaptive text color for proper contrast
                                      fontWeight: FontWeight.w700,
                                      shadows: [
                                        Shadow(
                                          color: textShadowColor, // Adaptive shadow for better contrast
                                          blurRadius: AppDesignSystem.spaceXS, // 4px - subtle text shadow (matches AppDesignSystem spacing)
                                          offset: Offset(0, AppDesignSystem.spaceXS / 4), // 1px offset (using AppDesignSystem spacing ratio)
                                        ),
                                      ],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            // Subtitle
                            Text(
                              plugin.subtitle,
                              style: AppDesignSystem.bodySmall(context).copyWith(
                                color: textColor.withValues(alpha: isDarkBackground ? 0.95 : 0.8), // Adaptive opacity
                                shadows: [
                                  Shadow(
                                    color: textShadowColor, // Adaptive shadow for better contrast
                                    blurRadius: AppDesignSystem.spaceXS * 0.375, // 1.5px - subtle shadow (using AppDesignSystem spacing ratio)
                                    offset: Offset(0, AppDesignSystem.spaceXS / 4), // 1px offset (using AppDesignSystem spacing ratio)
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
      ),
    );
  }
}
