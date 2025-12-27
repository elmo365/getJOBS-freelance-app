import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/utils/colors.dart';

/// Admin Disputes Screen
/// Manages user disputes with two-way messaging, status tracking, and detailed views
/// Uses AppDesignSystem for consistent styling throughout
class AdminDisputesScreen extends StatefulWidget {
  const AdminDisputesScreen({super.key});

  @override
  State<AdminDisputesScreen> createState() => _AdminDisputesScreenState();
}

class _AdminDisputesScreenState extends State<AdminDisputesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  String _selectedStatus = 'open';
  String _searchQuery = '';
  List<Map<String, dynamic>> _disputes = [];
  List<Map<String, dynamic>> _filteredDisputes = [];
  Map<String, dynamic>? _selectedDispute;
  bool _isLoading = true;

  final List<String> _statusOptions = ['open', 'in-review', 'resolved'];
  final Map<String, String> _statusLabels = {
    'open': 'Open',
    'in-review': 'In Review',
    'resolved': 'Resolved',
  };

  final Map<String, Color> _statusColors = {
    'open': const Color(0xFFE53935),
    'in-review': const Color(0xFFFFA500),
    'resolved': AppDesignSystem.brandGreen,
  };

  @override
  void initState() {
    super.initState();
    _loadDisputes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadDisputes() async {
    try {
      setState(() => _isLoading = true);

      final snap = await _firestore
          .collection('disputes')
          .orderBy('createdAt', descending: true)
          .get();

      final disputes = <Map<String, dynamic>>[];
      for (var doc in snap.docs) {
        final data = doc.data();
        disputes.add({
          ...data,
          'id': doc.id,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        });
      }

      setState(() {
        _disputes = disputes;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading disputes: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = _disputes;

    if (_selectedStatus != 'all') {
      filtered = filtered.where((d) => d['status'] == _selectedStatus).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((d) {
        final title = (d['title'] ?? '').toString().toLowerCase();
        final description = (d['description'] ?? '').toString().toLowerCase();
        final reporterId = (d['reporterId'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return title.contains(query) ||
            description.contains(query) ||
            reporterId.contains(query);
      }).toList();
    }

    setState(() => _filteredDisputes = filtered);
  }

  Future<void> _updateDisputeStatus(String disputeId, String newStatus) async {
    try {
      await _firestore.collection('disputes').doc(disputeId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': 'admin_id_here',
      });

      // Log audit event
      await _firestore.collection('admin_audit_logs').add({
        'timestamp': FieldValue.serverTimestamp(),
        'action': 'update_dispute_status',
        'disputeId': disputeId,
        'newStatus': newStatus,
        'adminId': 'admin_id_here',
        'type': 'dispute_management',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dispute status updated to $newStatus')),
        );
        _loadDisputes();
        setState(() => _selectedDispute = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating dispute: $e')),
        );
      }
    }
  }

  Future<void> _addMessage(String disputeId) async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message cannot be empty')),
      );
      return;
    }

    try {
      final messageText = _messageController.text.trim();
      _messageController.clear();

      await _firestore
          .collection('disputes')
          .doc(disputeId)
          .collection('messages')
          .add({
        'senderId': 'admin_id_here',
        'senderType': 'admin',
        'message': messageText,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // Update dispute updatedAt
      await _firestore.collection('disputes').doc(disputeId).update({
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message sent')),
        );
        _loadDisputes();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }

  Future<void> _resolveDispute(String disputeId, String resolution) async {
    try {
      await _firestore.collection('disputes').doc(disputeId).update({
        'status': 'resolved',
        'resolution': resolution,
        'resolvedAt': FieldValue.serverTimestamp(),
        'resolvedBy': 'admin_id_here',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log audit event
      await _firestore.collection('admin_audit_logs').add({
        'timestamp': FieldValue.serverTimestamp(),
        'action': 'resolve_dispute',
        'disputeId': disputeId,
        'resolution': resolution,
        'adminId': 'admin_id_here',
        'type': 'dispute_management',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dispute resolved')),
        );
        _loadDisputes();
        setState(() => _selectedDispute = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error resolving dispute: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: 'Disputes Management',
        variant: AppBarVariant.primary,
      ),
      body: Row(
        children: [
          // Disputes List
          Expanded(
            flex: 1,
            child: Column(
              children: [
                // Status Filter Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDesignSystem.spaceM,
                      vertical: AppDesignSystem.spaceS,
                    ),
                    child: Row(
                      children: _statusOptions.map((status) {
                        final isSelected = _selectedStatus == status;
                        return Padding(
                          padding: EdgeInsets.only(right: AppDesignSystem.spaceS),
                          child: FilterChip(
                            label: Text(_statusLabels[status] ?? status),
                            selected: isSelected,
                            backgroundColor: AppDesignSystem.chipBackground,
                            selectedColor:
                                _statusColors[status]?.withValues(alpha: 0.2),
                            labelStyle:
                                AppDesignSystem.labelMedium(context).copyWith(
                              color: isSelected
                                  ? _statusColors[status]
                                  : AppDesignSystem.textSecondary,
                            ),
                            onSelected: (selected) {
                              setState(() {
                                _selectedStatus = status;
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
                      hintText: 'Search disputes...',
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
                else if (_filteredDisputes.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        'No disputes found',
                        style: AppDesignSystem.bodyLarge(context),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.all(AppDesignSystem.spaceM),
                      itemCount: _filteredDisputes.length,
                      itemBuilder: (context, index) {
                        final dispute = _filteredDisputes[index];
                        final isSelected = _selectedDispute?['id'] == dispute['id'];

                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: AppDesignSystem.spaceM,
                          ),
                          child: _DisputeListItem(
                            dispute: dispute,
                            isSelected: isSelected,
                            statusColor: _statusColors[dispute['status']]!,
                            onTap: () {
                              setState(() => _selectedDispute = dispute);
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Dispute Details Panel
          if (_selectedDispute != null)
            Expanded(
              flex: 1,
              child: Container(
                color: AppDesignSystem.superLightGrey,
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: EdgeInsets.all(AppDesignSystem.spaceM),
                      decoration: BoxDecoration(
                        color: botsWhite,
                        border: Border(
                          bottom: BorderSide(
                            color: AppDesignSystem.divider,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _selectedDispute!['title'] ?? 'Untitled',
                              style: AppDesignSystem.titleMedium(context),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() => _selectedDispute = null);
                            },
                          ),
                        ],
                      ),
                    ),

                    // Details and Messages
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(AppDesignSystem.spaceM),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Dispute Info Card
                            AppCard(
                              child: Padding(
                                padding: EdgeInsets.all(AppDesignSystem.spaceM),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInfoRow(
                                      'Status:',
                                      _statusLabels[_selectedDispute!['status']] ?? 'Unknown',
                                      _statusColors[_selectedDispute!['status']]!,
                                    ),
                                    SizedBox(height: AppDesignSystem.spaceM),
                                    _buildInfoRow(
                                      'Reporter:',
                                      _selectedDispute!['reporterName'] ?? _selectedDispute!['reporterId'] ?? 'Unknown',
                                    ),
                                    SizedBox(height: AppDesignSystem.spaceM),
                                    _buildInfoRow(
                                      'Respondent:',
                                      _selectedDispute!['respondentName'] ?? _selectedDispute!['respondentId'] ?? 'Unknown',
                                    ),
                                    SizedBox(height: AppDesignSystem.spaceM),
                                    _buildInfoRow(
                                      'Category:',
                                      _selectedDispute!['category'] ?? 'Uncategorized',
                                    ),
                                    SizedBox(height: AppDesignSystem.spaceM),
                                    _buildInfoRow(
                                      'Created:',
                                      DateFormat('MMM dd, yyyy - hh:mm a')
                                          .format(_selectedDispute!['createdAt'] as DateTime),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: AppDesignSystem.spaceL),

                            // Description
                            Text(
                              'Description',
                              style: AppDesignSystem.titleMedium(context),
                            ),
                            SizedBox(height: AppDesignSystem.spaceS),
                            AppCard(
                              child: Padding(
                                padding: EdgeInsets.all(AppDesignSystem.spaceM),
                                child: Text(
                                  _selectedDispute!['description'] ?? 'No description provided',
                                  style: AppDesignSystem.bodyMedium(context),
                                ),
                              ),
                            ),

                            SizedBox(height: AppDesignSystem.spaceL),

                            // Messages Section
                            Text(
                              'Messages',
                              style: AppDesignSystem.titleMedium(context),
                            ),
                            SizedBox(height: AppDesignSystem.spaceS),
                            _buildMessagesSection(_selectedDispute!['id']),

                            SizedBox(height: AppDesignSystem.spaceL),

                            // Action Buttons
                            if (_selectedDispute!['status'] != 'resolved')
                              Column(
                                children: [
                                  Text(
                                    'Actions',
                                    style: AppDesignSystem.titleMedium(context),
                                  ),
                                  SizedBox(height: AppDesignSystem.spaceS),
                                  Wrap(
                                    spacing: AppDesignSystem.spaceS,
                                    runSpacing: AppDesignSystem.spaceS,
                                    children: [
                                      if (_selectedDispute!['status'] != 'in-review')
                                        ElevatedButton(
                                          onPressed: () => _updateDisputeStatus(
                                            _selectedDispute!['id'],
                                            'in-review',
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppDesignSystem.brandBlue,
                                          ),
                                          child: Text(
                                            'Mark In Review',
                                            style: AppDesignSystem
                                                .labelMedium(context)
                                                .copyWith(color: botsWhite),
                                          ),
                                        ),
                                      ElevatedButton(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (dialogContext) =>
                                                _ResolutionDialog(
                                              onConfirm: (resolution) {
                                                _resolveDispute(
                                                  _selectedDispute!['id'],
                                                  resolution,
                                                );
                                              },
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppDesignSystem.brandGreen,
                                        ),
                                        child: Text(
                                          'Resolve',
                                          style: AppDesignSystem
                                              .labelMedium(context)
                                              .copyWith(color: botsWhite),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Message Input
                    if (_selectedDispute!['status'] != 'resolved')
                      Container(
                        padding: EdgeInsets.all(AppDesignSystem.spaceM),
                        decoration: BoxDecoration(
                          color: botsWhite,
                          border: Border(
                            top: BorderSide(
                              color: AppDesignSystem.divider,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                minLines: 1,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  hintText: 'Type a message...',
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        AppDesignSystem.borderRadiusM,
                                  ),
                                  contentPadding: EdgeInsets.all(
                                      AppDesignSystem.spaceM),
                                ),
                              ),
                            ),
                            SizedBox(width: AppDesignSystem.spaceM),
                            IconButton(
                              icon: Icon(
                                Icons.send,
                                color: AppDesignSystem.brandBlue,
                              ),
                              onPressed: () =>
                                  _addMessage(_selectedDispute!['id']),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, [Color? valueColor]) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppDesignSystem.labelMedium(context).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(width: AppDesignSystem.spaceS),
        Expanded(
          child: Text(
            value,
            style: AppDesignSystem.bodyMedium(context).copyWith(
              color: valueColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMessagesSection(String disputeId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('disputes')
          .doc(disputeId)
          .collection('messages')
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Padding(
            padding: EdgeInsets.all(AppDesignSystem.spaceM),
            child: const CircularProgressIndicator(),
          );
        }

        final messages = snapshot.data!.docs;
        if (messages.isEmpty) {
          return Padding(
            padding: EdgeInsets.all(AppDesignSystem.spaceM),
            child: Text(
              'No messages yet',
              style: AppDesignSystem.bodyMedium(context),
            ),
          );
        }

        return Column(
          children: messages.map((doc) {
            final msg = doc.data() as Map<String, dynamic>;
            final isAdmin = msg['senderType'] == 'admin';
            final timestamp = (msg['createdAt'] as Timestamp?)?.toDate();

            return Padding(
              padding: EdgeInsets.only(bottom: AppDesignSystem.spaceS),
              child: AppCard(
                variant: isAdmin
                    ? SurfaceVariant.elevated
                    : SurfaceVariant.standard,
                child: Padding(
                  padding: EdgeInsets.all(AppDesignSystem.spaceM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isAdmin ? 'Admin' : 'User',
                            style: AppDesignSystem.labelSmall(context)
                                .copyWith(
                              color: isAdmin
                                  ? AppDesignSystem.brandBlue
                                  : AppDesignSystem.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (timestamp != null)
                            Text(
                              DateFormat('MMM dd, hh:mm a')
                                  .format(timestamp),
                              style:
                                  AppDesignSystem.labelSmall(context),
                            ),
                        ],
                      ),
                      SizedBox(height: AppDesignSystem.spaceXS),
                      Text(
                        msg['message'] ?? '',
                        style: AppDesignSystem.bodyMedium(context),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

/// Dispute List Item
class _DisputeListItem extends StatelessWidget {
  final Map<String, dynamic> dispute;
  final bool isSelected;
  final Color statusColor;
  final VoidCallback onTap;

  const _DisputeListItem({
    required this.dispute,
    required this.isSelected,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = dispute['title'] ?? 'Untitled';
    final createdAt = dispute['createdAt'] as DateTime?;
    final formattedDate = createdAt != null
        ? DateFormat('MMM dd').format(createdAt)
        : 'Unknown';

    return Material(
      color: isSelected ? AppDesignSystem.primaryContainer(context) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: AppCard(
          variant: isSelected ? SurfaceVariant.elevated : SurfaceVariant.standard,
          child: Padding(
            padding: EdgeInsets.all(AppDesignSystem.spaceM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
                      ),
                    ),
                    SizedBox(width: AppDesignSystem.spaceS),
                    Expanded(
                      child: Text(
                        title.toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppDesignSystem.titleSmall(context),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppDesignSystem.spaceXS),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Category: ${dispute['category'] ?? 'Uncategorized'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppDesignSystem.labelSmall(context),
                      ),
                    ),
                    Text(
                      formattedDate,
                      style: AppDesignSystem.labelSmall(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Resolution Dialog
class _ResolutionDialog extends StatefulWidget {
  final Function(String) onConfirm;

  const _ResolutionDialog({required this.onConfirm});

  @override
  State<_ResolutionDialog> createState() => _ResolutionDialogState();
}

class _ResolutionDialogState extends State<_ResolutionDialog> {
  late TextEditingController _resolutionController;

  final List<String> _commonResolutions = [
    'In favor of reporter',
    'In favor of respondent',
    'Partial refund issued',
    'Full refund issued',
    'Warning issued',
    'Suspended pending appeal',
    'Case dismissed',
  ];

  @override
  void initState() {
    super.initState();
    _resolutionController = TextEditingController();
  }

  @override
  void dispose() {
    _resolutionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Resolve Dispute',
        style: AppDesignSystem.headlineSmall(context),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select or enter a resolution:',
              style: AppDesignSystem.bodyMedium(context),
            ),
            SizedBox(height: AppDesignSystem.spaceM),
            ..._commonResolutions.map((resolution) {
              return Padding(
                padding: EdgeInsets.only(bottom: AppDesignSystem.spaceS),
                child: InkWell(
                  onTap: () {
                    setState(() => _resolutionController.text = resolution);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDesignSystem.spaceM,
                      vertical: AppDesignSystem.spaceS,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _resolutionController.text == resolution
                            ? AppDesignSystem.brandBlue
                            : AppDesignSystem.divider,
                        width: _resolutionController.text == resolution ? 2 : 1,
                      ),
                      borderRadius: AppDesignSystem.borderRadiusM,
                      color: _resolutionController.text == resolution
                          ? AppDesignSystem.primaryContainer(context)
                          : Colors.transparent,
                    ),
                    child: Text(
                      resolution,
                      style: AppDesignSystem.bodyMedium(context).copyWith(
                        color: _resolutionController.text == resolution
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
              controller: _resolutionController,
              maxLines: 3,
              onChanged: (value) {
                setState(() {}); // Update button state
              },
              decoration: InputDecoration(
                hintText: 'Enter custom resolution or edit above...',
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
          onPressed: _resolutionController.text.isNotEmpty
              ? () {
                  widget.onConfirm(_resolutionController.text);
                  Navigator.pop(context);
                }
              : null,
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
