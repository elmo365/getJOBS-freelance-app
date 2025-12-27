import 'dart:io';
import 'config/user_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/admin/admin_login_screen.dart' as admin_login;
import 'screens/user/login_screen.dart' as user_login;
import 'screens/chat/chat_list_screen.dart';
import 'utils/app_theme.dart';
import 'widgets/common/page_transitions.dart';
import 'services/firebase/firebase_config.dart';
import 'services/connectivity_service.dart';
import 'services/notifications/notification_service.dart';
import 'services/ai/gemini_ai_service.dart';
import 'services/android_compat_service.dart';
import 'utils/admin_setup.dart';
import 'screens/search/search_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Performance optimization: Enable timeline for development
  // FlutterError.onError = (FlutterErrorDetails details) {
  //   FlutterError.dumpErrorToConsole(details);
  // };

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Firebase
  await FirebaseConfig.initialize();

  // Initialize Connectivity Service
  await ConnectivityService().initialize();

  // Initialize Notification Service
  await NotificationService().initialize();

  // Initialize Gemini AI Service
  await GeminiAIService().initialize();

  // Android Compatibility & Permissions
  final androidCompat = AndroidCompatService();
  await androidCompat.checkNotificationPermission();
  
  // Log GMS Availability for troubleshooting
  final isGmsAvailable = await androidCompat.isGmsAvailable();
  if (!isGmsAvailable && Platform.isAndroid) {
    debugPrint('⚠️ GMS not available. Some features (Firebase) might be limited.');
  }

  // Initialize default admin user
  await AdminSetup.initializeDefaultAdmin();

  // Set background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of the application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bots Jobs Connect',
      theme: AppTheme.getTheme(),
      // Performance optimizations
      showPerformanceOverlay: false, // Set to true for performance debugging
      checkerboardOffscreenLayers: false, // Disable for production
      checkerboardRasterCacheImages: false, // Disable for production
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return ModernPageTransitions.fadeSlideTransition(
              page: const user_login.LoginScreen(),
              settings: settings,
            );
          case '/admin/login':
            return ModernPageTransitions.fadeSlideTransition(
              page: const admin_login.AdminLoginScreen(),
              settings: settings,
            );
          case '/chat':
            return ModernPageTransitions.fadeSlideTransition(
              page: const ChatListScreen(),
              settings: settings,
            );
          case '/search':
            return ModernPageTransitions.fadeSlideTransition(
              page: const Search(),
              settings: settings,
            );
          default:
            return ModernPageTransitions.fadeSlideTransition(
              page: const ConnectivityBanner(child: UserState()),
              settings: settings,
            );
        }
      },
      home: const ConnectivityBanner(
        child: UserState(),
      ),
    );
  }
}
