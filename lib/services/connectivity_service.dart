import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Service to check and monitor network connectivity
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  Stream<bool> get connectionStatus => _connectionStatusController.stream;
  bool _isConnected = true;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    // Check initial connectivity
    final results = await _connectivity.checkConnectivity();
    if (results.isNotEmpty) {
      _updateConnectionStatus(results.first);
    }

    // Listen to connectivity changes
    _connectivity.onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      if (results.isNotEmpty) {
        _updateConnectionStatus(results.first);
      }
    });
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    final wasConnected = _isConnected;
    _isConnected = result != ConnectivityResult.none;

    if (wasConnected != _isConnected) {
      _connectionStatusController.add(_isConnected);
    }
  }

  /// Check if device is currently connected
  Future<bool> isConnected() async {
    final results = await _connectivity.checkConnectivity();
    return results.isNotEmpty && results.first != ConnectivityResult.none;
  }

  /// Get current connection status
  bool get currentStatus => _isConnected;

  /// Dispose resources
  void dispose() {
    _connectionStatusController.close();
  }
}

/// Widget to show connectivity status banner
class ConnectivityBanner extends StatefulWidget {
  final Widget child;

  const ConnectivityBanner({super.key, required this.child});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner>
    with SingleTickerProviderStateMixin {
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _isConnected = true;
  bool _showBanner = false;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _connectivityService.initialize();
    _connectivityService.connectionStatus.listen((isConnected) {
      if (mounted) {
        final wasConnected = _isConnected;

        setState(() {
          _isConnected = isConnected;
          // Show when offline, and briefly when transitioning back online.
          _showBanner = !isConnected || (!wasConnected && isConnected);
        });

        if (!isConnected) {
          _animationController.forward();
        } else if (!wasConnected && isConnected) {
          _animationController.forward();
          // Show reconnected message briefly
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              _animationController.reverse();
              setState(() => _showBanner = false);
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final containerColor = _isConnected
        ? colorScheme.tertiaryContainer
        : colorScheme.error;
    final foregroundColor = _isConnected
        ? colorScheme.onTertiaryContainer
        : colorScheme.onError;

    return Stack(
      children: [
        widget.child,
        if (_showBanner)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _slideAnimation,
              child: Material(
                color: containerColor,
                elevation: 1,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    child: Row(
                      children: [
                        Icon(
                          _isConnected ? Icons.wifi : Icons.wifi_off,
                          color: foregroundColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _isConnected
                                ? 'Back online! You\'re connected to the internet.'
                                : 'No internet connection. Please check your network.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: foregroundColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Mixin to check connectivity before actions
mixin ConnectivityAware {
  final ConnectivityService _connectivityService = ConnectivityService();

  /// Check if connected and show message if not
  Future<bool> checkConnectivity(BuildContext context,
      {String? message}) async {
    final isConnected = await _connectivityService.isConnected();

    if (!isConnected && context.mounted) {
      final colorScheme = Theme.of(context).colorScheme;
      final textTheme = Theme.of(context).textTheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi_off, color: colorScheme.onError),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message ??
                      'No internet connection. Please check your network and try again.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onError,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: colorScheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            textColor: colorScheme.onError,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }

    return isConnected;
  }

  /// Execute action only if connected
  Future<T?> executeIfConnected<T>(
    BuildContext context,
    Future<T> Function() action, {
    String? offlineMessage,
  }) async {
    if (await checkConnectivity(context, message: offlineMessage)) {
      return await action();
    }
    return null;
  }
}
