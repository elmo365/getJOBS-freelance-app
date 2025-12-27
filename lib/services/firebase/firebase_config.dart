import 'package:firebase_core/firebase_core.dart';

/// Firebase configuration and initialization
class FirebaseConfig {
  static bool _initialized = false;

  /// Initialize Firebase
  static Future<void> initialize() async {
    if (_initialized) return;

    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyCtSf5A-1sbBd0XZrfqvmI-dm1xuCRN-VA',
        appId: '1:290457853042:android:a0a95e052fd97120ddb6eb',
        messagingSenderId: '290457853042',
        projectId: 'jobs-f240f',
        storageBucket: 'jobs-f240f.firebasestorage.app',
      ),
    );

    _initialized = true;
  }

  /// Check if Firebase is initialized
  static bool isInitialized() => _initialized;

  /// Collection names
  static const String usersCollection = 'users';
  static const String jobsCollection = 'jobs';
  static const String applicationsCollection = 'applications';
  static const String interviewsCollection = 'interviews';
  static const String commentsCollection = 'comments';

  /// Storage paths
  static const String cvsPath = 'cvs';
  static const String videoResumesPath = 'video_resumes';
  static const String profileImagesPath = 'profile_images';
  static const String companyLogosPath = 'company_logos';

  /// Company KYC document uploads
  static const String companyKycDocsPath = 'company_kyc_docs';
}

