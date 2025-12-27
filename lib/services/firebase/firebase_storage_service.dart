import 'dart:io' as io;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'firebase_config.dart';

/// Firebase Storage Service
/// Handles all file upload and download operations
class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ==================== COMPANY KYC DOCUMENTS ====================

  /// Upload a company verification/KYC document (PDF/DOC/DOCX)
  /// Stored under: company_kyc_docs/{companyId}/{docType}_{timestamp}.{ext}
  Future<String> uploadCompanyKycDocument({
    required String filePath,
    required String companyId,
    required String docType,
    Function(double)? onProgress,
  }) async {
    try {
      final file = io.File(filePath);
      final extension = path.extension(filePath).toLowerCase();
      final normalizedExtension = extension.isEmpty ? '.pdf' : extension;

      final contentType = switch (normalizedExtension) {
        '.pdf' => 'application/pdf',
        '.doc' => 'application/msword',
        '.docx' =>
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        _ => 'application/octet-stream',
      };

      final ts = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${docType}_$ts$normalizedExtension';
      final ref = _storage
          .ref()
          .child('${FirebaseConfig.companyKycDocsPath}/$companyId/$fileName');

      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: contentType),
      );

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (onProgress != null) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        }
      });

      await uploadTask;
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw _handleException(e);
    }
  }

  Future<String> _getFirstDownloadUrl(List<String> fullPaths) async {
    FirebaseException? lastNotFound;

    for (final filePath in fullPaths) {
      try {
        final ref = _storage.ref().child(filePath);
        return await ref.getDownloadURL();
      } on FirebaseException catch (e) {
        if (e.code == 'object-not-found') {
          lastNotFound = e;
          continue;
        }
        throw _handleException(e);
      }
    }

    if (lastNotFound != null) {
      throw _handleException(lastNotFound);
    }
    throw 'File not found.';
  }

  Future<void> _deleteFirstExisting(List<String> fullPaths) async {
    FirebaseException? lastNotFound;

    for (final filePath in fullPaths) {
      try {
        final ref = _storage.ref().child(filePath);
        await ref.delete();
        return;
      } on FirebaseException catch (e) {
        if (e.code == 'object-not-found') {
          lastNotFound = e;
          continue;
        }
        throw _handleException(e);
      }
    }

    if (lastNotFound != null) {
      throw _handleException(lastNotFound);
    }
    throw 'File not found.';
  }

  // ==================== CV FILES ====================

  /// Upload CV file (PDF, DOC, DOCX)
  Future<String> uploadCV({
    required String filePath,
    required String userId,
    Function(double)? onProgress,
  }) async {
    try {
      final file = io.File(filePath);
      final extension = path.extension(filePath).toLowerCase();
      final normalizedExtension = extension.isEmpty ? '.pdf' : extension;

      final contentType = switch (normalizedExtension) {
        '.pdf' => 'application/pdf',
        '.doc' => 'application/msword',
        '.docx' =>
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        _ => 'application/octet-stream',
      };

      final fileName = 'CV_$userId$normalizedExtension';
      final ref = _storage
          .ref()
          .child('${FirebaseConfig.cvsPath}/$userId/$fileName');

      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: contentType),
      );

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (onProgress != null) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        }
      });

      await uploadTask;
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw _handleException(e);
    }
  }

  /// Get CV file URL
  Future<String> getCVUrl(String userId) async {
    try {
      return await _getFirstDownloadUrl([
        '${FirebaseConfig.cvsPath}/$userId/CV_$userId.pdf',
        '${FirebaseConfig.cvsPath}/$userId/CV_$userId.doc',
        '${FirebaseConfig.cvsPath}/$userId/CV_$userId.docx',
      ]);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete CV file
  Future<void> deleteCV(String userId) async {
    try {
      await _deleteFirstExisting([
        '${FirebaseConfig.cvsPath}/$userId/CV_$userId.pdf',
        '${FirebaseConfig.cvsPath}/$userId/CV_$userId.doc',
        '${FirebaseConfig.cvsPath}/$userId/CV_$userId.docx',
      ]);
    } catch (e) {
      rethrow;
    }
  }

  // ==================== VIDEO RESUME FILES ====================

  /// Upload video resume (MP4, MOV, AVI)
  Future<String> uploadVideoResume({
    required String filePath,
    required String userId,
    Function(double)? onProgress,
  }) async {
    try {
      final file = io.File(filePath);
      final extension = path.extension(filePath).toLowerCase();
      // Normalize to mp4 when unknown for best compatibility
      final normalizedExtension =
          (extension == '.mp4' || extension == '.mov' || extension == '.avi')
              ? extension
              : '.mp4';
      final fileName = 'VideoResume_$userId$normalizedExtension';
      final ref = _storage
          .ref()
          .child('${FirebaseConfig.videoResumesPath}/$userId/$fileName');

      final contentType = switch (normalizedExtension) {
        '.mp4' => 'video/mp4',
        '.mov' => 'video/quicktime',
        '.avi' => 'video/x-msvideo',
        _ => 'video/mp4',
      };

      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: contentType),
      );

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (onProgress != null) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        }
      });

      await uploadTask;
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw _handleException(e);
    }
  }

  /// Get video resume URL
  Future<String> getVideoResumeUrl(String userId) async {
    try {
      return await _getFirstDownloadUrl([
        '${FirebaseConfig.videoResumesPath}/$userId/VideoResume_$userId.mp4',
        '${FirebaseConfig.videoResumesPath}/$userId/VideoResume_$userId.mov',
        '${FirebaseConfig.videoResumesPath}/$userId/VideoResume_$userId.avi',
      ]);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete video resume
  Future<void> deleteVideoResume(String userId) async {
    try {
      await _deleteFirstExisting([
        '${FirebaseConfig.videoResumesPath}/$userId/VideoResume_$userId.mp4',
        '${FirebaseConfig.videoResumesPath}/$userId/VideoResume_$userId.mov',
        '${FirebaseConfig.videoResumesPath}/$userId/VideoResume_$userId.avi',
      ]);
    } catch (e) {
      rethrow;
    }
  }

  // ==================== PROFILE IMAGES ====================

  /// Upload profile image (JPG, PNG, WEBP)
  Future<String> uploadProfileImage({
    required String filePath,
    required String userId,
    Function(double)? onProgress,
  }) async {
    try {
      // Validate file exists before uploading
      final file = io.File(filePath);
      if (!await file.exists()) {
        throw Exception('Image file does not exist at path: $filePath');
      }

      // Check file size (max 10MB)
      final fileSize = await file.length();
      const maxSize = 10 * 1024 * 1024; // 10MB
      if (fileSize > maxSize) {
        throw Exception('Image file is too large. Maximum size is 10MB.');
      }

      final extension = path.extension(filePath).toLowerCase();
      final normalizedExtension = switch (extension) {
        '.jpg' || '.jpeg' => '.jpg',
        '.png' => '.png',
        '.webp' => '.webp',
        _ => '.jpg',
      };

      final contentType = switch (normalizedExtension) {
        '.png' => 'image/png',
        '.webp' => 'image/webp',
        _ => 'image/jpeg',
      };

      final fileName = 'Profile_$userId$normalizedExtension';
      final ref = _storage
          .ref()
          .child('${FirebaseConfig.profileImagesPath}/$userId/$fileName');

      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: contentType, cacheControl: 'public,max-age=3600'),
      );

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (onProgress != null) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        }
      });

      await uploadTask;
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw _handleException(e);
    } catch (e) {
      rethrow;
    }
  }

  /// Get profile image URL
  Future<String> getProfileImageUrl(String userId) async {
    try {
      return await _getFirstDownloadUrl([
        '${FirebaseConfig.profileImagesPath}/$userId/Profile_$userId.jpg',
        '${FirebaseConfig.profileImagesPath}/$userId/Profile_$userId.png',
        '${FirebaseConfig.profileImagesPath}/$userId/Profile_$userId.webp',
      ]);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete profile image
  Future<void> deleteProfileImage(String userId) async {
    try {
      await _deleteFirstExisting([
        '${FirebaseConfig.profileImagesPath}/$userId/Profile_$userId.jpg',
        '${FirebaseConfig.profileImagesPath}/$userId/Profile_$userId.png',
        '${FirebaseConfig.profileImagesPath}/$userId/Profile_$userId.webp',
      ]);
    } catch (e) {
      rethrow;
    }
  }

  // ==================== COMPANY LOGOS ====================

  /// Upload company logo (JPG, PNG, SVG)
  Future<String> uploadCompanyLogo({
    required String filePath,
    required String companyId,
    Function(double)? onProgress,
  }) async {
    try {
      final file = io.File(filePath);
      final extension = path.extension(filePath).toLowerCase();
      final normalizedExtension = switch (extension) {
        '.jpg' || '.jpeg' => '.jpg',
        '.png' => '.png',
        '.webp' => '.webp',
        _ => '.png',
      };

      final contentType = switch (normalizedExtension) {
        '.jpg' => 'image/jpeg',
        '.webp' => 'image/webp',
        _ => 'image/png',
      };

      final fileName = 'Logo_$companyId$normalizedExtension';
      final ref = _storage
          .ref()
          .child('${FirebaseConfig.companyLogosPath}/$companyId/$fileName');

      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: contentType, cacheControl: 'public,max-age=3600'),
      );

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (onProgress != null) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        }
      });

      await uploadTask;
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw _handleException(e);
    }
  }

  /// Get company logo URL
  Future<String> getCompanyLogoUrl(String companyId) async {
    try {
      return await _getFirstDownloadUrl([
        '${FirebaseConfig.companyLogosPath}/$companyId/Logo_$companyId.png',
        '${FirebaseConfig.companyLogosPath}/$companyId/Logo_$companyId.jpg',
        '${FirebaseConfig.companyLogosPath}/$companyId/Logo_$companyId.webp',
      ]);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete company logo
  Future<void> deleteCompanyLogo(String companyId) async {
    try {
      await _deleteFirstExisting([
        '${FirebaseConfig.companyLogosPath}/$companyId/Logo_$companyId.png',
        '${FirebaseConfig.companyLogosPath}/$companyId/Logo_$companyId.jpg',
        '${FirebaseConfig.companyLogosPath}/$companyId/Logo_$companyId.webp',
      ]);
    } catch (e) {
      rethrow;
    }
  }

  // ==================== GENERAL FILE OPERATIONS ====================

  /// Check if file exists
  Future<bool> fileExists(String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.getDownloadURL();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get file download URL
  Future<String> getFileUrl(String path) async {
    try {
      final ref = _storage.ref().child(path);
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw _handleException(e);
    }
  }

  /// Delete file
  Future<void> deleteFile(String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.delete();
    } on FirebaseException catch (e) {
      throw _handleException(e);
    }
  }

  // ==================== ERROR HANDLING ====================

  /// Handle Firebase Storage exceptions
  String _handleException(FirebaseException e) {
    switch (e.code) {
      case 'object-not-found':
        return 'File not found.';
      case 'unauthorized':
        return 'Unauthorized. Please login again.';
      case 'canceled':
        return 'Upload canceled.';
      case 'unknown':
        return 'An unknown error occurred.';
      case 'quota-exceeded':
        return 'Storage quota exceeded.';
      case 'unauthenticated':
        return 'Please login to upload files.';
      case 'retry-limit-exceeded':
        return 'Upload failed. Please try again.';
      case 'invalid-checksum':
        return 'File corrupted. Please try again.';
      default:
        return e.message ?? 'An error occurred while uploading file.';
    }
  }
}

