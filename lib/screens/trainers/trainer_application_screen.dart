import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:freelance_app/models/trainer_application_model.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';
import 'package:freelance_app/widgets/common/standard_button.dart';
import 'package:freelance_app/widgets/common/snackbar_helper.dart';
import 'package:freelance_app/widgets/common/app_card.dart';

/// Screen for users to apply to become trainers
/// Allows uploading certifications and describing courses/training
class TrainerApplicationScreen extends StatefulWidget {
  const TrainerApplicationScreen({super.key});

  @override
  State<TrainerApplicationScreen> createState() =>
      _TrainerApplicationScreenState();
}

class _TrainerApplicationScreenState extends State<TrainerApplicationScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  final _bioController = TextEditingController();
  final _coursesController = TextEditingController();

  List<String> _certificationUrls = [];
  final List<String> _courses = [];
  bool _isSubmitting = false;
  TrainerApplicationModel? _existingApplication;

  @override
  void initState() {
    super.initState();
    _checkExistingApplication();
  }

  Future<void> _checkExistingApplication() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _firestore
          .collection('trainerApplications')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final app = TrainerApplicationModel.fromMap(
          snapshot.docs.first.data(),
          snapshot.docs.first.id,
        );
        setState(() {
          _existingApplication = app;
          if (app.status == 'pending') {
            _bioController.text = app.bio;
            _coursesController.text = app.courses.join(', ');
            _certificationUrls = List.from(app.certifications);
          }
        });
      }
    } catch (e) {
      debugPrint('Error checking application: $e');
    }
  }

  Future<void> _uploadCertification() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (!mounted) return;
        SnackbarHelper.showInfo(context, 'Uploading certificate...');

        try {
          // For web, use bytes directly; for mobile, save to temp location
          String url;
          
          if (file.path != null) {
            // Mobile: file path is available
            url = await _uploadFileFromPath(file.path!, file.name);
          } else {
            // Web: use bytes via Firebase Storage putBytes
            url = await _uploadFileFromBytes(file.bytes!, file.name);
          }

          setState(() {
            _certificationUrls.add(url);
          });

          if (mounted) {
            SnackbarHelper.showSuccess(
                context, 'Certificate uploaded successfully');
          }
        } catch (uploadError) {
          if (mounted) {
            SnackbarHelper.showError(
                context, 'Error uploading certificate: $uploadError');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error picking file: $e');
      }
    }
  }

  Future<String> _uploadFileFromPath(String filePath, String fileName) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('trainer_certifications/${_auth.currentUser!.uid}/$fileName');

      await ref.putFile(io.File(filePath));
      return await ref.getDownloadURL();
    } catch (e) {
      throw 'Error uploading file: $e';
    }
  }

  Future<String> _uploadFileFromBytes(List<int> bytes, String fileName) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('trainer_certifications/${_auth.currentUser!.uid}/$fileName');

      await ref.putData(Uint8List.fromList(bytes));
      return await ref.getDownloadURL();
    } catch (e) {
      throw 'Error uploading file: $e';
    }
  }

  void _removeCertification(int index) {
    setState(() {
      _certificationUrls.removeAt(index);
    });
  }

  void _addCourse(String course) {
    if (course.trim().isNotEmpty && !_courses.contains(course.trim())) {
      setState(() {
        _courses.add(course.trim());
      });
      _coursesController.clear();
    }
  }

  void _removeCourse(int index) {
    setState(() {
      _courses.removeAt(index);
    });
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    if (_certificationUrls.isEmpty) {
      SnackbarHelper.showError(context, 'Please upload at least one certification');
      return;
    }

    if (_courses.isEmpty) {
      SnackbarHelper.showError(context, 'Please add at least one course/training area');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final userData = await _firestore.collection('users').doc(user.uid).get();
      final userEmail = userData['email'] as String? ?? user.email ?? '';
      final userName = userData['name'] as String? ?? 'Unknown';
      final userImage = userData['user_image'] as String?;

      final applicationId = _firestore.collection('trainerApplications').doc().id;

      final application = TrainerApplicationModel(
        applicationId: applicationId,
        userId: user.uid,
        userName: userName,
        userEmail: userEmail,
        userImage: userImage,
        bio: _bioController.text.trim(),
        certifications: _certificationUrls,
        courses: _courses,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      if (_existingApplication != null && _existingApplication!.status == 'pending') {
        // Update existing pending application
        await _firestore
            .collection('trainerApplications')
            .doc(_existingApplication!.applicationId)
            .update(application.toMap());

        if (mounted) {
          SnackbarHelper.showSuccess(context, 'Application updated successfully');
        }
      } else {
        // Create new application
        await _firestore
            .collection('trainerApplications')
            .doc(applicationId)
            .set(application.toMap());

        if (mounted) {
          SnackbarHelper.showSuccess(context, 'Application submitted successfully');
        }
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error submitting application: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    _coursesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // If application is already approved or rejected, show status
    if (_existingApplication != null &&
        (_existingApplication!.status == 'approved' ||
            _existingApplication!.status == 'rejected')) {
      return Scaffold(
        appBar: AppAppBar(
          title: 'Trainer Application',
          variant: AppBarVariant.primary,
        ),
        body: Center(
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _existingApplication!.status == 'approved'
                      ? Icons.check_circle
                      : Icons.cancel,
                  size: 64,
                  color: _existingApplication!.status == 'approved'
                      ? Colors.green
                      : Colors.red,
                ),
                SizedBox(height: AppDesignSystem.spaceM),
                Text(
                  _existingApplication!.status == 'approved'
                      ? 'Application Approved'
                      : 'Application Rejected',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppDesignSystem.spaceM),
                if (_existingApplication!.rejectionReason != null) ...[
                  Text('Reason:',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
                  SizedBox(height: AppDesignSystem.spaceS),
                  Text(_existingApplication!.rejectionReason!,
                      style: theme.textTheme.bodyMedium),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppAppBar(
        title: 'Apply to Become a Trainer',
        variant: AppBarVariant.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDesignSystem.spaceL),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Trainer Registration',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppDesignSystem.spaceXS),
              Text(
                'Upload your certifications and describe the courses you want to teach',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: AppDesignSystem.spaceL),

              // Bio Section
              Text(
                'Professional Bio *',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppDesignSystem.spaceS),
              TextFormField(
                controller: _bioController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe your training experience and expertise...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please provide a professional bio';
                  }
                  if (value.length < 50) {
                    return 'Bio must be at least 50 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: AppDesignSystem.spaceL),

              // Certifications Section
              Text(
                'Teaching Certifications *',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppDesignSystem.spaceS),
              StandardButton(
                label: 'Upload Certificate',
                icon: Icons.upload_file,
                type: StandardButtonType.secondary,
                fullWidth: true,
                onPressed: _uploadCertification,
              ),
              SizedBox(height: AppDesignSystem.spaceM),

              // Display uploaded certifications
              if (_certificationUrls.isNotEmpty) ...[
                Text(
                  'Uploaded Certifications (${_certificationUrls.length})',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: AppDesignSystem.spaceS),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _certificationUrls.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppDesignSystem.spaceS,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.description, color: colorScheme.primary),
                          SizedBox(width: AppDesignSystem.spaceS),
                          Expanded(
                            child: Text(
                              'Certificate ${index + 1}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: colorScheme.error),
                            onPressed: () => _removeCertification(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
              SizedBox(height: AppDesignSystem.spaceL),

              // Courses Section
              Text(
                'Courses/Training Areas *',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppDesignSystem.spaceS),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _coursesController,
                      decoration: InputDecoration(
                        hintText: 'e.g., Flutter Development',
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppDesignSystem.radiusM),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppDesignSystem.spaceS),
                  FilledButton(
                    onPressed: () {
                      _addCourse(_coursesController.text);
                    },
                    child: const Text('Add'),
                  ),
                ],
              ),
              SizedBox(height: AppDesignSystem.spaceM),

              // Display added courses
              if (_courses.isNotEmpty) ...[
                Wrap(
                  spacing: AppDesignSystem.spaceS,
                  runSpacing: AppDesignSystem.spaceS,
                  children: _courses.asMap().entries.map((entry) {
                    return Chip(
                      label: Text(entry.value),
                      onDeleted: () => _removeCourse(entry.key),
                      backgroundColor: colorScheme.secondaryContainer,
                    );
                  }).toList(),
                ),
              ],
              SizedBox(height: AppDesignSystem.spaceL),

              // Submit Button
              StandardButton(
                label: 'Submit Application',
                icon: Icons.send,
                type: StandardButtonType.primary,
                fullWidth: true,
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _submitApplication,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
