import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/screens/common/cv_document_viewer_screen.dart';
import 'package:freelance_app/services/firebase/firebase_storage_service.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/snackbar_helper.dart';
import 'package:freelance_app/widgets/common/standard_button.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';
import 'package:freelance_app/services/notifications/notification_service.dart';
import 'package:file_picker/file_picker.dart';

class CompanyVerificationScreen extends StatefulWidget {
  const CompanyVerificationScreen({super.key});

  @override
  State<CompanyVerificationScreen> createState() => _CompanyVerificationScreenState();
}

class _CompanyVerificationScreenState extends State<CompanyVerificationScreen> {
  final _storage = FirebaseStorageService();
  final _firestore = FirebaseFirestore.instance;
  final _notificationService = NotificationService();

  bool _loading = true;
  bool _uploading = false;
  Map<String, dynamic> _user = {};
  Map<String, dynamic> _kyc = {};

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static const _requiredDocs = <String, String>{
    'cipa_certificate': 'CIPA Certificate (PDF/DOC)',
    'cipa_extract': 'CIPA Extract (PDF/DOC)',
    'burs_tin': 'BURS TIN Evidence (PDF/DOC)',
    'proof_of_address': 'Proof of Business Address (PDF/DOC)',
  };

  static const _optionalDocs = <String, String>{
    'authority_letter': 'Authority Letter / Resolution (PDF/DOC)',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = _uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final kycDoc = await _firestore.collection('company_kyc').doc(uid).get();

      setState(() {
        _user = (userDoc.data() ?? {});
        _kyc = (kycDoc.data() ?? {});
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) SnackbarHelper.showError(context, 'Failed to load verification: $e');
    }
  }

  bool get _canEdit {
    final status = (_kyc['status'] as String?) ?? 'draft';
    return status == 'draft' || status == 'rejected';
  }

  Map<String, dynamic> get _documents {
    final d = _kyc['documents'];
    if (d is Map<String, dynamic>) return d;
    return <String, dynamic>{};
  }

  bool get _hasAllRequired {
    for (final key in _requiredDocs.keys) {
      final doc = _documents[key];
      if (doc is! Map) return false;
      final url = doc['url'];
      if (url is! String || url.isEmpty) return false;
    }
    return true;
  }

  Future<void> _pickAndUpload(String docType) async {
    if (!_canEdit) {
      SnackbarHelper.showError(context, 'Verification is under review.');
      return;
    }

    final uid = _uid;
    if (uid == null) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      withData: false,
    );

    final file = result?.files.single;
    final filePath = file?.path;
    if (filePath == null) return;

    setState(() => _uploading = true);
    try {
      final url = await _storage.uploadCompanyKycDocument(
        filePath: filePath,
        companyId: uid,
        docType: docType,
      );

      await _firestore.collection('company_kyc').doc(uid).set({
        'companyId': uid,
        'companyName': (_user['company_name'] ?? _user['name'] ?? '').toString(),
        'companyEmail': (_user['email'] ?? '').toString(),
        'status': (_kyc['status'] as String?) ?? 'draft',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _firestore.collection('company_kyc').doc(uid).update({
        'documents.$docType': {
          'url': url,
          'fileName': file?.name,
          'uploadedAt': FieldValue.serverTimestamp(),
        }
      });

      await _load();
      if (mounted) SnackbarHelper.showSuccess(context, 'Uploaded successfully');
    } catch (e) {
      if (mounted) SnackbarHelper.showError(context, 'Upload failed: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _submit() async {
    final uid = _uid;
    if (uid == null) return;

    if (!_hasAllRequired) {
      SnackbarHelper.showError(context, 'Upload all required documents first.');
      return;
    }

    setState(() => _uploading = true);
    try {
      await _firestore.collection('company_kyc').doc(uid).set({
        'status': 'submitted',
        'submittedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Notify company (confirmation) and admins
      try {
        final companyName = (_user['company_name'] ?? _user['name'] ?? '').toString();
        
        // Notify company (confirmation)
        await _notificationService.sendNotification(
          userId: uid,
          type: 'company_kyc_submitted',
          title: 'Documents Submitted Successfully',
          body: 'Your verification documents have been submitted for review. Our admin team will review them within 2-3 business days.',
          data: {'companyId': uid, 'companyName': companyName},
          sendEmail: true,
        );

        // Notify admins (in-app + push/email handled server-side by notifyUser)
        final admins = await _firestore
            .collection('users')
            .where('isAdmin', isEqualTo: true)
            .limit(25)
            .get();
        for (final admin in admins.docs) {
          await _notificationService.sendNotification(
            userId: admin.id,
            type: 'company_kyc_submitted',
            title: 'New Company Verification Submitted',
            body: 'Company "$companyName" has submitted verification documents for review.',
            data: {'companyId': uid, 'companyName': companyName},
            sendEmail: true,
          );
        }
      } catch (e) {
        debugPrint('Error sending admin notifications: $e');
        // Best-effort; do not block submission.
      }

      await _load();
      if (mounted) SnackbarHelper.showSuccess(context, 'Submitted for review');
    } catch (e) {
      if (mounted) SnackbarHelper.showError(context, 'Submit failed: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _viewDoc(String label, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CvDocumentViewerScreen(title: label, cvUrl: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final approvalStatus = (_user['approvalStatus'] as String?) ?? 'pending';
    final rejectionReason = (_kyc['rejectionReason'] as String?) ?? (_user['rejectionReason'] as String?);
    final kycStatus = (_kyc['status'] as String?) ?? 'draft';

    return HintsWrapper(
      screenId: 'company_verification',
      child: Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppAppBar(
        title: 'Company Verification',
        variant: AppBarVariant.primary,
      ),
      body: ListView(
        padding: AppDesignSystem.paddingM,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                Text('Account: $approvalStatus'),
                Text('KYC: $kycStatus'),
                if (kycStatus == 'rejected' && rejectionReason != null && rejectionReason.trim().isNotEmpty) ...[
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                  Text('Rejection reason:', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                  Text(rejectionReason),
                ],
                if (!_canEdit) ...[
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                  Text(
                    'Your documents are under review. Editing is disabled until a decision is made.',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
          _buildDocSection('Required documents', _requiredDocs),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
          _buildDocSection('Optional documents', _optionalDocs),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceM + AppDesignSystem.spaceXS),
          StandardButton(
            label: 'Submit for Review',
            type: StandardButtonType.primary,
            onPressed: (_uploading || !_canEdit) 
                ? null 
                : () {
                    if (!_hasAllRequired) {
                      SnackbarHelper.showError(
                        context, 
                        'Please upload all required documents before submitting.',
                      );
                      return;
                    }
                    _submit();
                  },
            isLoading: _uploading,
            fullWidth: true,
            icon: Icons.send,
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
          Text(
            'Tip: Use official documents from CIPA and BURS. Upload clear scans.',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildDocSection(String title, Map<String, String> docs) {
    final theme = Theme.of(context);
    final documents = _documents;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
          for (final entry in docs.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _DocRow(
                label: entry.value,
                doc: documents[entry.key],
                canEdit: _canEdit && !_uploading,
                onUpload: () => _pickAndUpload(entry.key),
                onView: (url) => _viewDoc(entry.value, url),
              ),
            ),
        ],
      ),
    );
  }
}

class _DocRow extends StatelessWidget {
  final String label;
  final Object? doc;
  final bool canEdit;
  final VoidCallback onUpload;
  final void Function(String url) onView;

  const _DocRow({
    required this.label,
    required this.doc,
    required this.canEdit,
    required this.onUpload,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String? url;
    if (doc is Map) {
      final m = doc as Map;
      final u = m['url'];
      if (u is String && u.isNotEmpty) url = u;
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS / 2),
              Text(
                url != null ? 'Uploaded' : 'Not uploaded',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: url != null
                      ? AppDesignSystem.primary(context).withValues(alpha: 0.85)
                      : AppDesignSystem.onSurfaceVariant(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
        if (url != null)
          StandardButton(
            label: 'View',
            type: StandardButtonType.text,
            onPressed: () => onView(url!),
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            fontSize: 14,
          ),
        StandardButton(
          label: url == null ? 'Upload' : 'Replace',
          type: StandardButtonType.secondary,
          onPressed: canEdit ? onUpload : null,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          fontSize: 14,
        ),
      ],
    );
  }
}
