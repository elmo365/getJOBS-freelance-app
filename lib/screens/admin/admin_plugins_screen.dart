import 'package:flutter/material.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';
import 'package:freelance_app/services/notifications/notification_service.dart';
import 'package:freelance_app/services/connectivity_service.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/standard_button.dart';
import 'package:freelance_app/widgets/common/snackbar_helper.dart';
import 'package:freelance_app/widgets/common/common_widgets.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/utils/colors.dart';

class AdminPluginsScreen extends StatefulWidget {
  const AdminPluginsScreen({super.key});

  @override
  State<AdminPluginsScreen> createState() => _AdminPluginsScreenState();
}

class _AdminPluginsScreenState extends State<AdminPluginsScreen>
    with ConnectivityAware {
  final _dbService = FirebaseDatabaseService();
  final _notificationService = NotificationService();
  List<Map<String, dynamic>> _pendingGigs = [];
  List<Map<String, dynamic>> _pendingCourses = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPendingPlugins();
  }

  Future<void> _loadPendingPlugins() async {
    try {
      if (mounted) {
        setState(() => _isLoading = true);
      }

      // Load pending gigs
      try {
        final gigsResult = await _dbService
            .getCollection('gigs')
            .where('status', isEqualTo: 'pending')
            .where('approvalStatus', isEqualTo: 'pending')
            .get();

        _pendingGigs = gigsResult.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            ...data,
            'id': doc.id,
            'type': 'gig',
          };
        }).toList();
      } catch (e) {
        debugPrint('Error loading pending gigs: $e');
        _pendingGigs = [];
      }

      // Load pending courses
      try {
        final coursesResult = await _dbService
            .getCollection('courses')
            .where('status', isEqualTo: 'pending')
            .where('approvalStatus', isEqualTo: 'pending')
            .get();

        _pendingCourses = coursesResult.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            ...data,
            'id': doc.id,
            'type': 'course',
          };
        }).toList();
      } catch (e) {
        debugPrint('Error loading pending courses: $e');
        _pendingCourses = [];
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading pending plugins: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: botsSuperLightGrey,
      resizeToAvoidBottomInset: true,
      appBar: AppAppBar(
        title: 'Plugin Approvals',
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
                  padding: AppDesignSystem.paddingVertical(AppDesignSystem.spaceL),
                  child: TextField(
                    onChanged: (value) =>
                        setState(() => _searchQuery = value.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search plugins...',
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
                        borderSide: BorderSide(
                            color: colorScheme.primary, width: 2),
                      ),
                    ),
                  ),
                ),
                // Plugins List
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildPluginsList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPluginsList() {
    final allPending = [..._pendingGigs, ..._pendingCourses];

    if (allPending.isEmpty) {
      return EmptyState(
        icon: Icons.check_circle,
        title: 'No pending plugins',
      );
    }

    final filtered = allPending.where((item) {
      if (_searchQuery.isNotEmpty) {
        final title = (item['title'] ?? '').toString().toLowerCase();
        return title.contains(_searchQuery);
      }
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'No results found',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPendingPlugins,
      child: ListView.builder(
        padding: AppDesignSystem.paddingHorizontal(AppDesignSystem.spaceL),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(bottom: AppDesignSystem.spaceM),
            child: _buildPluginCard(filtered[index]),
          );
        },
      ),
    );
  }

  Widget _buildPluginCard(Map<String, dynamic> item) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final itemId = item['id'] as String;
    final itemType = item['type'] as String? ?? 'unknown';
    final title = item['title'] as String? ?? 'Untitled';
    final description = item['description'] as String? ?? '';

    return AppCard(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 6,
      variant: SurfaceVariant.elevated,
      borderRadius: AppDesignSystem.borderRadiusM,
      child: Padding(
        padding: AppDesignSystem.paddingM,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  itemType == 'gig' ? Icons.work_outline : Icons.video_library,
                  color: colorScheme.primary,
                ),
                AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
                Expanded(
                  child: Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: AppDesignSystem.paddingS,
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: AppDesignSystem.borderRadiusS,
                  ),
                  child: Text(
                    itemType == 'gig' ? 'Gig' : 'Course',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
              Text(
                description,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            Row(
              children: [
                Expanded(
                  child: StandardButton(
                    label: 'Approve',
                    type: StandardButtonType.success,
                    onPressed: () => _approvePlugin(itemId, itemType, title),
                    icon: Icons.check,
                  ),
                ),
                AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
                Expanded(
                  child: StandardButton(
                    label: 'Reject',
                    type: StandardButtonType.danger,
                    onPressed: () =>
                        _showRejectPluginDialog(itemId, itemType, title),
                    icon: Icons.close,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approvePlugin(
      String itemId, String itemType, String title) async {
    if (!mounted) return;

    if (!await checkConnectivity(context,
        message: 'Cannot approve without internet.')) {
      return;
    }

    try {
      setState(() => _isLoading = true);

      final collection = itemType == 'gig' ? 'gigs' : 'courses';
      await _dbService.getCollection(collection).doc(itemId).update({
        'status': itemType == 'gig' ? 'active' : 'approved',
        'approvalStatus': 'approved',
        'isApproved': true,
        'isVerified': true,
        'approvedAt': DateTime.now().toIso8601String(),
      });

      // Get creator info
      final itemDoc =
          await _dbService.getCollection(collection).doc(itemId).get();
      final itemData = itemDoc.data() as Map<String, dynamic>?;
      final creatorId = itemData?['trainerId'] as String? ??
          itemData?['userId'] as String? ??
          itemData?['creatorId'] as String?;

      if (creatorId != null) {
        await _notificationService.sendNotification(
          userId: creatorId,
          type: '${itemType}_approved',
          title: '${itemType == 'gig' ? 'Gig' : 'Course'} Approved! ✅',
          body: 'Your $itemType "$title" has been approved and is now live.',
          data: {'${itemType}Id': itemId, 'title': title},
          sendEmail: true,
        );
      }

      await _loadPendingPlugins();

      if (!mounted) return;
      setState(() => _isLoading = false);
      SnackbarHelper.showSuccess(context, '✓ "$title" approved');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      SnackbarHelper.showError(context, 'Error approving $itemType: $e');
      debugPrint('Error approving $itemType: $e');
    }
  }

  void _showRejectPluginDialog(String itemId, String itemType, String title) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject ${itemType == 'gig' ? 'Gig' : 'Course'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to reject this?'),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'Provide feedback...',
              ),
              maxLines: 3,
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
              Navigator.pop(context);
              _rejectPlugin(
                  itemId, itemType, title, reasonController.text.trim());
            },
          ),
        ],
      ),
    );
  }

  Future<void> _rejectPlugin(
      String itemId, String itemType, String title, String reason) async {
    if (!mounted) return;
    if (!await checkConnectivity(context,
        message: 'Cannot reject without internet.')) {
      return;
    }

    try {
      setState(() => _isLoading = true);

      final collection = itemType == 'gig' ? 'gigs' : 'courses';
      await _dbService.getCollection(collection).doc(itemId).update({
        'status': 'rejected',
        'approvalStatus': 'rejected',
        'isApproved': false,
        'isVerified': false,
        'rejectedAt': DateTime.now().toIso8601String(),
        if (reason.isNotEmpty) 'rejectionReason': reason,
      });

      // Get creator info
      final itemDoc =
          await _dbService.getCollection(collection).doc(itemId).get();
      final itemData = itemDoc.data() as Map<String, dynamic>?;
      final creatorId = itemData?['trainerId'] as String? ??
          itemData?['userId'] as String? ??
          itemData?['creatorId'] as String?;

      if (creatorId != null) {
        await _notificationService.sendNotification(
          userId: creatorId,
          type: '${itemType}_rejected',
          title: '${itemType == 'gig' ? 'Gig' : 'Course'} Rejected',
          body:
              'Your $itemType "$title" was rejected.${reason.isNotEmpty ? ' Reason: $reason' : ''}',
          data: {
            '${itemType}Id': itemId,
            'title': title,
            if (reason.isNotEmpty) 'reason': reason,
          },
          sendEmail: true,
        );
      }

      await _loadPendingPlugins();

      if (!mounted) return;
      setState(() => _isLoading = false);
      SnackbarHelper.showError(context, '✗ "$title" rejected');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      SnackbarHelper.showError(context, 'Error rejecting $itemType: $e');
      debugPrint('Error rejecting $itemType: $e');
    }
  }
}
