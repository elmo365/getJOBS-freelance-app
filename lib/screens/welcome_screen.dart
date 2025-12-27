import 'package:flutter/material.dart';
import 'package:freelance_app/screens/user/login_screen.dart';
import 'package:freelance_app/screens/user/signup_screen.dart';
import 'package:freelance_app/screens/admin/admin_login_screen.dart';
import 'package:freelance_app/screens/admin/admin_setup_screen.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/micro_interactions.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';

/// Modern 2025 Welcome Screen
/// Features: Gradient background, animated logo, glass-morphic buttons
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  int _tapCount = 0;
  DateTime? _lastTapTime;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Fade in animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Slide up animation for buttons
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.fastOutSlowIn,
    ));

    // Start animations with stagger
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _handleLogoTap() {
    final now = DateTime.now();

    // Reset counter if more than 2 seconds since last tap
    if (_lastTapTime == null ||
        now.difference(_lastTapTime!) > const Duration(seconds: 2)) {
      _tapCount = 1;
    } else {
      _tapCount++;
    }

    _lastTapTime = now;

    // Navigate to admin setup after 5 taps
    if (_tapCount >= 5) {
      _tapCount = 0;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AdminSetupScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final colorScheme = Theme.of(context).colorScheme;

    return HintsWrapper(
      screenId: 'welcome_screen',
      child: Scaffold(
      body: Container(
        height: size.height,
        width: double.infinity,
        // 2025 pattern: Subtle gradient background
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppDesignSystem.nearlyWhite,
              AppDesignSystem.heroAccent
                  .withValues(alpha: 0.05), // BOTS Yellow (balanced)
              AppDesignSystem.softBackground,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceXL),

              // Animated Logo Section
              Flexible(
                flex: 2,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: MicroInteractions.scaleOnTap(
                    onTap: _handleLogoTap,
                    child: Container(
                      padding: AppDesignSystem.paddingSymmetric(
                        horizontal: AppDesignSystem.spaceXL,
                        vertical: AppDesignSystem.spaceL,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo with 2025 glass container
                          Container(
                            padding: AppDesignSystem.paddingL,
                            decoration: BoxDecoration(
                              color: colorScheme.surface.withValues(alpha: 0.9),
                              borderRadius: AppDesignSystem.borderRadiusXL,
                              boxShadow: AppDesignSystem.lightShadow,
                              border: Border.all(
                                color: colorScheme.surface.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: size.width * 0.6,
                                maxHeight: 140,
                              ),
                              child: Image.asset(
                                "assets/images/BOTSJOBSCONNECT logo.png",
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Welcome text with modern typography
              FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: AppDesignSystem.paddingHorizontal(AppDesignSystem.spaceL),
                  child: Column(
                    children: [
                      Text(
                        "Welcome to",
                        style: AppDesignSystem.bodyMedium(context).copyWith(
                          color: colorScheme.onSurfaceVariant,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                      Text(
                        "Bots Jobs Connect",
                        style: AppDesignSystem.headlineLarge(context).copyWith(
                          fontWeight: FontWeight.w800,
                          color:
                              AppDesignSystem.brandBlue, // BOTS Blue (balanced)
                          letterSpacing: -0.5,
                        ),
                      ),
                      AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                      Container(
                        padding: AppDesignSystem.paddingSymmetric(
                          horizontal: AppDesignSystem.spaceM,
                          vertical: AppDesignSystem.spaceS,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondary.withValues(alpha: 0.1),
                          borderRadius: AppDesignSystem.borderRadiusL,
                        ),
                        child: Text(
                          "Get the job done!",
                          style: AppDesignSystem.titleMedium(context).copyWith(
                            color: colorScheme.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              AppDesignSystem.verticalSpace(AppDesignSystem.spaceXL),

              // Modern 2025 Buttons with slide animation
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: AppDesignSystem.paddingHorizontal(AppDesignSystem.spaceL),
                    child: Column(
                      children: [
                        // Primary Login Button with gradient
                        MicroInteractions.scaleOnTap(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: AppDesignSystem.paddingVertical(18),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppDesignSystem
                                      .brandBlue, // BOTS Blue (primary)
                                  AppDesignSystem
                                      .brandGreen, // BOTS Green (secondary)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: AppDesignSystem.borderRadiusL,
                              boxShadow: AppDesignSystem.coloredShadow(
                                AppDesignSystem
                                    .brandBlue, // BOTS Blue (balanced)
                              ),
                            ),
                            child: Center(
                              child: Text(
                                "Login",
                                style: AppDesignSystem.buttonText(context)
                                    .copyWith(
                                  color: colorScheme.onPrimary,
                                  fontSize: 18,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),

                        AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),

                        // Register Button - Outlined style
                        MicroInteractions.scaleOnTap(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignUpScreen(),
                            ),
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: AppDesignSystem.paddingVertical(18),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: AppDesignSystem.borderRadiusL,
                              border: Border.all(
                                color: AppDesignSystem.heroPrimary.withValues(
                                    alpha: 0.3), // BOTS Yellow (balanced)
                                width: 2,
                              ),
                              boxShadow: AppDesignSystem.lightShadow,
                            ),
                            child: Center(
                              child: Text(
                                "Register",
                                style: AppDesignSystem.buttonText(context)
                                    .copyWith(
                                  color:
                                      AppDesignSystem.heroPrimary, // BOTS Green
                                  fontSize: 18,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),

                        AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),

                        // Admin Login - Subtle text link
                        MicroInteractions.scaleOnTap(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminLoginScreen(),
                            ),
                          ),
                          child: Container(
                            padding: AppDesignSystem.paddingSymmetric(
                              horizontal: AppDesignSystem.spaceM,
                              vertical: AppDesignSystem.spaceM,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.admin_panel_settings_outlined,
                                  size: 18,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
                                Text(
                                  "Admin Login",
                                  style: AppDesignSystem.labelLarge(context)
                                      .copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              AppDesignSystem.verticalSpace(AppDesignSystem.spaceXL),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
