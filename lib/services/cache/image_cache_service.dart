import 'package:flutter/material.dart';

/// Unified Image Caching Service
/// Provides memory caching for network images using Flutter's built-in image cache
/// 
/// Usage:
/// ```dart
/// final provider = ImageCacheService().getCachedImageProvider(imageUrl);
/// Image(image: provider)
/// ```
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  /// Get network image provider
  /// Uses Flutter's built-in image cache (memory only)
  ImageProvider getCachedImageProvider(
    String imageUrl, {
    Duration maxAge = const Duration(days: 7),
    VoidCallback? onError,
  }) {
    if (imageUrl.isEmpty) {
      throw ArgumentError('imageUrl cannot be empty');
    }

    debugPrint('📥 [Image Cache] Loading: $imageUrl');
    return NetworkImage(imageUrl);
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    final cache = imageCache;
    return {
      'currentSize': cache.currentSize,
      'maxSize': cache.maximumSize,
      'count': cache.statusForKey(NetworkImage('')).pending ? 0 : 1,
    };
  }

  /// Clear all cached images
  Future<void> clearAll() async {
    imageCache.clear();
    imageCache.clearLiveImages();
    debugPrint('🗑️ [Image Cache] Cleared all images');
  }

  /// Clear specific image from cache
  Future<void> clearImage(String imageUrl) async {
    imageCache.evict(NetworkImage(imageUrl));
    debugPrint('🗑️ [Image Cache] Cleared: $imageUrl');
  }

  /// Precache image
  Future<void> precache(String imageUrl, BuildContext context) async {
    await precacheImage(
      NetworkImage(imageUrl),
      context,
    );
    debugPrint('✅ [Image Cache] Precached: $imageUrl');
  }
}
