import 'package:flutter/material.dart';
import 'package:freelance_app/widgets/common/micro_interactions.dart';

/// Modern Page Transitions for 2025 UI Standards
/// Provides smooth, consistent navigation transitions across the app
class ModernPageTransitions {
  /// Standard page transition with fade and slide
  static PageRouteBuilder<T> fadeSlideTransition<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = const Duration(milliseconds: 300),
    Offset beginOffset = const Offset(0.0, 0.1),
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: MicroInteractions.easeOut,
        ));

        final slideAnimation = Tween<Offset>(
          begin: beginOffset,
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: MicroInteractions.easeOut,
        ));

        final secondaryFadeAnimation = Tween<double>(
          begin: 1.0,
          end: 0.8,
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeInOut,
        ));

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: FadeTransition(
              opacity: secondaryFadeAnimation,
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// Hero-style transition for detailed views
  static PageRouteBuilder<T> heroTransition<T>({
    required Widget page,
    required String heroTag,
    RouteSettings? settings,
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleAnimation = Tween<double>(
          begin: 0.8,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: MicroInteractions.bounceOut,
        ));

        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: MicroInteractions.easeOut,
        ));

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
    );
  }

  /// Modal transition for dialogs and overlays
  static PageRouteBuilder<T> modalTransition<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = const Duration(milliseconds: 250),
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleAnimation = Tween<double>(
          begin: 0.8,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: MicroInteractions.bounceOut,
        ));

        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: MicroInteractions.easeOut,
        ));

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
    );
  }

  /// Slide transition for navigation between related screens
  static PageRouteBuilder<T> slideTransition<T>({
    required Widget page,
    required Offset direction,
    RouteSettings? settings,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideAnimation = Tween<Offset>(
          begin: direction,
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: MicroInteractions.easeOut,
        ));

        final secondarySlideAnimation = Tween<Offset>(
          begin: Offset.zero,
          end: -direction,
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: MicroInteractions.easeInOut,
        ));

        return SlideTransition(
          position: slideAnimation,
          child: SlideTransition(
            position: secondarySlideAnimation,
            child: child,
          ),
        );
      },
    );
  }

  /// Factory method for creating transitions based on route type
  static Route<T> createRoute<T>({
    required Widget page,
    required RouteType type,
    RouteSettings? settings,
    String? heroTag,
    Offset? slideDirection,
  }) {
    switch (type) {
      case RouteType.fadeSlide:
        return fadeSlideTransition(
          page: page,
          settings: settings,
        );
      case RouteType.hero:
        return heroTransition(
          page: page,
          heroTag: heroTag ?? '',
          settings: settings,
        );
      case RouteType.modal:
        return modalTransition(
          page: page,
          settings: settings,
        );
      case RouteType.slideLeft:
        return slideTransition(
          page: page,
          direction: slideDirection ?? const Offset(1.0, 0.0),
          settings: settings,
        );
      case RouteType.slideRight:
        return slideTransition(
          page: page,
          direction: slideDirection ?? const Offset(-1.0, 0.0),
          settings: settings,
        );
      case RouteType.slideUp:
        return slideTransition(
          page: page,
          direction: slideDirection ?? const Offset(0.0, 1.0),
          settings: settings,
        );
      case RouteType.slideDown:
        return slideTransition(
          page: page,
          direction: slideDirection ?? const Offset(0.0, -1.0),
          settings: settings,
        );
    }
  }
}

/// Route types for consistent navigation patterns
enum RouteType {
  /// Standard fade and slide transition
  fadeSlide,

  /// Hero-style transition for detailed views
  hero,

  /// Modal transition for dialogs
  modal,

  /// Slide from right (forward navigation)
  slideLeft,

  /// Slide from left (back navigation)
  slideRight,

  /// Slide from bottom (modal-like)
  slideUp,

  /// Slide from top (rarely used)
  slideDown,
}

/// Extension for easy navigation with modern transitions
extension ModernNavigator on BuildContext {
  /// Navigate to a new screen with modern transitions
  Future<T?> pushModern<T>({
    required Widget page,
    RouteType type = RouteType.fadeSlide,
    String? heroTag,
    Offset? slideDirection,
  }) {
    final route = ModernPageTransitions.createRoute(
      page: page,
      type: type,
      heroTag: heroTag,
      slideDirection: slideDirection,
    );
    return Navigator.of(this).push<T>(route as Route<T>);
  }

  /// Replace current screen with modern transitions
  Future<T?> pushReplacementModern<T, TO>({
    required Widget page,
    RouteType type = RouteType.fadeSlide,
    String? heroTag,
    Offset? slideDirection,
  }) {
    final route = ModernPageTransitions.createRoute(
      page: page,
      type: type,
      heroTag: heroTag,
      slideDirection: slideDirection,
    );
    return Navigator.of(this).pushReplacement<T, TO>(route as Route<T>);
  }
}
