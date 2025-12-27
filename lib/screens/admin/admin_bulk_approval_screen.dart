import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/utils/colors.dart';

/// Admin Bulk Approval Screen
/// Manages batch approval/rejection of pending items (jobs, companies, gigs, tenders)
/// Uses AppDesignSystem for consistent styling throughout
class AdminBulkApprovalScreen extends StatefulWidget {
  const AdminBulkApprovalScreen({super.key});

  @override
  State<AdminBulkApprovalScreen> createState() =>
      _AdminBulkApprovalScreenState();
}

class _AdminBulkApprovalScreenState extends State<AdminBulkApprovalScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  String _selectedType = 'all';
  String _searchQuery = '';
  List<Map<String, dynamic>> _pendingItems = [];
  List<Map<String, dynamic>> _filteredItems = [];
  final Map<String, bool> _selectedItems = {};
  final List<Map<String, dynamic>> _undoHistory = [];
  bool _isLoading = true;

  final List<String> _itemTypes = ['all', 'jobs', 'companies', 'gigs', 'tenders'];
  final Map<String, String> _typeLabels = {
    'all': 'All Pending',
    'jobs': 'Pending Jobs',
    'companies': 'Pending Companies',
    'gigs': 'Pending Gigs',
    'tenders': 'Pending Tenders',
  };

  @override
  void initState() {
    super.initState();
    _loadPendingItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingItems() async {
    try {
      setState(() => _isLoading = true);
      List<Map<String, dynamic>> allItems = [];

      // Load pending items from all collections
      final collections = ['jobs', 'companies', 'gigs', 'tenders'];
      for (final collectionName in collections) {
        // Jobs use 'status' and 'isVerified', others use 'approvalStatus'
        Query query = _firestore.collection(collectionName);
        
        if (collectionName == 'jobs') {
          query = query
              .where('status', isEqualTo: 'pending')
              .where('isVerified', isEqualTo: false);
        } else {
          query = query.where('approvalStatus', isEqualTo: 'pending');
        }

        final snap = await query.get();

        for (var doc in snap.docs) {
          final data = doc.data() as Map<String, dynamic>;
          allItems.add({
            ...data,
            'id': doc.id,
            'type': collectionName,
            'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          });
        }
      }

      // Sort by creation date (newest first)
      allItems.sort((a, b) =>
          (b['createdAt'] as DateTime).compareTo(a['createdAt'] as DateTime));

      setState(() {
        _pendingItems = allItems;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading items: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = _pendingItems;

    if (_selectedType != 'all') {
      filtered = filtered.where((item) => item['type'] == _selectedType).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        final title = (item['title'] ?? item['name'] ?? '').toString().toLowerCase();
        final description = (item['description'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return title.contains(query) || description.contains(query);
      }).toList();
    }

    setState(() => _filteredItems = filtered);
  }

  Future<void> _approveBulk() async {
    final selectedIds = _selectedItems.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select items to approve')),
      );
      return;
    }

    try {
      final batch = _firestore.batch();
      final nowLocal = DateTime.now();
      final nowFirestore = FieldValue.serverTimestamp();

      setState(() {
        _undoHistory.add({
          'action': 'bulk_approve',
          'items': selectedIds,
          'timestamp': nowLocal,
        });
      });

      for (final itemId in selectedIds) {
        final item = _pendingItems.firstWhere((i) => i['id'] == itemId);
        batch.update(
          _firestore.collection(item['type']).doc(itemId),
          {
            'approvalStatus': 'approved',
            'approvedAt': nowFirestore,
            'approvedBy': 'admin_id_here',
          },
        );
      }

      await _firestore.collection('admin_audit_logs').add({
        'timestamp': nowFirestore,
        'action': 'bulk_approve',
        'count': selectedIds.length,
        'items': selectedIds,
        'adminId': 'admin_id_here',
        'type': 'bulk_approval',
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Approved ${selectedIds.length} items'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => _undoBulkAction(),
            ),
          ),
        );
        _clearSelection();
        _loadPendingItems();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error approving items: $e')),
        );
      }
    }
  }

  Future<void> _rejectBulk() async {
    final selectedIds = _selectedItems.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select items to reject')),
      );
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => _RejectionReasonDialog(
        onConfirm: (reason) => _confirmRejectBulk(selectedIds, reason),
      ),
    );
  }

  Future<void> _confirmRejectBulk(
      List<String> selectedIds, String reason) async {
    try {
      final batch = _firestore.batch();
      final nowLocal = DateTime.now();
      final nowFirestore = FieldValue.serverTimestamp();

      setState(() {
        _undoHistory.add({
          'action': 'bulk_reject',
          'items': selectedIds,
          'reason': reason,
          'timestamp': nowLocal,
        });
      });

      for (final itemId in selectedIds) {
        final item = _pendingItems.firstWhere((i) => i['id'] == itemId);
        batch.update(
          _firestore.collection(item['type']).doc(itemId),
          {
            'approvalStatus': 'rejected',
            'rejectedAt': nowFirestore,
            'rejectionReason': reason,
            'rejectedBy': 'admin_id_here',
          },
        );
      }

      await _firestore.collection('admin_audit_logs').add({
        'timestamp': nowFirestore,
        'action': 'bulk_reject',
        'count': selectedIds.length,
        'items': selectedIds,
        'reason': reason,
        'adminId': 'admin_id_here',
        'type': 'bulk_approval',
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rejected ${selectedIds.length} items'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => _undoBulkAction(),
            ),
          ),
        );
        _clearSelection();
        _loadPendingItems();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rejecting items: $e')),
        );
      }
    }
  }

  Future<void> _undoBulkAction() async {
    if (_undoHistory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No actions to undo')),
      );
      return;
    }

    try {
      final lastAction = _undoHistory.removeLast();
      final itemIds = List<String>.from(lastAction['items'] as List);
      final batch = _firestore.batch();
      final nowFirestore = FieldValue.serverTimestamp();

      for (final itemId in itemIds) {
        final item = _pendingItems.firstWhere((i) => i['id'] == itemId);
        batch.update(
          _firestore.collection(item['type']).doc(itemId),
          {
            'approvalStatus': 'pending',
            'approvedAt': FieldValue.delete(),
            'approvedBy': FieldValue.delete(),
            'rejectedAt': FieldValue.delete(),
            'rejectionReason': FieldValue.delete(),
            'rejectedBy': FieldValue.delete(),
          },
        );
      }

      await _firestore.collection('admin_audit_logs').add({
        'timestamp': nowFirestore,
        'action': 'undo_bulk_action',
        'originalAction': lastAction['action'],
        'count': itemIds.length,
        'adminId': 'admin_id_here',
        'type': 'bulk_approval',
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Action undone successfully')),
        );
        _clearSelection();
        _loadPendingItems();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error undoing action: $e')),
        );
      }
    }
  }

  void _clearSelection() {
    setState(() => _selectedItems.clear());
  }

  void _toggleItem(String itemId) {
    setState(() {
      _selectedItems[itemId] = !(_selectedItems[itemId] ?? false);
    });
  }

  void _selectAll() {
    setState(() {
      for (final item in _filteredItems) {
        _selectedItems[item['id']] = true;
      }
    });
  }

  void _deselectAll() {
    setState(() => _selectedItems.clear());
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selectedItems.values.where((v) => v).length;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Bulk Approval',
        variant: AppBarVariant.primary,
      ),
      body: Column(
        children: [
          // Type Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppDesignSystem.spaceM,
                vertical: AppDesignSystem.spaceS,
              ),
              child: Row(
                children: _itemTypes.map((type) {
                  final isSelected = _selectedType == type;
                  return Padding(
                    padding: EdgeInsets.only(right: AppDesignSystem.spaceS),
                    child: FilterChip(
                      label: Text(_typeLabels[type] ?? type),
                      selected: isSelected,
                      backgroundColor: AppDesignSystem.chipBackground,
                      selectedColor:
                          AppDesignSystem.brandBlue.withValues(alpha: 0.2),
                      labelStyle:
                          AppDesignSystem.labelMedium(context).copyWith(
                        color: isSelected
                            ? AppDesignSystem.brandBlue
                            : AppDesignSystem.textSecondary,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _selectedType = type;
                          _applyFilters();
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Search Bar
          Padding(
            padding: EdgeInsets.all(AppDesignSystem.spaceM),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFilters();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by title or description...',
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
                  borderSide: BorderSide(
                    color: AppDesignSystem.divider,
                  ),
                ),
                filled: true,
                fillColor: botsWhite,
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _applyFilters();
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Content Area
          if (_isLoading)
            Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  color: AppDesignSystem.brandBlue,
                ),
              ),
            )
          else if (_filteredItems.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No pending items',
                  style: AppDesignSystem.bodyLarge(context),
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  // Selection Summary Bar
                  Container(
                    color: AppDesignSystem.superLightGrey,
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDesignSystem.spaceM,
                      vertical: AppDesignSystem.spaceS,
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: selectedCount == _filteredItems.length &&
                              selectedCount > 0,
                          onChanged: (value) {
                            if (value == true) {
                              _selectAll();
                            } else {
                              _deselectAll();
                            }
                          },
                        ),
                        Expanded(
                          child: Text(
                            '$selectedCount of ${_filteredItems.length} selected',
                            style: AppDesignSystem.bodyMedium(context),
                          ),
                        ),
                        if (selectedCount > 0)
                          TextButton(
                            onPressed: _deselectAll,
                            child: const Text('Clear'),
                          )
                      ],
                    ),
                  ),

                  // Items List
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.all(AppDesignSystem.spaceM),
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        final isSelected = _selectedItems[item['id']] ?? false;

                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: AppDesignSystem.spaceM,
                          ),
                          child: _BulkApprovalItemCard(
                            item: item,
                            isSelected: isSelected,
                            onSelectChanged: (selected) =>
                                _toggleItem(item['id']),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: selectedCount > 0
          ? Container(
              padding: EdgeInsets.all(AppDesignSystem.spaceM),
              decoration: BoxDecoration(
                color: botsWhite,
                boxShadow: AppDesignSystem.mediumShadow,
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _rejectBulk,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              AppDesignSystem.errorColor(context),
                          padding: EdgeInsets.symmetric(
                            vertical: AppDesignSystem.spaceM,
                          ),
                        ),
                        child: Text(
                          'Reject',
                          style: AppDesignSystem.labelLarge(context).copyWith(
                            color: AppDesignSystem.onError(context),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: AppDesignSystem.spaceM),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _approveBulk,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppDesignSystem.brandGreen,
                          padding: EdgeInsets.symmetric(
                            vertical: AppDesignSystem.spaceM,
                          ),
                        ),
                        child: Text(
                          'Approve',
                          style: AppDesignSystem.labelLarge(context).copyWith(
                            color: botsWhite,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

/// Bulk Approval Item Card
/// Displays pending item with type badge, title, description, and date
class _BulkApprovalItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isSelected;
  final Function(bool) onSelectChanged;

  const _BulkApprovalItemCard({
    required this.item,
    required this.isSelected,
    required this.onSelectChanged,
  });

  @override
  Widget build(BuildContext context) {
    final title = item['title'] ?? item['name'] ?? 'Untitled';
    final description = item['description'] ?? '';
    final type = item['type'] as String;
    final createdAt = (item['createdAt'] as DateTime?);
    final formattedDate = createdAt != null
        ? DateFormat('MMM dd, yyyy - hh:mm a').format(createdAt)
        : 'Unknown date';

    final typeColors = {
      'jobs': AppDesignSystem.brandBlue,
      'companies': AppDesignSystem.primaryColor,
      'gigs': AppDesignSystem.brandYellow,
      'tenders': AppDesignSystem.brandGreen,
    };

    final typeColor = typeColors[type] ?? AppDesignSystem.textSecondary;

    return AppCard(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onSelectChanged(!isSelected),
          child: Padding(
            padding: EdgeInsets.all(AppDesignSystem.spaceM),
            child: Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (value) => onSelectChanged(value ?? false),
                ),
                SizedBox(width: AppDesignSystem.spaceS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppDesignSystem.spaceS,
                              vertical: AppDesignSystem.spaceXS,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.15),
                              borderRadius: AppDesignSystem.borderRadiusS,
                            ),
                            child: Text(
                              type.toUpperCase(),
                              style:
                                  AppDesignSystem.labelSmall(context).copyWith(
                                color: typeColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(width: AppDesignSystem.spaceS),
                          Expanded(
                            child: Text(
                              title.toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  AppDesignSystem.titleMedium(context),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppDesignSystem.spaceXS),
                      Text(
                        description.toString().length > 100
                            ? '${description.toString().substring(0, 100)}...'
                            : description.toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppDesignSystem.bodySmall(context),
                      ),
                      SizedBox(height: AppDesignSystem.spaceS),
                      Text(
                        'Submitted: $formattedDate',
                        style: AppDesignSystem.labelSmall(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rejection Reason Dialog
/// Allows user to select from common rejection reasons or enter a custom one
class _RejectionReasonDialog extends StatefulWidget {
  final Function(String) onConfirm;

  const _RejectionReasonDialog({required this.onConfirm});

  @override
  State<_RejectionReasonDialog> createState() =>
      _RejectionReasonDialogState();
}

class _RejectionReasonDialogState extends State<_RejectionReasonDialog> {
  late TextEditingController _reasonController;

  final List<String> _commonReasons = [
    'Inappropriate content',
    'Incomplete information',
    'Duplicate listing',
    'Policy violation',
    'Low quality',
    'Spam/Suspicious activity',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Rejection Reason',
        style: AppDesignSystem.headlineSmall(context),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select or enter a reason for rejection:',
              style: AppDesignSystem.bodyMedium(context),
            ),
            SizedBox(height: AppDesignSystem.spaceM),
            ..._commonReasons.map((reason) {
              return Padding(
                padding: EdgeInsets.only(bottom: AppDesignSystem.spaceS),
                child: InkWell(
                  onTap: () {
                    setState(() => _reasonController.text = reason);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDesignSystem.spaceM,
                      vertical: AppDesignSystem.spaceS,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _reasonController.text == reason
                            ? AppDesignSystem.brandBlue
                            : AppDesignSystem.divider,
                        width: _reasonController.text == reason ? 2 : 1,
                      ),
                      borderRadius: AppDesignSystem.borderRadiusM,
                      color: _reasonController.text == reason
                          ? AppDesignSystem.primaryContainer(context)
                          : Colors.transparent,
                    ),
                    child: Text(
                      reason,
                      style: AppDesignSystem.bodyMedium(context).copyWith(
                        color: _reasonController.text == reason
                            ? AppDesignSystem.brandBlue
                            : AppDesignSystem.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            }),
            SizedBox(height: AppDesignSystem.spaceM),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              onChanged: (value) {
                setState(() {}); // Update button state
              },
              decoration: InputDecoration(
                hintText: 'Enter custom reason or edit above...',
                border: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
                ),
                contentPadding: EdgeInsets.all(AppDesignSystem.spaceM),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _reasonController.text.isNotEmpty
              ? () {
                  widget.onConfirm(_reasonController.text);
                  Navigator.pop(context);
                }
              : null,
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
