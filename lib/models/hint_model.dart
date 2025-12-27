/// Model for a hint/tooltip to show users
class HintModel {
  final String id;
  final String title;
  final String message;
  final String? screenId; // Which screen this hint belongs to
  final String? targetElementId; // Optional: specific element to highlight
  final HintType type;
  final bool requiresMonetization; // Only show if monetization is enabled
  final int priority; // Higher priority hints shown first
  final Duration? autoDismissDuration; // Auto-dismiss after duration

  const HintModel({
    required this.id,
    required this.title,
    required this.message,
    this.screenId,
    this.targetElementId,
    this.type = HintType.info,
    this.requiresMonetization = false,
    this.priority = 0,
    this.autoDismissDuration,
  });
}

enum HintType {
  info, // General information
  tip, // Helpful tip
  feature, // Feature discovery
  monetization, // Monetization-related
  warning, // Important warning
  ai, // AI-generated smart hint
}

