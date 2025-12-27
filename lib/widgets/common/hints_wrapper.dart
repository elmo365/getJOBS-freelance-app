import 'package:flutter/material.dart';

/// Wrapper widget that provides infrastructure for screen hints.
/// 
/// Previously displayed banner hints at the top of the screen.
/// Now simplified to support AI-powered tooltips integrated into
/// individual form fields via AIHintTooltip and InputFieldWithHint.
/// 
/// Usage: Wrap your screen's body with HintsWrapper (no functional change to layout)
class HintsWrapper extends StatelessWidget {
  final Widget child;
  final String screenId;
  final bool showHints;

  const HintsWrapper({
    super.key,
    required this.child,
    required this.screenId,
    this.showHints = true,
  });

  @override
  Widget build(BuildContext context) {
    // AI-powered tooltips are now integrated directly into form fields
    // via AIHintTooltip and InputFieldWithHint. No banner display needed.
    return child;
  }
}
