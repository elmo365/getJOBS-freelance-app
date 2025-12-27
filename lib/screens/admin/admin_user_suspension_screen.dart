import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/utils/colors.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';

class AdminUserSuspensionScreen extends StatefulWidget {
  const AdminUserSuspensionScreen({super.key});

  @override
  State<AdminUserSuspensionScreen> createState() =>
      _AdminUserSuspensionScreenState();
}

class _AdminUserSuspensionScreenState extends State<AdminUserSuspensionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Suspension dialog fields
  final _userEmailController = TextEditingController();
  final _reasonController = TextEditingController();
  DateTime? _suspensionEndDate;
  bool _isPermanent = false;
  bool _isLookingUpUser = false;
  String? _lookedUpUserId;
  String? _lookedUpUserName;

  List<Map<String, dynamic>> _activeSuspensions = [];
  List<Map<String, dynamic>> _filteredSuspensions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSuspensions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _userEmailController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadSuspensions() async {
    try {
      setState(() => _isLoading = true);

      final snapshot = await FirebaseFirestore.instance
          .collection('user_suspensions')
          .orderBy('createdAt', descending: true)
          .get();

      final suspensions = snapshot.docs
          .map((doc) => {
            'id': doc.id,
            ...doc.data(),
          })
          .toList();

      setState(() {
        _activeSuspensions = suspensions;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading suspensions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load suspensions: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    _filteredSuspensions = _activeSuspensions.where((suspension) {
      if (_searchQuery.isEmpty) return true;

      final userId = (suspension['userId'] as String? ?? '').toLowerCase();
      final reason = (suspension['reason'] as String? ?? '').toLowerCase();
      final adminEmail =
          (suspension['adminEmail'] as String? ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();

      return userId.contains(query) ||
          reason.contains(query) ||
          adminEmail.contains(query);
    }).toList();
  }

  Future<void> _lookupUserByEmail(String email) async {
    if (email.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a user email')),
      );
      return;
    }

    try {
      setState(() => _isLookingUpUser = true);

      // Query users collection by email
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        if (mounted) {
          setState(() => _isLookingUpUser = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('User with email "$email" not found')),
          );
        }
        return;
      }

      final userData = userQuery.docs.first;
      final userId = userData.id;
      final userName = userData.data()['name'] ?? userData.data()['firstName'] ?? 'Unknown';

      setState(() {
        _lookedUpUserId = userId;
        _lookedUpUserName = userName;
        _isLookingUpUser = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Found: $userName')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLookingUpUser = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error looking up user: $e')),
        );
      }
    }
  }

  Future<void> _createSuspension() async {
    if (_userEmailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a user email')),
      );
      return;
    }

    if (_lookedUpUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please click "Find User" to lookup the user first')),
      );
      return;
    }

    if (_reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reason')),
      );
      return;
    }

    if (!_isPermanent && _suspensionEndDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select an end date or mark as permanent')),
      );
      return;
    }

    try {
      final userId = _lookedUpUserId!;

      // Create suspension record
      final suspensionData = {
        'userId': userId,
        'userEmail': _userEmailController.text.trim().toLowerCase(),
        'userName': _lookedUpUserName,
        'reason': _reasonController.text.trim(),
        'suspendedAt': FieldValue.serverTimestamp(),
        'suspendedUntil':
            _isPermanent ? null : Timestamp.fromDate(_suspensionEndDate!),
        'isPermanent': _isPermanent,
        'adminEmail': FirebaseAuth.instance.currentUser?.email ?? 'system_admin',
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('user_suspensions')
          .add(suspensionData);

      // Update user's suspension status
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'isSuspended': true,
        'suspensionReason': _reasonController.text.trim(),
        'suspendedUntil':
            _isPermanent ? null : Timestamp.fromDate(_suspensionEndDate!),
      });

      // Log the action
      await FirebaseFirestore.instance.collection('admin_audit_logs').add({
        'action': 'suspend',
        'adminEmail': FirebaseAuth.instance.currentUser?.email ?? 'system_admin',
        'targetType': 'user',
        'targetId': userId,
        'targetEmail': _userEmailController.text.trim().toLowerCase(),
        'reason': _reasonController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'changes': {
          'isSuspended': {'before': false, 'after': true},
          'suspendedUntil': {
            'before': null,
            'after': _isPermanent ? 'permanent' : _suspensionEndDate
          }
        },
      });

      // Reset form
      _userEmailController.clear();
      _reasonController.clear();
      _suspensionEndDate = null;
      _isPermanent = false;
      _lookedUpUserId = null;
      _lookedUpUserName = null;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('User $_lookedUpUserName suspended successfully')),
        );
      }

      _loadSuspensions();

      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error creating suspension: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to suspend user: $e')),
        );
      }
    }
  }

  Future<void> _liftSuspension(String suspensionId, String userId) async {
    try {
      // Update suspension status to lifted
      await FirebaseFirestore.instance
          .collection('user_suspensions')
          .doc(suspensionId)
          .update({
        'status': 'lifted',
        'liftedAt': FieldValue.serverTimestamp(),
      });

      // Update user's suspension status
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isSuspended': false,
        'suspensionReason': null,
        'suspendedUntil': null,
      });

      // Log the action
      await FirebaseFirestore.instance.collection('admin_audit_logs').add({
        'action': 'lift_suspension',
        'adminEmail': FirebaseAuth.instance.currentUser?.email ?? 'system_admin',
        'targetType': 'user',
        'targetId': userId,
        'reason': 'Manually lifted by admin',
        'timestamp': FieldValue.serverTimestamp(),
        'changes': {
          'isSuspended': {'before': true, 'after': false},
        },
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Suspension lifted successfully')),
        );
      }

      _loadSuspensions();
    } catch (e) {
      debugPrint('Error lifting suspension: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to lift suspension: $e')),
        );
      }
    }
  }

  void _showCreateSuspensionDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Suspend User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Email Input Field
                TextField(
                  controller: _userEmailController,
                  decoration: InputDecoration(
                    labelText: 'User Email',
                    hintText: 'john@example.com',
                    border: const OutlineInputBorder(),
                    helperText: 'Enter user email to look up (easier than ID)',
                    suffixIcon: _isLookingUpUser
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _lookedUpUserId != null
                            ? Icon(Icons.check_circle, color: Colors.green[600])
                            : null,
                  ),
                  enabled: !_isLookingUpUser,
                ),
                SizedBox(height: AppDesignSystem.spaceS),
                
                // Lookup Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLookingUpUser
                        ? null
                        : () => _lookupUserByEmail(_userEmailController.text),
                    icon: const Icon(Icons.search),
                    label: const Text('Find User'),
                  ),
                ),

                // User Found Indicator
                if (_lookedUpUserId != null) ...[
                  SizedBox(height: AppDesignSystem.spaceM),
                  Container(
                    padding: EdgeInsets.all(AppDesignSystem.spaceS),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      border: Border.all(color: Colors.green[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '✓ Found: $_lookedUpUserName',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],

                SizedBox(height: AppDesignSystem.spaceM),
                TextField(
                  controller: _reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Reason for Suspension',
                    hintText: 'Explain why this user is being suspended',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: AppDesignSystem.spaceM),
                CheckboxListTile(
                  title: const Text('Permanent Suspension'),
                  value: _isPermanent,
                  onChanged: (value) {
                    setState(() {
                      _isPermanent = value ?? false;
                      if (_isPermanent) {
                        _suspensionEndDate = null;
                      }
                    });
                  },
                ),
                if (!_isPermanent) ...[
                  SizedBox(height: AppDesignSystem.spaceM),
                  OutlinedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(
                          const Duration(days: 7),
                        ),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 365),
                        ),
                      );
                      if (picked != null) {
                        setState(() => _suspensionEndDate = picked);
                      }
                    },
                    child: Text(
                      _suspensionEndDate != null
                          ? 'End Date: ${DateFormat('MMM d, yyyy').format(_suspensionEndDate!)}'
                          : 'Select End Date',
                    ),
                  ),
                ],
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
                _createSuspension();
                Navigator.pop(context);
              },
              child: const Text('Suspend'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppAppBar(
        title: 'User Suspensions',
        variant: AppBarVariant.primary,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateSuspensionDialog,
        icon: const Icon(Icons.add),
        label: const Text('Suspend User'),
        backgroundColor: AppDesignSystem.errorColor(context),
      ),
      body: Column(
        children: [
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
                hintText: 'Search by user ID, reason, or admin email...',
                prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                filled: true,
                fillColor: botsWhite,
                border: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusM,
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppDesignSystem.spaceM,
                  vertical: AppDesignSystem.spaceS,
                ),
              ),
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Active Suspensions'),
              Tab(text: 'Suspension History'),
            ],
          ),

          // Tab Content
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Active Suspensions Tab
                      _filteredSuspensions.isEmpty
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
                                    'No active suspensions',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredSuspensions.length,
                              itemBuilder: (context, index) {
                                final suspension = _filteredSuspensions[index];
                                final suspendedAt = (suspension['suspendedAt']
                                        as Timestamp?)
                                    ?.toDate();
                                final suspendedUntil =
                                    (suspension['suspendedUntil']
                                            as Timestamp?)
                                        ?.toDate();
                                final isPermanent =
                                    suspension['isPermanent'] as bool? ?? false;
                                final userId =
                                    suspension['userId'] as String? ?? '';
                                final reason =
                                    suspension['reason'] as String? ?? '';
                                final adminEmail =
                                    suspension['adminEmail'] as String? ?? '';

                                return AppCard(
                                  margin: EdgeInsets.symmetric(
                                    horizontal: AppDesignSystem.spaceM,
                                    vertical: AppDesignSystem.spaceS,
                                  ),
                                  padding: EdgeInsets.all(
                                      AppDesignSystem.spaceM),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
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
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal:
                                                        AppDesignSystem.spaceS,
                                                    vertical:
                                                        AppDesignSystem.spaceXS,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: isPermanent
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
                                                    isPermanent
                                                        ? 'Permanent'
                                                        : 'Temporary',
                                                    style: TextStyle(
                                                      color: isPermanent
                                                          ? Colors.red[600]
                                                          : AppDesignSystem
                                                              .brandYellow,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () =>
                                                _liftSuspension(suspension['id'],
                                                    userId),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppDesignSystem.brandGreen,
                                            ),
                                            child: const Text('Lift'),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: AppDesignSystem.spaceM),
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
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Suspended Since',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall,
                                              ),
                                              Text(
                                                suspendedAt != null
                                                    ? DateFormat('MMM d, yyyy HH:mm')
                                                        .format(suspendedAt)
                                                    : 'Unknown',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                            ],
                                          ),
                                          if (suspendedUntil != null)
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  'Suspended Until',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelSmall,
                                                ),
                                                Text(
                                                  DateFormat('MMM d, yyyy')
                                                      .format(suspendedUntil),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                      SizedBox(height: AppDesignSystem.spaceM),
                                      Text(
                                        'Suspended by: $adminEmail',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                      // Suspension History Tab
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('user_suspensions')
                            .where('status', isEqualTo: 'lifted')
                            .orderBy('liftedAt', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: CircularProgressIndicator(
                                color: colorScheme.primary,
                              ),
                            );
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return Center(
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
                                    'No suspension history',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: snapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              final doc = snapshot.data!.docs[index];
                              final suspension = doc.data()
                                  as Map<String, dynamic>;
                              final suspendedAt = (suspension['suspendedAt']
                                      as Timestamp?)
                                  ?.toDate();
                              final liftedAt =
                                  (suspension['liftedAt'] as Timestamp?)
                                      ?.toDate();
                              final userId =
                                  suspension['userId'] as String? ?? '';

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
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            userId,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal:
                                                AppDesignSystem.spaceS,
                                            vertical:
                                                AppDesignSystem.spaceXS,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppDesignSystem.brandGreen
                                                .withValues(alpha: 0.2),
                                            borderRadius: AppDesignSystem
                                                .borderRadiusS,
                                          ),
                                          child: Text(
                                            'Lifted',
                                            style: TextStyle(
                                              color: AppDesignSystem
                                                  .brandGreen,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: AppDesignSystem.spaceM),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Suspended',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall,
                                            ),
                                            Text(
                                              suspendedAt != null
                                                  ? DateFormat('MMM d, yyyy')
                                                      .format(suspendedAt)
                                                  : 'Unknown',
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
                                              'Lifted',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall,
                                            ),
                                            Text(
                                              liftedAt != null
                                                  ? DateFormat('MMM d, yyyy')
                                                      .format(liftedAt)
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
                          );
                        },
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
