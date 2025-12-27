import 'package:flutter/material.dart';

/// Plugin Model for dynamic plugin configuration
class PluginModel {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route; // Screen route or identifier
  final bool isEnabled;
  final List<String> allowedRoles; // Empty = all roles, or specific roles
  final int order; // Display order

  const PluginModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
    this.isEnabled = true,
    this.allowedRoles = const [],
    this.order = 0,
  });

  factory PluginModel.fromMap(Map<String, dynamic> map, String id) {
    // Map icon string to IconData
    IconData iconData = Icons.extension;
    final iconString = map['icon'] as String? ?? '';
    try {
      iconData = _iconFromString(iconString);
    } catch (e) {
      // Use default icon
    }

    // Map color string to Color
    Color color = const Color(0xFF4461AD); // Default botsBlue
    final colorString = map['color'] as String? ?? '';
    try {
      if (colorString.isNotEmpty) {
        color = Color(int.parse(colorString.replaceFirst('#', '0xFF')));
      }
    } catch (e) {
      // Use default color
    }

    return PluginModel(
      id: id,
      title: map['title'] as String? ?? '',
      subtitle: map['subtitle'] as String? ?? '',
      icon: iconData,
      color: color,
      route: map['route'] as String? ?? '',
      isEnabled: map['isEnabled'] as bool? ?? true,
      allowedRoles: (map['allowedRoles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      order: _validatePluginOrder(map['order']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'icon': _iconToString(icon),
      'color': '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
      'route': route,
      'isEnabled': isEnabled,
      'allowedRoles': allowedRoles,
      'order': order,
    };
  }

  static IconData _iconFromString(String iconString) {
    // Map common icon strings to IconData
    switch (iconString.toLowerCase()) {
      case 'work_outline':
        return Icons.work_outline;
      case 'video_library':
        return Icons.video_library;
      case 'flash_on':
        return Icons.flash_on;
      case 'description':
        return Icons.description;
      case 'school':
        return Icons.school;
      case 'newspaper':
        return Icons.newspaper;
      case 'business_center':
        return Icons.business_center;
      default:
        return Icons.extension;
    }
  }

  static String _iconToString(IconData icon) {
    // Convert IconData to string (simplified mapping)
    if (icon == Icons.work_outline) return 'work_outline';
    if (icon == Icons.video_library) return 'video_library';
    if (icon == Icons.flash_on) return 'flash_on';
    if (icon == Icons.description) return 'description';
    if (icon == Icons.school) return 'school';
    if (icon == Icons.newspaper) return 'newspaper';
    if (icon == Icons.business_center) return 'business_center';
    return 'extension';
  }

  /// Check if plugin is accessible for a given role
  bool isAccessibleForRole(String? userRole) {
    if (!isEnabled) return false;
    if (allowedRoles.isEmpty) return true; // Available to all
    if (userRole == null) return false;
    return allowedRoles.contains(userRole.toLowerCase());
  }
}

/// Helper method to validate plugin order
int _validatePluginOrder(dynamic rawOrder) {
  try {
    final order = (rawOrder as num?)?.toInt();
    if (order == null) {
      throw Exception('Plugin order is missing');
    }
    if (order < 0) {
      throw Exception('Invalid order value: $order');
    }
    return order;
  } catch (e) {
    debugPrint('❌ ERROR: Failed to parse plugin order: $e');
    rethrow;
  }
}

