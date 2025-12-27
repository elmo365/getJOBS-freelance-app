import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';
import 'package:freelance_app/services/notifications/notification_service.dart';
import 'package:freelance_app/services/connectivity_service.dart';

import 'package:freelance_app/widgets/common/app_app_bar.dart';
import 'package:freelance_app/widgets/common/snackbar_helper.dart';
import 'package:freelance_app/widgets/common/standard_button.dart';
import 'package:freelance_app/widgets/common/common_widgets.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/utils/colors.dart';
import 'package:freelance_app/screens/admin/widgets/admin_company_card.dart';
import 'package:freelance_app/screens/admin/screens/admin_company_details_screen.dart';
import 'package:freelance_app/screens/common/cv_document_viewer_screen.dart';

/// Base screen for listing companies by approval status
class AdminCompaniesListScreen extends StatefulWidget {
  final String status; // 'pending', 'approved', or 'rejected'

  const AdminCompaniesListScreen({
    super.key,
    required this.status,
  });

  @override
  State<AdminCompaniesListScreen> createState() =>
      _AdminCompaniesListScreenState();
}

class _AdminCompaniesListScreenState extends State<AdminCompaniesListScreen>
    with ConnectivityAware {
  final _dbService = FirebaseDatabaseService();
  final _notificationService = NotificationService();
  List<Map<String, dynamic>> _companies = [];
  bool _isLoading = true;
  String _searchQuery = '';
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    if (!await checkConnectivity(context,
        message:
            'Cannot load companies without internet. Please connect and try again.')) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      if (mounted) {
        setState(() => _isLoading = true);
      }

      final result = await _dbService.searchUsers(isCompany: true, limit: 100);
      final allCompanies = result.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final docId = doc.id;
            if (docId.isEmpty) return null;
            return {
              ...data,
              'id': docId,
            };
          })
          .where((c) {
            if (c == null) return false;
            final id = c['id'] as String?;
            final isCompany = c['isCompany'] as bool? ?? false;
            return id != null && id.isNotEmpty && isCompany;
          })
          .cast<Map<String, dynamic>>()
          .toList();

      if (mounted) {
        setState(() {
          _companies = allCompanies.where((c) {
            final id = c['id'] as String?;
            if (id == null || id.isEmpty) return false;
            if (widget.status == 'all') return true;
            final approvalStatus = c['approvalStatus'] as String? ?? 'pending';
            return approvalStatus == widget.status;
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading companies: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _companies = [];
        });
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _searchQuery = query.toLowerCase();
        });
      }
    });
  }

  String get _title {
    switch (widget.status) {
      case 'pending':
        return 'Pending Companies';
      case 'approved':
        return 'Approved Companies';
      case 'rejected':
        return 'Rejected Companies';
      default:
        return 'Companies';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: botsSuperLightGrey,
      resizeToAvoidBottomInset: true,
      appBar: AppAppBar(
        title: _title,
        variant: AppBarVariant.primary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: AppDesignSystem.paddingHorizontal(AppDesignSystem.spaceL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Search Bar
                Padding(
                  padding:
                      AppDesignSystem.paddingVertical(AppDesignSystem.spaceL),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    scrollPadding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 100,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search companies...',
                      prefixIcon:
                          Icon(Icons.search, color: colorScheme.primary),
                      filled: true,
                      fillColor: botsWhite,
                      border: OutlineInputBorder(
                        borderRadius: AppDesignSystem.borderRadiusM,
                        borderSide:
                            BorderSide(color: colorScheme.outlineVariant),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppDesignSystem.borderRadiusM,
                        borderSide:
                            BorderSide(color: colorScheme.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppDesignSystem.borderRadiusM,
                        borderSide:
                            BorderSide(color: colorScheme.primary, width: 2),
                      ),
                    ),
                  ),
                ),
                // Company List
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildCompanyList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyList() {
    final filtered = _companies.where((company) {
      final id = company['id'] as String?;
      if (id == null || id.isEmpty) return false;

      if (_searchQuery.isNotEmpty) {
        final companyName = (company['company_name'] ?? company['name'] ?? '')
            .toString()
            .toLowerCase();
        final email = (company['email'] ?? '').toString().toLowerCase();
        final regNumber =
            (company['registration_number'] ?? '').toString().toLowerCase();
        return companyName.contains(_searchQuery) ||
            email.contains(_searchQuery) ||
            regNumber.contains(_searchQuery);
      }
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return EmptyState(
        icon: widget.status == 'pending'
            ? Icons.inbox
            : widget.status == 'approved'
                ? Icons.check_circle_outline
                : Icons.cancel_outlined,
        title: _searchQuery.isEmpty
            ? 'No ${widget.status} companies'
            : 'No results found',
      );
    }

    // FIXED: Use Column with mapped widgets instead of nested ListView
    // This allows parent SingleChildScrollView to handle all scrolling
    return RefreshIndicator(
      onRefresh: _loadCompanies,
      child: Column(
        children: filtered.map((company) {
          final docId = company['id'] as String? ?? '';
          if (docId.isEmpty) return const SizedBox.shrink();

          return Padding(
            padding: EdgeInsets.only(bottom: AppDesignSystem.spaceM),
            child: _buildCompanyCard(company, docId),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCompanyCard(Map<String, dynamic> company, String docId) {
    // Determine status from widget.status or company data
    final status = company['approvalStatus'] as String? ?? 'pending';

    return AdminCompanyCard(
      company: company,
      docId: docId,
      status: status,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminCompanyDetailsScreen(
              company: company,
              docId: docId,
              status: status,
              onApprove: () async {
                Navigator.pop(context);
                await _approveCompany(
                    docId, company['company_name'] ?? 'Company');
              },
              onReject: () async {
                Navigator.pop(context);
                _showRejectDialog(docId, company['company_name'] ?? 'Company');
              },
              onRevoke: () async {
                Navigator.pop(context);
                _showRejectDialog(
                    docId,
                    company['company_name'] ??
                        'Company'); // Using reject as revoke
              },
              onReapprove: () async {
                Navigator.pop(context);
                await _approveCompany(
                    docId, company['company_name'] ?? 'Company');
              },
              onViewKyc: () => _showKycDocsDialog(docId, company['company_name'] ?? 'Company'),
            ),
          ),
        );
      },
    );
  }

  Future<void> _approveCompany(String docId, String companyName) async {
    if (!mounted) return;
    if (!await checkConnectivity(context,
        message:
            'Cannot approve company without internet. Please connect and try again.')) {
      return;
    }

    try {
      setState(() => _isLoading = true);
      final kycDoc = await FirebaseFirestore.instance
          .collection('company_kyc')
          .doc(docId)
          .get();
      final kyc = kycDoc.data() ?? {};
      final kycStatus = (kyc['status'] as String?) ?? 'draft';
      if (kycStatus != 'submitted') {
        if (!mounted) return;
        SnackbarHelper.showError(context,
            'Cannot approve: company has not submitted KYC documents.');
        setState(() => _isLoading = false);
        return;
      }

      await _dbService.updateUser(
        userId: docId,
        data: {
          'isApproved': true,
          'approvalStatus': 'approved',
          'approvalDate': DateTime.now().toIso8601String(),
        },
      );

      await FirebaseFirestore.instance
          .collection('company_kyc')
          .doc(docId)
          .set({
        'status': 'approved',
        'reviewedAt': FieldValue.serverTimestamp(),
        'rejectionReason': FieldValue.delete(),
      }, SetOptions(merge: true));

      await _notificationService.sendNotification(
        userId: docId,
        type: 'company_approval',
        title: 'Company Approved! ✅',
        body:
            'Your company "$companyName" has been approved. You can now post jobs!',
        data: {'companyId': docId},
        sendEmail: true,
      );

      await _loadCompanies();
      if (!mounted) return;
      SnackbarHelper.showSuccess(
          context, '✓ $companyName approved successfully');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      SnackbarHelper.showError(context, 'Error approving company: $e');
    }
  }

  void _showRejectDialog(String docId, String companyName) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject $companyName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide a reason for rejection:'),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g., Invalid registration number',
                border: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusS,
                ),
              ),
            ),
          ],
        ),
        actions: [
          StandardButton(
            label: 'Cancel',
            type: StandardButtonType.text,
            onPressed: () => Navigator.pop(context),
          ),
          StandardButton(
            label: 'Reject',
            type: StandardButtonType.danger,
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                SnackbarHelper.showError(context, 'Please provide a reason');
                return;
              }
              Navigator.pop(context);
              _rejectCompany(docId, companyName, reasonController.text.trim());
            },
          ),
        ],
      ),
    );
  }

  Future<void> _rejectCompany(
      String docId, String companyName, String reason) async {
    if (!mounted) return;
    if (!await checkConnectivity(context,
        message:
            'Cannot reject company without internet. Please connect and try again.')) {
      return;
    }

    try {
      setState(() => _isLoading = true);
      await _dbService.updateUser(
        userId: docId,
        data: {
          'isApproved': false,
          'approvalStatus': 'rejected',
          'rejectionReason': reason,
          'rejectionDate': DateTime.now().toIso8601String(),
        },
      );

      await FirebaseFirestore.instance
          .collection('company_kyc')
          .doc(docId)
          .set({
        'status': 'rejected',
        'rejectionReason': reason,
        'reviewedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _notificationService.sendNotification(
        userId: docId,
        type: 'company_rejection',
        title: 'Company Application Rejected',
        body:
            'Your company "$companyName" application was rejected. Reason: $reason',
        data: {'companyId': docId},
        sendEmail: true,
      );

      await _loadCompanies();
      if (!mounted) return;
      SnackbarHelper.showSuccess(context, '✓ $companyName rejected');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      SnackbarHelper.showError(context, 'Error rejecting company: $e');
    }
  }

  void _showKycDocsDialog(String companyId, String companyName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('KYC Documents: $companyName'),
          content: SizedBox(
            width: 520,
            child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('company_kyc')
                  .doc(companyId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Padding(
                    padding: AppDesignSystem.paddingL,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }

                final data = snapshot.data?.data() ?? {};
                final status = data['status'] as String? ?? '';
                final documents = (data['documents'] is Map<String, dynamic>)
                    ? (data['documents'] as Map<String, dynamic>)
                    : <String, dynamic>{};

                Widget row(String key, String label) {
                  String? url;
                  final doc = documents[key];
                  if (doc is Map) {
                    final u = doc['url'];
                    if (u is String && u.isNotEmpty) url = u;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(child: Text(label)),
                        Text(url != null ? 'Uploaded' : 'Missing'),
                        AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
                        if (url != null)
                          StandardButton(
                            label: 'View',
                            type: StandardButtonType.text,
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                this.context,
                                MaterialPageRoute(
                                  builder: (_) => CvDocumentViewerScreen(
                                    title: label,
                                    cvUrl: url!,
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'KYC status: ${status.isNotEmpty ? status : 'Not submitted'}'),
                      AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                      row('cipa_certificate', 'CIPA Certificate'),
                      row('cipa_extract', 'CIPA Extract'),
                      row('burs_tin', 'BURS TIN Evidence'),
                      row('proof_of_address', 'Proof of Address'),
                      row('authority_letter', 'Authority Letter (optional)'),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            StandardButton(
              label: 'Close',
              type: StandardButtonType.text,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }
}
