import 'package:flutter/material.dart';
import 'package:freelance_app/utils/app_design_system.dart';

/// Modern Micro-Interactions Framework
/// Provides subtle but intentional animations and interactions for 2025 UI standards
class MicroInteractions {
  // ==================== ANIMATION DURATIONS ====================

  static const Duration instant = Duration(milliseconds: 0);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);

  // ==================== ANIMATION CURVES ====================

  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeOut = Curves.easeOut;
  static const Curve bounceOut = Curves.elasticOut;
  static const Curve sharp = Curves.fastOutSlowIn;

  // ==================== SCALE ANIMATIONS ====================

  /// Scale animation for interactive elements
  static Widget scaleOnTap({
    required Widget child,
    required VoidCallback onTap,
    double scaleFactor = 0.95,
    Duration duration = fast,
    Curve curve = easeOut,
  }) {
    return _ScaleOnTap(
      onTap: onTap,
      scaleFactor: scaleFactor,
      duration: duration,
      curve: curve,
      child: child,
    );
  }

  /// Scale animation for cards on hover/press
  static Widget scaleCard({
    required Widget child,
    VoidCallback? onTap,
    double scaleFactor = 0.98,
    Duration duration = fast,
    bool enabled = true,
  }) {
    if (!enabled) return child;

    return _ScaleCard(
      onTap: onTap,
      scaleFactor: scaleFactor,
      duration: duration,
      child: child,
    );
  }

  // ==================== FADE ANIMATIONS ====================

  /// Fade in animation for list items
  static Widget fadeInListItem({
    required Widget child,
    required int index,
    Duration delayPerItem = const Duration(milliseconds: 50),
    Duration duration = normal,
    Curve curve = easeOut,
    double startOpacity = 0.0,
    Offset? slideOffset,
  }) {
    return _FadeInListItem(
      index: index,
      delayPerItem: delayPerItem,
      duration: duration,
      curve: curve,
      startOpacity: startOpacity,
      slideOffset: slideOffset,
      child: child,
    );
  }

  /// Staggered fade in for entire lists
  static Widget staggeredFadeIn({
    required List<Widget> children,
    Duration delayPerItem = const Duration(milliseconds: 50),
    Duration itemDuration = normal,
    Curve curve = easeOut,
  }) {
    return _StaggeredFadeIn(
      delayPerItem: delayPerItem,
      itemDuration: itemDuration,
      curve: curve,
      children: children,
    );
  }

  // ==================== MORPHING ANIMATIONS ====================

  /// Smooth morphing between two states
  static Widget morphingContainer({
    required Widget child,
    required bool isActive,
    Duration duration = normal,
    Curve curve = easeInOut,
    double activeScale = 1.05,
    Color? activeColor,
    Color? inactiveColor,
  }) {
    return _MorphingContainer(
      isActive: isActive,
      duration: duration,
      curve: curve,
      activeScale: activeScale,
      activeColor: activeColor,
      inactiveColor: inactiveColor,
      child: child,
    );
  }

  // ==================== LOADING ANIMATIONS ====================

  /// Shimmer loading effect for modern UI
  static Widget shimmerBox({
    required double width,
    required double height,
    BorderRadius? borderRadius,
    EdgeInsets? margin,
  }) {
    return _ShimmerBox(
      width: width,
      height: height,
      borderRadius:
          borderRadius ?? BorderRadius.circular(AppDesignSystem.radiusM),
      margin: margin ?? EdgeInsets.zero,
    );
  }

  /// Pulsing animation for loading states
  static Widget pulsingWidget({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1500),
    double minOpacity = 0.3,
    double maxOpacity = 1.0,
  }) {
    return _PulsingWidget(
      duration: duration,
      minOpacity: minOpacity,
      maxOpacity: maxOpacity,
      child: child,
    );
  }

  // ==================== HERO ANIMATIONS ====================

  /// Modern hero transition wrapper
  static Widget heroWrapper({
    required String tag,
    required Widget child,
    CreateRectTween? createRectTween,
    HeroFlightShuttleBuilder? flightShuttleBuilder,
  }) {
    return Hero(
      tag: tag,
      createRectTween: createRectTween,
      flightShuttleBuilder: flightShuttleBuilder,
      child: child,
    );
  } // child is already last here

  // ==================== RIPPLE EFFECTS ====================

  /// Custom ripple effect for modern interactions
  static Widget modernRipple({
    required Widget child,
    required VoidCallback onTap,
    Color? splashColor,
    double? radius,
    BorderRadius? borderRadius,
  }) {
    return _ModernRipple(
      onTap: onTap,
      splashColor: splashColor,
      radius: radius,
      borderRadius: borderRadius,
      child: child,
    );
  }
}

// ==================== PRIVATE IMPLEMENTATIONS ====================

class _ScaleOnTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleFactor;
  final Duration duration;
  final Curve curve;

  const _ScaleOnTap({
    required this.child,
    required this.onTap,
    this.scaleFactor = 0.95,
    this.duration = MicroInteractions.fast,
    this.curve = MicroInteractions.easeOut,
  });

  @override
  State<_ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<_ScaleOnTap>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

class _ScaleCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;
  final Duration duration;

  const _ScaleCard({
    required this.child,
    this.onTap,
    this.scaleFactor = 0.98,
    this.duration = MicroInteractions.fast,
  });

  @override
  State<_ScaleCard> createState() => _ScaleCardState();
}

class _ScaleCardState extends State<_ScaleCard> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: MicroInteractions.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: widget.child,
            );
          },
        ),
      ),
    );
  }
}

class _FadeInListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delayPerItem;
  final Duration duration;
  final Curve curve;
  final double startOpacity;
  final Offset? slideOffset;

  const _FadeInListItem({
    required this.child,
    required this.index,
    this.delayPerItem = const Duration(milliseconds: 50),
    this.duration = MicroInteractions.normal,
    this.curve = MicroInteractions.easeOut,
    this.startOpacity = 0.0,
    this.slideOffset,
  });

  @override
  State<_FadeInListItem> createState() => _FadeInListItemState();
}

class _FadeInListItemState extends State<_FadeInListItem>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _opacityAnimation = Tween<double>(
      begin: widget.startOpacity,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _slideAnimation = Tween<Offset>(
      begin: widget.slideOffset ?? Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    // Start animation with delay
    Future.delayed(widget.delayPerItem * widget.index, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: SlideTransition(
            position: _slideAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }
}

class _StaggeredFadeIn extends StatelessWidget {
  final List<Widget> children;
  final Duration delayPerItem;
  final Duration itemDuration;
  final Curve curve;

  const _StaggeredFadeIn({
    required this.children,
    this.delayPerItem = const Duration(milliseconds: 50),
    this.itemDuration = MicroInteractions.normal,
    this.curve = MicroInteractions.easeOut,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: children.asMap().entries.map((entry) {
        return MicroInteractions.fadeInListItem(
          child: entry.value,
          index: entry.key,
          delayPerItem: delayPerItem,
          duration: itemDuration,
          curve: curve,
        );
      }).toList(),
    );
  }
}

class _MorphingContainer extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final Duration duration;
  final Curve curve;
  final double activeScale;
  final Color? activeColor;
  final Color? inactiveColor;

  const _MorphingContainer({
    required this.child,
    required this.isActive,
    this.duration = MicroInteractions.normal,
    this.curve = MicroInteractions.easeInOut,
    this.activeScale = 1.05,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<_MorphingContainer> createState() => _MorphingContainerState();
}

class _MorphingContainerState extends State<_MorphingContainer>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.activeScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _colorAnimation = ColorTween(
      begin: widget.inactiveColor,
      end: widget.activeColor,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _updateAnimation();
  }

  @override
  void didUpdateWidget(_MorphingContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    if (widget.isActive) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            color: _colorAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final EdgeInsets margin;

  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.margin,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment(_animation.value, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

class _PulsingWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minOpacity;
  final double maxOpacity;

  const _PulsingWidget({
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.minOpacity = 0.3,
    this.maxOpacity = 1.0,
  });

  @override
  State<_PulsingWidget> createState() => _PulsingWidgetState();
}

class _PulsingWidgetState extends State<_PulsingWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: widget.minOpacity,
      end: widget.maxOpacity,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

class _ModernRipple extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color? splashColor;
  final double? radius;
  final BorderRadius? borderRadius;

  const _ModernRipple({
    required this.child,
    required this.onTap,
    this.splashColor,
    this.radius,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        splashColor: splashColor ??
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        highlightColor: splashColor ??
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
        radius: radius,
        child: child,
      ),
    );
  }
}
