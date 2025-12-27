import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';
import 'package:freelance_app/utils/app_design_system.dart';

/// Admin Content Moderation Screen
/// Reviews flagged content, approves or rejects based on moderation scores
/// Integrates with ContentModerationService for automated flagging
class AdminContentModerationScreen extends StatefulWidget {
  const AdminContentModerationScreen({super.key});

  @override
  State<AdminContentModerationScreen> createState() =>
      _AdminContentModerationScreenState();
}

class _AdminContentModerationScreenState
    extends State<AdminContentModerationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  String _selectedStatus = 'active';
  String _selectedSeverity = 'all';
  String _searchQuery = '';
  List<Map<String, dynamic>> _flags = [];
  List<Map<String, dynamic>> _filteredFlags = [];
  bool _isLoading = true;

  final List<String> _statusFilters = ['active', 'approved', 'rejected', 'all'];
  final List<String> _severityFilters = ['high', 'medium', 'low', 'all'];

  @override
  void initState() {
    super.initState();
    _loadFlags();
    _searchController.addListener(() {
      _searchQuery = _searchController.text;
      _applyFilters();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFlags() async {
    try {
      setState(() => _isLoading = true);

      Query query = _firestore.collection('compliance_warnings');

      // Filter by automated flags only
      query = query.where('automatedFlag', isEqualTo: true);

      // Order by creation date (newest first)
      query = query.orderBy('createdAt', descending: true);

      final snap = await query.get();

      setState(() {
        _flags = snap.docs.map((doc) {
          return {
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          };
        }).toList();
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading flags: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = _flags;

    // Filter by status
    if (_selectedStatus != 'all') {
      filtered =
          filtered.where((f) => (f['status'] ?? 'active') == _selectedStatus).toList();
    }

    // Filter by severity
    if (_selectedSeverity != 'all') {
      filtered = filtered
          .where((f) => (f['severity'] ?? 'low') == _selectedSeverity)
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((f) {
        final contentId = (f['contentId'] ?? '').toString().toLowerCase();
        final reason = (f['reason'] ?? []).toString().toLowerCase();
        return contentId.contains(query) || reason.contains(query);
      }).toList();
    }

    setState(() => _filteredFlags = filtered);
  }

  Future<void> _approveFlag(String flagId) async {
    try {
      await _firestore
          .collection('compliance_warnings')
          .doc(flagId)
          .update({
            'status': 'approved',
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Log action
      await _firestore.collection('admin_audit_logs').add({
        'timestamp': FieldValue.serverTimestamp(),
        'action': 'approve_flagged_content',
        'flagId': flagId,
        'adminAction': true,
        'type': 'content_moderation',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Flag approved')),
        );
        _loadFlags();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error approving flag: $e')),
        );
      }
    }
  }

  Future<void> _rejectFlag(String flagId, String contentId, String contentType) async {
    try {
      await _firestore
          .collection('compliance_warnings')
          .doc(flagId)
          .update({
            'status': 'rejected',
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Mark content as rejected in source collection if applicable
      final sourceCollections = ['jobs', 'companies', 'gigs', 'tenders', 'users'];
      for (final collection in sourceCollections) {
        try {
          final docSnap = await _firestore.collection(collection).doc(contentId).get();
          if (docSnap.exists) {
            await docSnap.reference.update({
              'approvalStatus': 'rejected',
              'rejectionReason': 'Content violates community guidelines',
              'rejectedAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
            break;
          }
        } catch (_) {
          // Continue to next collection
        }
      }

      // Log action
      await _firestore.collection('admin_audit_logs').add({
        'timestamp': FieldValue.serverTimestamp(),
        'action': 'reject_flagged_content',
        'flagId': flagId,
        'contentId': contentId,
        'contentType': contentType,
        'adminAction': true,
        'type': 'content_moderation',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Content rejected')),
        );
        _loadFlags();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rejecting flag: $e')),
        );
      }
    }
  }

  Future<void> _dismissFlag(String flagId) async {
    try {
      await _firestore
          .collection('compliance_warnings')
          .doc(flagId)
          .update({
            'status': 'dismissed',
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Log action
      await _firestore.collection('admin_audit_logs').add({
        'timestamp': FieldValue.serverTimestamp(),
        'action': 'dismiss_flagged_content',
        'flagId': flagId,
        'adminAction': true,
        'type': 'content_moderation',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Flag dismissed')),
        );
        _loadFlags();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error dismissing flag: $e')),
        );
      }
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: 'Content Moderation',
        variant: AppBarVariant.primary,
      ),
      body: Column(
        children: [
          // Search and filters
          Padding(
            padding: EdgeInsets.all(AppDesignSystem.spaceM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by content ID or reason',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppDesignSystem.spaceM,
                      vertical: AppDesignSystem.spaceS,
                    ),
                  ),
                ),
                SizedBox(height: AppDesignSystem.spaceM),
                // Status filter
                Wrap(
                  spacing: AppDesignSystem.spaceS,
                  children: _statusFilters.map((status) {
                    final isSelected = _selectedStatus == status;
                    return FilterChip(
                      label: Text(status.toUpperCase()),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedStatus = status;
                          _applyFilters();
                        });
                      },
                      backgroundColor: isSelected
                          ? AppDesignSystem.brandBlue
                          : Colors.transparent,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppDesignSystem.textPrimary,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? AppDesignSystem.brandBlue
                            : AppDesignSystem.divider,
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: AppDesignSystem.spaceM),
                // Severity filter
                Wrap(
                  spacing: AppDesignSystem.spaceS,
                  children: _severityFilters.map((severity) {
                    final isSelected = _selectedSeverity == severity;
                    return FilterChip(
                      label: Text(severity.toUpperCase()),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedSeverity = severity;
                          _applyFilters();
                        });
                      },
                      backgroundColor: isSelected
                          ? _getSeverityColor(severity)
                          : Colors.transparent,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppDesignSystem.textPrimary,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? _getSeverityColor(severity)
                            : AppDesignSystem.divider,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          // Flags list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFlags.isEmpty
                    ? Center(
                        child: Text(
                          'No flagged content',
                          style: AppDesignSystem.bodyMedium(context),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(AppDesignSystem.spaceM),
                        itemCount: _filteredFlags.length,
                        itemBuilder: (context, index) {
                          final flag = _filteredFlags[index];
                          return _FlagItemCard(
                            flag: flag,
                            onApprove: () => _approveFlag(flag['id']),
                            onReject: () => _rejectFlag(
                              flag['id'],
                              flag['contentId'] ?? '',
                              flag['contentType'] ?? '',
                            ),
                            onDismiss: () => _dismissFlag(flag['id']),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _FlagItemCard extends StatelessWidget {
  final Map<String, dynamic> flag;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onDismiss;

  const _FlagItemCard({
    required this.flag,
    required this.onApprove,
    required this.onReject,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final createdAt = (flag['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final severity = flag['severity'] ?? 'low';
    final status = flag['status'] ?? 'active';

    return AppCard(
      variant: SurfaceVariant.standard,
      margin: EdgeInsets.only(bottom: AppDesignSystem.spaceM),
      child: Padding(
        padding: EdgeInsets.all(AppDesignSystem.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        flag['contentType'] ?? 'Unknown',
                        style: AppDesignSystem.labelSmall(context).copyWith(
                          color: AppDesignSystem.textSecondary,
                        ),
                      ),
                      Text(
                        flag['contentId'] ?? 'Unknown',
                        style: AppDesignSystem.bodyMedium(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDesignSystem.spaceS,
                    vertical: AppDesignSystem.spaceXS,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: AppDesignSystem.borderRadiusS,
                  ),
                  child: Text(
                    '${flag['score'] ?? 0}/100',
                    style: AppDesignSystem.labelSmall(context).copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppDesignSystem.spaceM),
            // Severity badge
            Wrap(
              spacing: AppDesignSystem.spaceS,
              children: [
                Chip(
                  label: Text(
                    severity.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: _getSeverityColor(severity),
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDesignSystem.spaceS,
                    vertical: AppDesignSystem.spaceXS,
                  ),
                ),
                Chip(
                  label: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: _getStatusColor(status),
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDesignSystem.spaceS,
                    vertical: AppDesignSystem.spaceXS,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppDesignSystem.spaceM),
            // Reasons
            if ((flag['reason'] as List?)?.isNotEmpty ?? false)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Flagged Reasons:',
                    style: AppDesignSystem.labelMedium(context),
                  ),
                  SizedBox(height: AppDesignSystem.spaceS),
                  Wrap(
                    spacing: AppDesignSystem.spaceS,
                    runSpacing: AppDesignSystem.spaceXS,
                    children: (flag['reason'] as List)
                        .map((reason) => Chip(
                              label: Text(
                                reason.toString(),
                                style:
                                    AppDesignSystem.labelSmall(context).copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              backgroundColor: AppDesignSystem.brandBlue,
                              padding: EdgeInsets.symmetric(
                                horizontal: AppDesignSystem.spaceS,
                                vertical: AppDesignSystem.spaceXS,
                              ),
                            ))
                        .toList(),
                  ),
                  SizedBox(height: AppDesignSystem.spaceM),
                ],
              ),
            // Date
            Text(
              'Flagged: ${DateFormat('MMM d, yyyy h:mm a').format(createdAt)}',
              style: AppDesignSystem.labelSmall(context).copyWith(
                color: AppDesignSystem.textSecondary,
              ),
            ),
            SizedBox(height: AppDesignSystem.spaceM),
            // Action buttons
            if (status == 'active')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onApprove,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text(
                        'Approve',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(width: AppDesignSystem.spaceS),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onReject,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text(
                        'Reject',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(width: AppDesignSystem.spaceS),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDismiss,
                      child: const Text('Dismiss'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.blue;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'dismissed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
