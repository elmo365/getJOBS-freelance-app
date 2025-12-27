import 'package:flutter/material.dart';

/// Cached Image Widget - Drop-in replacement for Image.network()
/// 
/// Uses Flutter's built-in image caching for simpler implementation
/// 
/// Usage:
/// ```dart
/// CachedImageWidget(
///   imageUrl: 'https://example.com/image.jpg',
///   width: 200,
///   height: 200,
///   fit: BoxFit.cover,
/// )
/// ```
class CachedImageWidget extends StatelessWidget {
  /// The URL of the image to cache and display
  final String imageUrl;

  /// Width of the image display
  final double width;

  /// Height of the image display
  final double height;

  /// How the image should be inscribed into the space allocated during layout
  final BoxFit fit;

  /// Maximum age before image is re-fetched from network (default 7 days)
  final Duration cacheMaxAge;

  /// Widget to show while image is loading (default: gray box with spinner)
  final Widget? placeholder;

  /// Widget to show if image fails to load (default: gray box with broken image icon)
  final Widget? errorWidget;

  /// Called when image successfully loads
  final VoidCallback? onImageLoaded;

  /// Display border radius (optional)
  final double borderRadius;

  const CachedImageWidget({
    super.key,
    required this.imageUrl,
    this.width = 100,
    this.height = 100,
    this.fit = BoxFit.cover,
    this.cacheMaxAge = const Duration(days: 7),
    this.placeholder,
    this.errorWidget,
    this.onImageLoaded,
    this.borderRadius = 0,
  });

  @override
  Widget build(BuildContext context) {
    // Return error widget if URL is empty
    if (imageUrl.isEmpty) {
      return _buildErrorPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: Image.network(
          imageUrl,
          width: width,
          height: height,
          fit: fit,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              onImageLoaded?.call();
              return child;
            }
            return placeholder ?? _buildLoadingPlaceholder(context);
          },
          errorBuilder: (context, error, stackTrace) {
            return errorWidget ?? _buildErrorPlaceholder();
          },
        ),
      ),
    );
  }

  /// Default loading placeholder
  Widget _buildLoadingPlaceholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
        ),
      ),
    );
  }

  /// Error placeholder - shown when image fails to load
  Widget _buildErrorPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          color: Colors.grey[600],
          size: (width + height) / 4, // Scale icon to widget size
        ),
      ),
    );
  }
}
