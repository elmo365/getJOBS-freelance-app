import 'package:freelance_app/screens/welcome_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/micro_interactions.dart';

/// Modern 2025 Onboarding Screen
/// Features: Gradient backgrounds, staggered animations, glass-morphic cards
class OnBoardingPage extends StatefulWidget {
  const OnBoardingPage({super.key});

  @override
  State<OnBoardingPage> createState() => _OnBoardingPageState();
}

class _OnBoardingPageState extends State<OnBoardingPage>
    with TickerProviderStateMixin {
  final introKey = GlobalKey<IntroductionScreenState>();
  late AnimationController _backgroundAnimationController;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    // Subtle background animation for 2025 feel
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat(reverse: true);

    _backgroundAnimation = CurvedAnimation(
      parent: _backgroundAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    super.dispose();
  }

  void _onIntroEnd(BuildContext context) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const WelcomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  Widget _buildHeroImage(String assetName, int index) {
    return MicroInteractions.fadeInListItem(
      child: Container(
        margin: AppDesignSystem.paddingSymmetric(
          horizontal: AppDesignSystem.spaceL,
          vertical: AppDesignSystem.spaceM,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppDesignSystem.borderRadiusXL,
            gradient: LinearGradient(
              colors: [
                AppDesignSystem.heroPrimary.withValues(alpha: 0.15), // BOTS Blue
                AppDesignSystem.heroSecondary.withValues(alpha: 0.1), // BOTS Green
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: AppDesignSystem.lightShadow,
          ),
          child: ClipRRect(
            borderRadius: AppDesignSystem.borderRadiusXL,
            child: Container(
              padding: AppDesignSystem.paddingL,
              child: Image.asset(
                'assets/images/$assetName',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
      index: index,
      delayPerItem: const Duration(milliseconds: 200),
      duration: const Duration(milliseconds: 800),
      slideOffset: const Offset(0, 30),
    );
  }

  Widget _buildFeatureChips() {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        _buildFeatureChip(
          icon: Icons.work_outline,
          label: 'Smart Matching',
          color: colorScheme.primary,
        ),
        _buildFeatureChip(
          icon: Icons.school,
          label: 'Skill Development',
          color: colorScheme.secondary,
        ),
        _buildFeatureChip(
          icon: Icons.people,
          label: 'Network Building',
          color: colorScheme.tertiary,
        ),
      ],
    );
  }

  Widget _buildFeatureChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: AppDesignSystem.paddingSymmetric(
        horizontal: AppDesignSystem.spaceM,
        vertical: AppDesignSystem.spaceS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppDesignSystem.borderRadiusL,
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
          Text(
            label,
            style: AppDesignSystem.labelMedium(context).copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final pageDecoration = PageDecoration(
      titleTextStyle: AppDesignSystem.headlineMedium(context).copyWith(
        fontWeight: FontWeight.w800,
        color: colorScheme.onSurface,
        height: 1.2,
        letterSpacing: -0.5,
      ),
      bodyTextStyle: AppDesignSystem.bodyLarge(context).copyWith(
        color: colorScheme.onSurfaceVariant,
        height: 1.6,
        letterSpacing: 0.2,
      ),
      bodyPadding: AppDesignSystem.paddingSymmetric(
        horizontal: AppDesignSystem.spaceL,
        vertical: AppDesignSystem.spaceM,
      ),
      pageColor: Colors.transparent,
      imageFlex: 4,
      bodyFlex: 3,
      imagePadding: EdgeInsets.zero,
      contentMargin: AppDesignSystem.paddingHorizontal(AppDesignSystem.spaceM),
      titlePadding: AppDesignSystem.paddingOnly(bottom: AppDesignSystem.spaceM),
    );

    return Scaffold(
      backgroundColor: AppDesignSystem.nearlyWhite,
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          final t = _backgroundAnimation.value;
          return SafeArea(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppDesignSystem.nearlyWhite,
                    colorScheme.primary.withValues(
                      alpha: 0.03 + (t * 0.02),
                    ),
                    colorScheme.secondary.withValues(
                      alpha: 0.02 + (t * 0.01),
                    ),
                    AppDesignSystem.softBackground,
                  ],
                ),
              ),
              child: child,
            ),
          );
        },
        child: IntroductionScreen(
          key: introKey,
          globalBackgroundColor: Colors.transparent,
          pages: [
            PageViewModel(
              title: "Find Your Dream Job",
              body:
                  "Discover thousands of job opportunities tailored to your skills and interests. Your next career move starts here!",
              image: _buildHeroImage('Dream_jobs.jpg', 0),
              decoration: pageDecoration,
            ),
            PageViewModel(
              title: "Apply with Ease",
              body:
                  "Browse job listings, upload your CV, and apply to positions that match your profile. Track your applications all in one place.",
              image: _buildHeroImage('opportunities.jpg', 1),
              decoration: pageDecoration,
            ),
            PageViewModel(
              title: "Build Your Career",
              bodyWidget: Padding(
                padding: AppDesignSystem.paddingHorizontal(
                  AppDesignSystem.spaceL,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                    // Icon Card
                    Container(
                      padding: AppDesignSystem.paddingL,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: AppDesignSystem.borderRadiusXL,
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.trending_up_rounded,
                        color: colorScheme.primary,
                        size: 64,
                      ),
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceXL),
                    Text(
                      "Create your profile, showcase your skills, and connect with top employers.",
                      style: AppDesignSystem.bodyLarge(context).copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceXL),
                    _buildFeatureChips(),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.rocket_launch,
                          color: colorScheme.tertiary,
                          size: 28,
                        ),
                        AppDesignSystem.horizontalSpace(
                          AppDesignSystem.spaceM,
                        ),
                        Flexible(
                          child: Text(
                            "Start your job search today!",
                            style:
                                AppDesignSystem.titleMedium(context).copyWith(
                              color: colorScheme.tertiary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              decoration: pageDecoration.copyWith(
                bodyFlex: 4,
                imageFlex: 0,
                bodyAlignment: Alignment.center,
                imageAlignment: Alignment.center,
              ),
              reverse: false,
            ),
          ],
          onDone: () => _onIntroEnd(context),
          showSkipButton: true,
          skipOrBackFlex: 1,
          nextFlex: 1,
          showBackButton: false,
          back: Container(
            padding: AppDesignSystem.paddingS,
            decoration: BoxDecoration(
              color: colorScheme.tertiaryContainer,
              borderRadius: AppDesignSystem.borderRadiusM,
            ),
            child: Icon(
              Icons.arrow_back,
              color: colorScheme.onTertiaryContainer,
              size: 20,
            ),
          ),
          skip: Container(
            padding: AppDesignSystem.paddingSymmetric(
              horizontal: AppDesignSystem.spaceM,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: colorScheme.tertiaryContainer,
              borderRadius: AppDesignSystem.borderRadiusM,
            ),
            child: Text(
              'Skip',
              style: AppDesignSystem.labelLarge(context).copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onTertiaryContainer,
                letterSpacing: 0.3,
              ),
            ),
          ),
          next: Container(
            padding: AppDesignSystem.paddingS,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: AppDesignSystem.borderRadiusM,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_forward,
              color: colorScheme.onPrimary,
              size: 20,
            ),
          ),
          done: Container(
            padding: AppDesignSystem.paddingSymmetric(
              horizontal: AppDesignSystem.spaceM,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: AppDesignSystem.borderRadiusM,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              'Done',
              style: AppDesignSystem.labelLarge(context).copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onPrimary,
                letterSpacing: 0.3,
              ),
            ),
          ),
          curve: Curves.fastOutSlowIn,
          controlsMargin: AppDesignSystem.paddingOnly(
            bottom: AppDesignSystem.spaceL,
            left: AppDesignSystem.spaceL,
            right: AppDesignSystem.spaceL,
            top: AppDesignSystem.spaceS,
          ),
          controlsPadding: kIsWeb
              ? AppDesignSystem.paddingM
              : AppDesignSystem.paddingSymmetric(
                  horizontal: AppDesignSystem.spaceS,
                  vertical: AppDesignSystem.spaceS,
                ),
          dotsDecorator: DotsDecorator(
            size: const Size(8.0, 8.0),
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            activeSize: const Size(24.0, 8.0),
            activeShape: RoundedRectangleBorder(
              borderRadius: AppDesignSystem.borderRadiusM,
            ),
            activeColor: colorScheme.primary,
            spacing: const EdgeInsets.symmetric(horizontal: 6.0),
          ),
          dotsContainerDecorator: ShapeDecoration(
            color: colorScheme.surfaceContainer.withValues(alpha: 0.9),
            shape: RoundedRectangleBorder(
              borderRadius: AppDesignSystem.borderRadiusL,
              side: BorderSide(
                color: colorScheme.surface.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
            shadows: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
