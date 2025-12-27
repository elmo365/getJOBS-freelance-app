import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/standard_button.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/utils/colors.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';

class AdminAuditLogsScreen extends StatefulWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  State<AdminAuditLogsScreen> createState() => _AdminAuditLogsScreenState();
}

class _AdminAuditLogsScreenState extends State<AdminAuditLogsScreen> {
  final _searchController = TextEditingController();

  // Filters
  String _selectedAction = 'all';
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';

  // UI State
  bool _isLoading = true;
  List<Map<String, dynamic>> _auditLogs = [];
  List<Map<String, dynamic>> _filteredLogs = [];

  // Pagination
  final int _pageSize = 25;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadAuditLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAuditLogs() async {
    try {
      setState(() => _isLoading = true);

      final snapshot = await FirebaseFirestore.instance
          .collection('admin_audit_logs')
          .orderBy('timestamp', descending: true)
          .limit(500)
          .get();

      final logs = snapshot.docs
          .map((doc) => {
            'id': doc.id,
            ...doc.data(),
          })
          .toList();

      setState(() {
        _auditLogs = logs;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading audit logs: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load audit logs: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    _filteredLogs = _auditLogs.where((log) {
      // Filter by action
      if (_selectedAction != 'all') {
        final action = log['action'] as String? ?? '';
        if (action != _selectedAction) return false;
      }

      // Filter by date range
      if (_startDate != null) {
        final timestamp = (log['timestamp'] as Timestamp?)?.toDate();
        if (timestamp == null || timestamp.isBefore(_startDate!)) return false;
      }

      if (_endDate != null) {
        final timestamp = (log['timestamp'] as Timestamp?)?.toDate();
        if (timestamp == null || timestamp.isAfter(_endDate!)) return false;
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final adminEmail = (log['adminEmail'] as String? ?? '').toLowerCase();
        final targetType = (log['targetType'] as String? ?? '').toLowerCase();
        final targetId = (log['targetId'] as String? ?? '').toLowerCase();
        final reason = (log['reason'] as String? ?? '').toLowerCase();

        final query = _searchQuery.toLowerCase();
        if (!adminEmail.contains(query) &&
            !targetType.contains(query) &&
            !targetId.contains(query) &&
            !reason.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _applyFilters();
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedAction = 'all';
      _startDate = null;
      _endDate = null;
      _searchQuery = '';
      _searchController.clear();
      _currentPage = 0;
      _applyFilters();
    });
  }

  int get _totalPages => (_filteredLogs.length / _pageSize).ceil();

  List<Map<String, dynamic>> get _paginatedLogs {
    final start = _currentPage * _pageSize;
    final end = start + _pageSize;
    return _filteredLogs.sublist(
      start,
      end > _filteredLogs.length ? _filteredLogs.length : end,
    );
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'approve':
        return AppDesignSystem.brandGreen;
      case 'reject':
        return AppDesignSystem.errorColor(context);
      case 'suspend':
        return Colors.red[600]!;
      case 'warn':
        return AppDesignSystem.brandYellow;
      case 'rate':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getActionLabel(String action) {
    switch (action) {
      case 'approve':
        return 'Approved';
      case 'reject':
        return 'Rejected';
      case 'suspend':
        return 'Suspended';
      case 'warn':
        return 'Warned';
      case 'rate':
        return 'Rated';
      default:
        return action;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Audit Logs',
        variant: AppBarVariant.primary,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filters Section
            Container(
              color: colorScheme.surface,
              padding: EdgeInsets.all(AppDesignSystem.spaceM),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _currentPage = 0;
                        _applyFilters();
                      });
                    },
                    decoration: InputDecoration(
                      hintText:
                          'Search by email, target type, ID, or reason...',
                      prefixIcon: Icon(Icons.search, color: colorScheme.primary),
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
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppDesignSystem.spaceM,
                        vertical: AppDesignSystem.spaceS,
                      ),
                    ),
                  ),
                  SizedBox(height: AppDesignSystem.spaceM),

                  // Filter Row 1: Action Dropdown + Date Range
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          value: _selectedAction,
                          isExpanded: true,
                          underline: Container(
                            height: 1,
                            color: colorScheme.outlineVariant,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'all',
                              child: Text('All Actions'),
                            ),
                            DropdownMenuItem(
                              value: 'approve',
                              child: Text('Approvals'),
                            ),
                            DropdownMenuItem(
                              value: 'reject',
                              child: Text('Rejections'),
                            ),
                            DropdownMenuItem(
                              value: 'suspend',
                              child: Text('Suspensions'),
                            ),
                            DropdownMenuItem(
                              value: 'warn',
                              child: Text('Warnings'),
                            ),
                            DropdownMenuItem(
                              value: 'rate',
                              child: Text('Ratings'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedAction = value ?? 'all';
                              _currentPage = 0;
                              _applyFilters();
                            });
                          },
                        ),
                      ),
                      SizedBox(width: AppDesignSystem.spaceM),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _selectDateRange,
                          child: Text(
                            _startDate != null && _endDate != null
                                ? '${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d').format(_endDate!)}'
                                : 'Date Range',
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppDesignSystem.spaceM),

                  // Filter Row 2: Clear Button + Log Count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StandardButton(
                        label: 'Clear Filters',
                        onPressed: _clearFilters,
                      ),
                      Text(
                        '${_filteredLogs.length} logs',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Logs List
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: colorScheme.primary,
                      ),
                    )
                  : _filteredLogs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history,
                                size: 64,
                                color: colorScheme.outlineVariant,
                              ),
                              SizedBox(height: AppDesignSystem.spaceM),
                              Text(
                                'No audit logs found',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        )
                      : CustomScrollView(
                          slivers: [
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final log = _paginatedLogs[index];
                                  final timestamp =
                                      (log['timestamp'] as Timestamp?)
                                          ?.toDate();
                                  final action =
                                      log['action'] as String? ?? '';
                                  final adminEmail = log['adminEmail']
                                      as String? ??
                                      'Unknown';
                                  final targetType =
                                      log['targetType'] as String? ?? '';
                                  final targetId =
                                      log['targetId'] as String? ?? '';
                                  final reason =
                                      log['reason'] as String? ?? '';
                                  final changes = log['changes']
                                      as Map<String, dynamic>? ??
                                      {};

                                  return AppCard(
                                    margin: EdgeInsets.symmetric(
                                      horizontal: AppDesignSystem.spaceM,
                                      vertical: AppDesignSystem.spaceS,
                                    ),
                                    padding: EdgeInsets.all(
                                        AppDesignSystem.spaceM),
                                    child: ExpansionTile(
                                      title: Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(
                                                AppDesignSystem.spaceXS),
                                            decoration: BoxDecoration(
                                              color: _getActionColor(action)
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                                  AppDesignSystem
                                                      .borderRadiusS,
                                            ),
                                            child: Text(
                                              _getActionLabel(action),
                                              style: TextStyle(
                                                color:
                                                    _getActionColor(action),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                              width:
                                                  AppDesignSystem.spaceM),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .start,
                                              children: [
                                                Text(
                                                  adminEmail,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  '$targetType: $targetId',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      subtitle: Text(
                                        timestamp != null
                                            ? DateFormat('MMM d, yyyy HH:mm')
                                                .format(timestamp)
                                            : 'Unknown date',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall,
                                      ),
                                      children: [
                                        Divider(
                                          height: 0,
                                          color: colorScheme.outlineVariant,
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal:
                                                AppDesignSystem.spaceM,
                                            vertical:
                                                AppDesignSystem.spaceM,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (reason.isNotEmpty) ...[
                                                Text(
                                                  'Reason',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelMedium,
                                                ),
                                                SizedBox(
                                                    height: AppDesignSystem
                                                        .spaceXS),
                                                Container(
                                                  width: double.infinity,
                                                  padding: EdgeInsets.all(
                                                      AppDesignSystem
                                                          .spaceS),
                                                  decoration: BoxDecoration(
                                                    color: colorScheme
                                                        .surfaceContainer,
                                                    borderRadius:
                                                        AppDesignSystem
                                                            .borderRadiusS,
                                                  ),
                                                  child: Text(
                                                    reason,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall,
                                                  ),
                                                ),
                                                SizedBox(
                                                    height: AppDesignSystem
                                                        .spaceM),
                                              ],
                                              if (changes.isNotEmpty) ...[
                                                Text(
                                                  'Changes',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelMedium,
                                                ),
                                                SizedBox(
                                                    height: AppDesignSystem
                                                        .spaceXS),
                                                ...changes.entries.map((entry) {
                                                  final oldValue = entry
                                                      .value['before'] ??
                                                      'N/A';
                                                  final newValue = entry
                                                      .value['after'] ??
                                                      'N/A';
                                                  return Padding(
                                                    padding: EdgeInsets.only(
                                                      bottom: AppDesignSystem
                                                          .spaceS,
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          entry.key,
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                'Before: $oldValue',
                                                                style:
                                                                    TextStyle(
                                                                  color: colorScheme
                                                                      .outlineVariant,
                                                                  fontSize:
                                                                      11,
                                                                ),
                                                              ),
                                                            ),
                                                            Icon(
                                                              Icons
                                                                  .arrow_forward,
                                                              size: 14,
                                                              color: colorScheme
                                                                  .outlineVariant,
                                                            ),
                                                            Expanded(
                                                              child: Text(
                                                                'After: $newValue',
                                                                style:
                                                                    TextStyle(
                                                                  color: colorScheme
                                                                      .primary,
                                                                  fontSize:
                                                                      11,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                childCount: _paginatedLogs.length,
                              ),
                            ),
                            // Pagination Controls
                            if (_totalPages > 1)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.all(
                                      AppDesignSystem.spaceM),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      StandardButton(
                                        label: 'Previous',
                                        onPressed: _currentPage > 0
                                            ? () {
                                                setState(
                                                    () => _currentPage--);
                                              }
                                            : null,
                                      ),
                                      Text(
                                        'Page ${_currentPage + 1} of $_totalPages',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                      StandardButton(
                                        label: 'Next',
                                        onPressed:
                                            _currentPage < _totalPages - 1
                                                ? () {
                                                    setState(
                                                        () =>
                                                            _currentPage++);
                                                  }
                                                : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
