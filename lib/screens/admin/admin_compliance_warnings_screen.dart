import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/utils/colors.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';

class AdminComplianceWarningsScreen extends StatefulWidget {
  const AdminComplianceWarningsScreen({super.key});

  @override
  State<AdminComplianceWarningsScreen> createState() =>
      _AdminComplianceWarningsScreenState();
}

class _AdminComplianceWarningsScreenState
    extends State<AdminComplianceWarningsScreen> {
  final _searchController = TextEditingController();
  final _userIdController = TextEditingController();
  final _reasonController = TextEditingController();

  String _searchQuery = '';
  String _filterStatus = 'all'; // all, active, suspended
  bool _isLoading = true;
  List<Map<String, dynamic>> _allWarnings = [];
  List<Map<String, dynamic>> _filteredWarnings = [];

  // 3-strike system configuration
  static const int autoSuspendThreshold = 3;

  @override
  void initState() {
    super.initState();
    _loadWarnings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _userIdController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadWarnings() async {
    try {
      setState(() => _isLoading = true);

      final snapshot = await FirebaseFirestore.instance
          .collection('compliance_warnings')
          .orderBy('createdAt', descending: true)
          .get();

      final warnings = snapshot.docs
          .map((doc) => {
            'id': doc.id,
            ...doc.data(),
          })
          .toList();

      setState(() {
        _allWarnings = warnings;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading warnings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load warnings: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    _filteredWarnings = _allWarnings.where((warning) {
      // Filter by status
      final status = warning['status'] as String? ?? 'active';
      if (_filterStatus == 'active' && status != 'active') return false;
      if (_filterStatus == 'suspended' && status != 'auto_suspended') return false;

      // Filter by search
      if (_searchQuery.isNotEmpty) {
        final userId =
            (warning['userId'] as String? ?? '').toLowerCase();
        final reason =
            (warning['reason'] as String? ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();

        if (!userId.contains(query) && !reason.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> _issueWarning() async {
    if (_userIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a user ID')),
      );
      return;
    }

    if (_reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reason')),
      );
      return;
    }

    try {
      final userId = _userIdController.text.trim();

      // Verify user exists
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (!userDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not found')),
          );
        }
        return;
      }

      // Count existing warnings for this user
      final existingWarnings = await FirebaseFirestore.instance
          .collection('compliance_warnings')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();

      int warningCount = existingWarnings.docs.length;
      bool willAutoSuspend = (warningCount + 1) >= autoSuspendThreshold;

      // Create warning record
      final warningData = {
        'userId': userId,
        'reason': _reasonController.text.trim(),
        'severity': 'warning',
        'issueCount': warningCount + 1,
        'adminEmail': FirebaseAuth.instance.currentUser?.email ?? 'system_admin',
        'status': willAutoSuspend ? 'auto_suspended' : 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'issuedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('compliance_warnings')
          .add(warningData);

      // Log the action
      await FirebaseFirestore.instance.collection('admin_audit_logs').add({
        'action': 'warn',
        'adminEmail': FirebaseAuth.instance.currentUser?.email ?? 'system_admin',
        'targetType': 'user',
        'targetId': userId,
        'reason': _reasonController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'changes': {
          'warnings': {
            'before': warningCount,
            'after': warningCount + 1,
          }
        },
      });

      // If 3rd warning, auto-suspend
      if (willAutoSuspend) {
        // Create suspension record
        await FirebaseFirestore.instance
            .collection('user_suspensions')
            .add({
          'userId': userId,
          'reason':
              'Auto-suspended: 3 compliance warnings issued. Warnings: $_reasonController',
          'suspendedAt': FieldValue.serverTimestamp(),
          'suspendedUntil': null,
          'isPermanent': false,
          'adminEmail': FirebaseAuth.instance.currentUser?.email ?? 'system_admin',
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'isAutomatic': true,
        });

        // Update user suspension status
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'isSuspended': true,
          'suspensionReason': 'Auto-suspended: 3 compliance warnings',
          'complianceWarningCount': warningCount + 1,
        });

        // Log auto-suspension
        await FirebaseFirestore.instance.collection('admin_audit_logs').add({
          'action': 'auto_suspend',
          'adminEmail': 'system',
          'targetType': 'user',
          'targetId': userId,
          'reason': 'Automatic suspension: 3 compliance warnings threshold reached',
          'timestamp': FieldValue.serverTimestamp(),
          'changes': {
            'isSuspended': {'before': false, 'after': true},
            'trigger': {'before': null, 'after': 'compliance_warnings'}
          },
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  const Text('Warning issued. User auto-suspended (3 warnings)'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else {
        // Update warning count on user record
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'complianceWarningCount': warningCount + 1,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Warning issued (${warningCount + 1}/$autoSuspendThreshold)',
              ),
            ),
          );
        }
      }

      // Reset form
      _userIdController.clear();
      _reasonController.clear();

      _loadWarnings();

      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error issuing warning: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to issue warning: $e')),
        );
      }
    }
  }

  Future<void> _dismissWarning(String warningId) async {
    try {
      await FirebaseFirestore.instance
          .collection('compliance_warnings')
          .doc(warningId)
          .update({
        'status': 'dismissed',
        'dismissedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Warning dismissed')),
        );
      }

      _loadWarnings();
    } catch (e) {
      debugPrint('Error dismissing warning: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to dismiss warning: $e')),
        );
      }
    }
  }

  void _showIssueWarningDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Issue Compliance Warning'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _userIdController,
                decoration: const InputDecoration(
                  labelText: 'User ID',
                  hintText: 'Enter the user ID',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: AppDesignSystem.spaceM),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Reason for Warning',
                  hintText: 'Describe the violation',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: AppDesignSystem.spaceM),
              Container(
                padding: EdgeInsets.all(AppDesignSystem.spaceM),
                decoration: BoxDecoration(
                  color: AppDesignSystem.brandYellow.withValues(alpha: 0.1),
                  borderRadius: AppDesignSystem.borderRadiusM,
                  border: Border.all(
                    color: AppDesignSystem.brandYellow,
                  ),
                ),
                child: const Text(
                  '⚠️ 3 warnings = Automatic suspension',
                  style: TextStyle(fontSize: 12),
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
          TextButton(
            onPressed: () {
              _issueWarning();
              Navigator.pop(context);
            },
            child: const Text('Issue Warning'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Compliance Warnings',
        variant: AppBarVariant.primary,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showIssueWarningDialog,
        icon: const Icon(Icons.warning),
        label: const Text('Issue Warning'),
        backgroundColor: AppDesignSystem.brandYellow,
      ),
      body: Column(
        children: [
          // Search and Filter
          Padding(
            padding: EdgeInsets.all(AppDesignSystem.spaceM),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _applyFilters();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by user ID or reason...',
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
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppDesignSystem.spaceM,
                      vertical: AppDesignSystem.spaceS,
                    ),
                  ),
                ),
                SizedBox(height: AppDesignSystem.spaceM),

                // Status Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _filterStatus == 'all',
                        onSelected: (selected) {
                          setState(() {
                            _filterStatus = 'all';
                            _applyFilters();
                          });
                        },
                      ),
                      SizedBox(width: AppDesignSystem.spaceS),
                      FilterChip(
                        label: const Text('Active'),
                        selected: _filterStatus == 'active',
                        onSelected: (selected) {
                          setState(() {
                            _filterStatus = 'active';
                            _applyFilters();
                          });
                        },
                      ),
                      SizedBox(width: AppDesignSystem.spaceS),
                      FilterChip(
                        label: const Text('Auto-Suspended'),
                        selected: _filterStatus == 'suspended',
                        onSelected: (selected) {
                          setState(() {
                            _filterStatus = 'suspended';
                            _applyFilters();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Warnings List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                  )
                : _filteredWarnings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 64,
                              color: AppDesignSystem.brandGreen,
                            ),
                            SizedBox(height: AppDesignSystem.spaceM),
                            Text(
                              'No warnings',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredWarnings.length,
                        itemBuilder: (context, index) {
                          final warning = _filteredWarnings[index];
                          final userId =
                              warning['userId'] as String? ?? '';
                          final reason =
                              warning['reason'] as String? ?? '';
                          final issueCount =
                              warning['issueCount'] as int? ?? 1;
                          final status =
                              warning['status'] as String? ?? 'active';
                          final createdAt =
                              (warning['createdAt'] as Timestamp?)
                                  ?.toDate();
                          final adminEmail =
                              warning['adminEmail'] as String? ?? '';

                          final isAutoSuspended =
                              status == 'auto_suspended';
                          final isDismissed = status == 'dismissed';

                          return AppCard(
                            margin: EdgeInsets.symmetric(
                              horizontal: AppDesignSystem.spaceM,
                              vertical: AppDesignSystem.spaceS,
                            ),
                            padding: EdgeInsets.all(
                                AppDesignSystem.spaceM),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            userId,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall,
                                            overflow:
                                                TextOverflow.ellipsis,
                                          ),
                                          SizedBox(
                                              height: AppDesignSystem
                                                  .spaceXS),
                                          Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal:
                                                      AppDesignSystem
                                                          .spaceS,
                                                  vertical:
                                                      AppDesignSystem
                                                          .spaceXS,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isAutoSuspended
                                                      ? Colors.red
                                                          .withValues(
                                                              alpha: 0.2)
                                                      : AppDesignSystem
                                                          .brandYellow
                                                          .withValues(
                                                              alpha: 0.2),
                                                  borderRadius:
                                                      AppDesignSystem
                                                          .borderRadiusS,
                                                ),
                                                child: Text(
                                                  isAutoSuspended
                                                      ? '⛔ Auto-Suspended'
                                                      : isDismissed
                                                          ? '✓ Dismissed'
                                                          : '⚠️ Warning',
                                                  style: TextStyle(
                                                    color: isAutoSuspended
                                                        ? Colors.red[600]
                                                        : AppDesignSystem
                                                            .brandYellow,
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                  width: AppDesignSystem
                                                      .spaceS),
                                              // Warning count badge
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal:
                                                      AppDesignSystem
                                                          .spaceS,
                                                  vertical:
                                                      AppDesignSystem
                                                          .spaceXS,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: colorScheme
                                                      .surfaceContainer,
                                                  borderRadius:
                                                      AppDesignSystem
                                                          .borderRadiusS,
                                                ),
                                                child: Text(
                                                  '$issueCount/$autoSuspendThreshold',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!isDismissed)
                                      ElevatedButton(
                                        onPressed: () =>
                                            _dismissWarning(warning['id']),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppDesignSystem.brandGreen,
                                        ),
                                        child: const Text('Dismiss'),
                                      ),
                                  ],
                                ),
                                SizedBox(height: AppDesignSystem.spaceM),

                                // Reason
                                Text(
                                  'Reason',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium,
                                ),
                                SizedBox(
                                    height: AppDesignSystem.spaceXS),
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(
                                      AppDesignSystem.spaceS),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainer,
                                    borderRadius: AppDesignSystem
                                        .borderRadiusS,
                                  ),
                                  child: Text(
                                    reason,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ),
                                SizedBox(height: AppDesignSystem.spaceM),

                                // Footer info
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Issued by',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall,
                                        ),
                                        Text(
                                          adminEmail,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Date',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall,
                                        ),
                                        Text(
                                          createdAt != null
                                              ? DateFormat('MMM d, yyyy')
                                                  .format(createdAt)
                                              : 'Unknown',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
