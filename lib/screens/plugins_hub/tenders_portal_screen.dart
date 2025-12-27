import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/utils/colors.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/standard_button.dart';
import 'package:freelance_app/widgets/common/app_chip.dart';
import 'package:freelance_app/utils/currency_formatter.dart';
import 'package:freelance_app/widgets/common/snackbar_helper.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';
import 'package:freelance_app/widgets/common/common_widgets.dart';
import 'package:freelance_app/services/cache/firestore_cache_service.dart';
import 'package:freelance_app/services/notifications/notification_service.dart';
import 'post_tender_dialog.dart';

class TendersPortalScreen extends StatefulWidget {
  const TendersPortalScreen({super.key});

  @override
  State<TendersPortalScreen> createState() => _TendersPortalScreenState();
}

class _TendersPortalScreenState extends State<TendersPortalScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String _keyword = '';
  Map<String, dynamic>? _currentUserData;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  Future<void> _loadCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final cacheService = FirestoreCacheService();
      
      // Try cache first (1 hour TTL for user data)
      Map<String, dynamic>? userData = cacheService.getCachedDoc(
        collection: 'users',
        docId: user.uid,
        ttl: Duration(hours: 1),
      );
      
      if (userData == null) {
        // Cache miss, fetch from Firestore
        final doc = await _firestore.collection('users').doc(user.uid).get();
        userData = doc.data();
        
        // Cache the user document
        if (userData != null) {
          cacheService.cacheDoc(
            collection: 'users',
            docId: user.uid,
            data: userData,
          );
        }
      }

      if (mounted && userData != null) {
        setState(() {
          _currentUserData = userData;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  bool get _isCompany => _currentUserData?['isCompany'] == true;
  String? get _currentUserId => _auth.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return HintsWrapper(
      screenId: 'tenders_portal',
      child: Scaffold(
      resizeToAvoidBottomInset: true, // Critical for keyboard handling
      appBar: AppAppBar(
        title: 'Tenders Portal',
        variant: AppBarVariant.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          // Only show add button for companies
          if (_isCompany)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showPostTenderDialog,
              tooltip: 'Post Tender',
            ),
        ],
      ),
      floatingActionButton: _isCompany
          ? FloatingActionButton.extended(
              onPressed: _showPostTenderDialog,
              label: const Text('Post Tender'),
              icon: const Icon(Icons.add),
              backgroundColor: AppDesignSystem.brandBlue,
              foregroundColor: botsWhite, // White text/icon on blue background
            )
          : null,
      body: Container(
        color: colorScheme.surface,
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('tenders')
              .where('approvalStatus', isEqualTo: 'approved')
              .where('status', isEqualTo: 'open')
              .orderBy('status', descending: false)
              .orderBy('deadline', descending: false)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return EmptyState(
                icon: Icons.error_outline,
                title: 'Unable to load tenders',
                message: 'Please check your connection and try again.',
              );
            }
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final docs = snapshot.data!.docs;
            final keyword = _keyword.trim().toLowerCase();
            
            final filtered = docs.where((doc) {
               final data = doc.data() as Map<String, dynamic>;
               if (keyword.isEmpty) return true;
               final title = (data['title'] ?? '').toString().toLowerCase();
               final org = (data['organization'] ?? '').toString().toLowerCase();
               final category = (data['category'] ?? '').toString().toLowerCase();
               return title.contains(keyword) || org.contains(keyword) || category.contains(keyword);
            }).toList();

            if (filtered.isEmpty) {
               return Padding(
                padding: EdgeInsets.only(top: AppDesignSystem.spaceM),
                child: Center(
                  child: Text(
                    keyword.isEmpty ? 'No tenders available' : 'No tenders match search',
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: AppDesignSystem.paddingL,
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final data = filtered[index].data() as Map<String, dynamic>;
                
                final title = data['title'] ?? 'No Title';
                final organization = data['organization'] ?? 'Unknown Org';
                final budget = (data['budget'] ?? 0).toDouble();
                final deadline = (data['deadline'] as Timestamp?)?.toDate() ?? DateTime.now();
                final category = data['category'] ?? 'General';
                final isVerified = data['isVerified'] ?? false;

                final tenderId = filtered[index].id;
                final organizationId = data['organizationId'] as String?;
                
                return _TenderCard(
                  tenderId: tenderId,
                  title: title,
                  organization: organization,
                  organizationId: organizationId,
                  budget: budget,
                  deadline: deadline,
                  category: category,
                  isVerified: isVerified,
                  onTap: () {
                    _showTenderDetails(
                      tenderId: tenderId,
                      title: title,
                      organization: organization,
                      organizationId: organizationId,
                      budget: budget,
                      deadline: deadline,
                      category: category,
                      isVerified: isVerified,
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      ),
    );
  }

  void _showFilterDialog() {
    final controller = TextEditingController(text: _keyword);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true, // Allow scrolling when keyboard appears
        title: const Text('Filter Tenders'),
        content: TextField(
          controller: controller,
          scrollPadding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 80,
          ),
          decoration: const InputDecoration(
            labelText: 'Keyword',
            hintText: 'e.g. technology, council, marketing',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          StandardButton(
            label: 'Clear',
            type: StandardButtonType.text,
            onPressed: () {
              setState(() => _keyword = '');
              Navigator.pop(dialogContext);
            },
          ),
          StandardButton(
            label: 'Apply',
            onPressed: () {
              setState(() => _keyword = controller.text);
              Navigator.pop(dialogContext);
            },
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  void _showTenderDetails({
    required String tenderId,
    required String title,
    required String organization,
    String? organizationId,
    required double budget,
    required DateTime deadline,
    required String category,
    required bool isVerified,
  }) {
    final canApply = _currentUserId != null && 
                     _currentUserId != organizationId; // Can't apply to own tender
    
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Organization: $organization'),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                Text('Category: $category'),
                Text('Verified: ${isVerified ? 'Yes' : 'No'}'),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                Text(
                  'Budget: ${CurrencyFormatter.formatBWP(budget, includeDecimals: false)}',
                ),
                Text(
                    'Deadline: ${deadline.day}/${deadline.month}/${deadline.year}'),
                if (!canApply && _currentUserId == organizationId)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      'You cannot apply to your own tender.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            StandardButton(
              label: 'Close',
              type: StandardButtonType.text,
              onPressed: () => Navigator.pop(context),
            ),
            if (canApply)
              StandardButton(
                label: 'Apply',
                onPressed: () {
                  Navigator.pop(context);
                  _applyToTender(tenderId, title, organization);
                },
              ),
          ],
        );
      },
    );
  }

  Future<void> _applyToTender(String tenderId, String title, String organization) async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Please login to apply');
      }
      return;
    }

    try {
      // Check if already applied
      final existingApplication = await _firestore
          .collection('tenders')
          .doc(tenderId)
          .collection('applications')
          .where('applicantId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (existingApplication.docs.isNotEmpty) {
        if (mounted) {
          SnackbarHelper.showInfo(context, 'You have already applied to this tender');
        }
        return;
      }

      // Create application
      final applicationRef = await _firestore
          .collection('tenders')
          .doc(tenderId)
          .collection('applications')
          .add({
        'applicantId': user.uid,
        'applicantName': _currentUserData?['name'] ?? _currentUserData?['companyName'] ?? 'Applicant',
        'tenderTitle': title,
        'organization': organization,
        'status': 'pending',
        'appliedAt': FieldValue.serverTimestamp(),
      });

      // Notify applicant
      try {
        final notificationService = NotificationService();
        await notificationService.sendNotification(
          userId: user.uid,
          type: 'tender_applied',
          title: 'Tender Application Submitted ✅',
          body: 'Your application for "$title" by $organization has been submitted. We will notify you when the tender owner responds.',
          data: {
            'tenderId': tenderId,
            'tenderTitle': title,
            'organization': organization,
            'applicationId': applicationRef.id,
          },
          sendEmail: true,
        );
      } catch (e) {
        debugPrint('Failed to notify applicant: $e');
      }

      // Notify tender owner
      try {
        final cacheService = FirestoreCacheService();
        
        // Try cache first (5 minute TTL for tender data)
        Map<String, dynamic>? tenderData = cacheService.getCachedDoc(
          collection: 'tenders',
          docId: tenderId,
          ttl: Duration(minutes: 5),
        );
        
        if (tenderData == null) {
          // Cache miss, fetch from Firestore
          final tenderDoc = await _firestore.collection('tenders').doc(tenderId).get();
          tenderData = tenderDoc.data();
          
          // Cache the tender document
          if (tenderData != null) {
            cacheService.cacheDoc(
              collection: 'tenders',
              docId: tenderId,
              data: tenderData,
            );
          }
        }

        final ownerId = tenderData?['createdBy'] as String?;
        final applicantName = _currentUserData?['name'] ?? _currentUserData?['companyName'] ?? 'A user';

        if (ownerId != null && ownerId.isNotEmpty) {
          final notificationService = NotificationService();
          await notificationService.sendNotification(
            userId: ownerId,
            type: 'tender_application_received',
            title: 'New Tender Application 📬',
            body: '$applicantName has applied for your tender "$title". Review their application to determine if they are a good fit.',
            data: {
              'tenderId': tenderId,
              'tenderTitle': title,
              'applicationId': applicationRef.id,
              'applicantId': user.uid,
              'applicantName': applicantName,
            },
            sendEmail: true,
          );
        }
      } catch (e) {
        debugPrint('Failed to notify tender owner: $e');
      }

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Application submitted successfully!');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error applying: $e');
      }
    }
  }

  void _showPostTenderDialog() {
    final user = _auth.currentUser;
    if (user == null) {
      SnackbarHelper.showError(context, 'Please login to post a tender');
      return;
    }

    if (!_isCompany) {
      SnackbarHelper.showError(context, 'Only companies can post tenders');
      return;
    }

    showDialog<void>(
      context: context,
      builder: (context) => PostTenderDialog(
        organizationId: user.uid,
        organizationName: _currentUserData?['companyName'] ?? 
                          _currentUserData?['name'] ?? 'Organization',
      ),
    );
  }
}

class _TenderCard extends StatelessWidget {
  final String tenderId;
  final String title;
  final String organization;
  final String? organizationId;
  final double budget;
  final DateTime deadline;
  final String category;
  final bool isVerified;
  final VoidCallback onTap;

  const _TenderCard({
    required this.tenderId,
    required this.title,
    required this.organization,
    this.organizationId,
    required this.budget,
    required this.deadline,
    required this.category,
    required this.isVerified,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      margin: EdgeInsets.only(bottom: AppDesignSystem.spaceM),
      onTap: onTap,
      padding: AppDesignSystem.paddingM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isVerified)
                Icon(
                  Icons.verified,
                  color: colorScheme.tertiary,
                  size: 20,
                ),
            ],
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
          Text(
            organization,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
          Row(
            children: [
              AppChip(
                label: category,
              ),
              AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
              Icon(Icons.payments_outlined,
                  size: 16, color: colorScheme.tertiary),
              AppDesignSystem.horizontalSpace(AppDesignSystem.spaceXS),
              Text(
                CurrencyFormatter.formatBWP(budget, includeDecimals: false),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.tertiary,
                ),
              ),
            ],
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
          Row(
            children: [
              Icon(Icons.calendar_today,
                  size: 16, color: colorScheme.onSurfaceVariant),
              AppDesignSystem.horizontalSpace(AppDesignSystem.spaceXS),
              Text(
                'Deadline: ${deadline.day}/${deadline.month}/${deadline.year}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
          StandardButton(
            label: 'View Details & Apply',
            onPressed: onTap,
            type: StandardButtonType.primary,
            icon: Icons.arrow_forward,
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}
