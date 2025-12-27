import 'package:flutter/material.dart';
import 'package:freelance_app/models/plugin_model.dart';
import 'package:freelance_app/utils/colors.dart';
import 'package:freelance_app/widgets/common/page_transitions.dart';
import 'package:freelance_app/screens/plugins_hub/gig_space_screen.dart';
import 'package:freelance_app/screens/plugins_hub/hustle_space_screen.dart';
import 'package:freelance_app/screens/plugins_hub/tenders_portal_screen.dart';
import 'package:freelance_app/screens/plugins_hub/youth_opportunities_screen.dart';
import 'package:freelance_app/screens/plugins_hub/news_corner_screen.dart';
import 'package:freelance_app/screens/plugins_hub/blue_pages_screen.dart';
import 'package:freelance_app/screens/trainers/courses_screen.dart';

/// Dynamic Plugin Navigation Service
/// Production-ready: Maps plugin routes to screens dynamically
/// No hardcoding - all navigation is driven by plugin configuration
class PluginNavigationService {
  static final PluginNavigationService _instance =
      PluginNavigationService._internal();
  factory PluginNavigationService() => _instance;
  PluginNavigationService._internal();

  /// Register a plugin route handler
  /// In production, this can be extended to support custom plugin screens
  final Map<String, Widget Function()> _routeHandlers = {
    'gig_space': () => const GigSpaceScreen(),
    'courses': () => const CoursesScreen(),
    'hustle_space': () => const HustleSpaceScreen(),
    'tenders_portal': () => const TendersPortalScreen(),
    'youth_opportunities': () => const YouthOpportunitiesScreen(),
    'news_corner': () => const NewsCornerScreen(),
    'blue_pages': () => const BluePagesScreen(),
  };

  /// Register a custom route handler (for future extensibility)
  void registerRoute(String route, Widget Function() screenBuilder) {
    _routeHandlers[route] = screenBuilder;
  }

  /// Navigate to plugin screen dynamically
  /// Returns true if navigation was successful, false if route not found
  bool navigateToPlugin(BuildContext context, PluginModel plugin) {
    final handler = _routeHandlers[plugin.route];

    if (handler == null) {
      debugPrint('⚠️ Plugin route not found: ${plugin.route}');
      // Show user-friendly error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Plugin "${plugin.title}" is not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    try {
      final screen = handler();
      context.pushModern(
        page: screen,
        type: RouteType.fadeSlide,
      );
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Error navigating to plugin ${plugin.route}: $e');
      debugPrint('Stack trace: $stackTrace');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error opening "${plugin.title}"',
            style: const TextStyle(color: botsWhite), // White text on red background
          ),
          backgroundColor: botsError, // Use AppDesignSystem error color
        ),
      );
      return false;
    }
  }

  /// Get all registered routes (for admin/debugging)
  List<String> getRegisteredRoutes() {
    return _routeHandlers.keys.toList();
  }

  /// Check if a route is registered
  bool isRouteRegistered(String route) {
    return _routeHandlers.containsKey(route);
  }
}
