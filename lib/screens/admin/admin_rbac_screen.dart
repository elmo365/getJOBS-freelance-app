import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/utils/colors.dart';

/// Admin Role-Based Access Control (RBAC) Management Screen
/// Manages admin roles, permissions, and role assignments
/// Uses AppDesignSystem for consistent styling
class AdminRoleBasedAccessScreen extends StatefulWidget {
  const AdminRoleBasedAccessScreen({super.key});

  @override
  State<AdminRoleBasedAccessScreen> createState() =>
      _AdminRoleBasedAccessScreenState();
}

class _AdminRoleBasedAccessScreenState
    extends State<AdminRoleBasedAccessScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();

  String _selectedTab = 'roles'; // 'roles', 'admins', or 'trainers'
  String _searchQuery = '';
  List<Map<String, dynamic>> _adminUsers = [];
  List<Map<String, dynamic>> _filteredAdmins = [];
  final List<Map<String, dynamic>> _trainerUsers = [];
  final List<Map<String, dynamic>> _filteredTrainers = [];
  Map<String, dynamic>? _selectedAdmin;
  bool _isLoading = true;

  // Role definitions
  final Map<String, String> _roleDescriptions = {
    'superAdmin': 'Full system access - manages all features and admins',
    'moderator': 'Content moderation - approves jobs, companies, and user content',
    'analyst': 'Analytics and reporting - generates reports and insights',
    'financial': 'Finance management - handles payments and transactions',
    'support': 'Customer support - manages tickets and user inquiries',
    'trainer': 'Training provider - creates and manages courses',
  };

  final Map<String, List<String>> _rolePermissions = {
    'superAdmin': [
      'manage_admins',
      'manage_roles',
      'approve_content',
      'manage_finances',
      'view_analytics',
      'manage_users',
      'manage_disputes',
      'system_settings',
    ],
    'moderator': [
      'approve_jobs',
      'approve_companies',
      'approve_gigs',
      'manage_disputes',
      'issue_warnings',
      'suspend_users',
    ],
    'analyst': [
      'view_analytics',
      'generate_reports',
      'view_metrics',
      'export_data',
    ],
    'financial': [
      'view_transactions',
      'process_refunds',
      'view_wallet',
      'generate_financial_reports',
    ],
    'support': [
      'manage_disputes',
      'contact_users',
      'view_tickets',
      'resolve_issues',
    ],
    'trainer': [
      'create_courses',
      'edit_courses',
      'delete_courses',
      'view_enrollments',
      'grade_assignments',
    ],
  };

  final Map<String, Color> _roleColors = {
    'superAdmin': const Color(0xFFD32F2F),
    'moderator': const Color(0xFFF57C00),
    'analyst': AppDesignSystem.brandBlue,
    'financial': AppDesignSystem.brandGreen,
    'support': const Color(0xFF0097A7),
    'trainer': Colors.amber,
  };

  @override
  void initState() {
    super.initState();
    _loadAdminUsers();
    _loadTrainerUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminUsers() async {
    try {
      setState(() => _isLoading = true);

      // Load all admins with their roles
      final adminSnap = await _firestore.collection('admin_roles').get();
      final admins = <Map<String, dynamic>>[];

      for (var doc in adminSnap.docs) {
        final data = doc.data();
        // Get user info
        final userSnap =
            await _firestore.collection('users').doc(doc.id).get();
        final userData = userSnap.data() ?? {};

        admins.add({
          ...data,
          'userId': doc.id,
          'email': userData['email'] ?? 'Unknown',
          'name': userData['name'] ?? userData['firstName'] ?? 'Unknown',
          'assignedAt': (data['assignedAt'] as Timestamp?)?.toDate() ??
              DateTime.now(),
        });
      }

      // Sort by role hierarchy
      admins.sort((a, b) {
        const roleOrder = [
          'superAdmin',
          'moderator',
          'analyst',
          'financial',
          'support'
        ];
        final aIndex = roleOrder.indexOf(a['role'] ?? 'support');
        final bIndex = roleOrder.indexOf(b['role'] ?? 'support');
        return aIndex.compareTo(bIndex);
      });

      setState(() {
        _adminUsers = admins;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading admins: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filteredAdmins = _adminUsers;
    List<Map<String, dynamic>> filteredTrainers = _trainerUsers;

    if (_searchQuery.isNotEmpty) {
      filteredAdmins = filteredAdmins.where((admin) {
        final email = (admin['email'] ?? '').toString().toLowerCase();
        final name = (admin['name'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return email.contains(query) || name.contains(query);
      }).toList();

      filteredTrainers = filteredTrainers.where((trainer) {
        final email = (trainer['email'] ?? '').toString().toLowerCase();
        final name = (trainer['name'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return email.contains(query) || name.contains(query);
      }).toList();
    }

    setState(() {
      _filteredAdmins = filteredAdmins;
      _filteredTrainers.clear();
      _filteredTrainers.addAll(filteredTrainers);
    });
  }

  Future<void> _assignRole(String userId, String newRole) async {
    try {
      await _firestore.collection('admin_roles').doc(userId).set({
        'role': newRole,
        'permissions': _rolePermissions[newRole] ?? [],
        'assignedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update user's isAdmin flag
      await _firestore.collection('users').doc(userId).update({
        'isAdmin': true,
        'adminRole': newRole,
      });

      // Log audit event
      await _firestore.collection('admin_audit_logs').add({
        'timestamp': FieldValue.serverTimestamp(),
        'action': 'assign_admin_role',
        'targetUserId': userId,
        'role': newRole,
        'adminId': _auth.currentUser?.uid ?? 'system',
        'type': 'role_management',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Role assigned: $newRole')),
        );
        _loadAdminUsers();
        setState(() => _selectedAdmin = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error assigning role: $e')),
        );
      }
    }
  }

  Future<void> _removeAdminRole(String userId) async {
    try {
      await _firestore.collection('admin_roles').doc(userId).delete();

      // Update user's isAdmin flag
      await _firestore.collection('users').doc(userId).update({
        'isAdmin': false,
      });

      // Log audit event
      await _firestore.collection('admin_audit_logs').add({
        'timestamp': FieldValue.serverTimestamp(),
        'action': 'remove_admin_role',
        'targetUserId': userId,
        'adminId': _auth.currentUser?.uid ?? 'system',
        'type': 'role_management',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin role removed')),
        );
        _loadAdminUsers();
        setState(() => _selectedAdmin = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing role: $e')),
        );
      }
    }
  }

  Future<void> _loadTrainerUsers() async {
    try {
      setState(() => _isLoading = true);

      // Load all users with trainer role
      final usersSnap = await _firestore
          .collection('users')
          .where('roles', arrayContains: 'trainer')
          .get();

      final trainers = <Map<String, dynamic>>[];

      for (var doc in usersSnap.docs) {
        final data = doc.data();
        trainers.add({
          'userId': doc.id,
          'email': data['email'] ?? 'Unknown',
          'name': data['name'] ?? 'Unknown',
          'userImage': data['user_image'],
          'bio': data['bio'] ?? '',
        });
      }

      setState(() {
        _trainerUsers.clear();
        _trainerUsers.addAll(trainers);
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading trainers: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _revokeTrainerRole(String userId, String email) async {
    try {
      // Remove trainer role from user.roles array
      await _firestore.collection('users').doc(userId).update({
        'roles': FieldValue.arrayRemove(['trainer']),
      });

      // Log audit event
      await _firestore.collection('admin_audit_logs').add({
        'timestamp': FieldValue.serverTimestamp(),
        'action': 'revoke_trainer_role',
        'targetUserEmail': email,
        'targetUserId': userId,
        'adminId': _auth.currentUser?.uid ?? 'system',
        'type': 'role_management',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trainer role revoked')),
        );
        _loadTrainerUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error revoking role: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: 'Admin Roles & Access Control',
        variant: AppBarVariant.primary,
      ),
      body: Column(
        children: [
          // Tab Selector
          Padding(
            padding: EdgeInsets.all(AppDesignSystem.spaceM),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(
                    width: 140,
                    child: _buildTabButton('roles', 'Role Definitions'),
                  ),
                  SizedBox(width: AppDesignSystem.spaceS),
                  SizedBox(
                    width: 140,
                    child: _buildTabButton('admins', 'Admin Users'),
                  ),
                  SizedBox(width: AppDesignSystem.spaceS),
                  SizedBox(
                    width: 140,
                    child: _buildTabButton('trainers', 'Trainers'),
                  ),
                ],
              ),
            ),
          ),

          // Search Bar (for admins and trainers tabs)
          if (_selectedTab == 'admins' || _selectedTab == 'trainers')
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppDesignSystem.spaceM,
                vertical: AppDesignSystem.spaceS,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _applyFilters();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
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
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppDesignSystem.brandBlue,
                    ),
                  )
                : _selectedTab == 'roles'
                    ? _buildRoleDefinitions()
                    : _selectedTab == 'admins'
                        ? _buildAdminsList()
                        : _buildTrainersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tabId, String label) {
    final isSelected = _selectedTab == tabId;
    return ElevatedButton(
      onPressed: () => setState(() => _selectedTab = tabId),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? AppDesignSystem.brandBlue
            : AppDesignSystem.chipBackground,
        elevation: isSelected ? 4 : 0,
      ),
      child: Text(
        label,
        style: AppDesignSystem.labelMedium(context).copyWith(
          color: isSelected ? botsWhite : AppDesignSystem.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildRoleDefinitions() {
    return ListView.builder(
      padding: EdgeInsets.all(AppDesignSystem.spaceM),
      itemCount: _roleDescriptions.length,
      itemBuilder: (context, index) {
        final roles = _roleDescriptions.entries.toList();
        final roleId = roles[index].key;
        final description = roles[index].value;
        final permissions = _rolePermissions[roleId] ?? [];
        final color = _roleColors[roleId] ?? AppDesignSystem.brandBlue;

        return Padding(
          padding: EdgeInsets.only(bottom: AppDesignSystem.spaceM),
          child: AppCard(
            child: Padding(
              padding: EdgeInsets.all(AppDesignSystem.spaceM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Role Header
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(AppDesignSystem.spaceS),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: AppDesignSystem.borderRadiusM,
                        ),
                        child: Icon(
                          Icons.admin_panel_settings,
                          color: color,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: AppDesignSystem.spaceM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatRoleName(roleId),
                              style: AppDesignSystem.titleMedium(context),
                            ),
                            SizedBox(height: AppDesignSystem.spaceXS),
                            Text(
                              description,
                              style: AppDesignSystem.bodySmall(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: AppDesignSystem.spaceM),

                  // Permissions List
                  Text(
                    'Permissions',
                    style: AppDesignSystem.labelMedium(context).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: AppDesignSystem.spaceS),
                  Wrap(
                    spacing: AppDesignSystem.spaceS,
                    runSpacing: AppDesignSystem.spaceS,
                    children: permissions.map((permission) {
                      return Chip(
                        label: Text(
                          _formatPermission(permission),
                          style: AppDesignSystem.labelSmall(context),
                        ),
                        backgroundColor: color.withValues(alpha: 0.1),
                        labelStyle: TextStyle(color: color),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdminsList() {
    if (_filteredAdmins.isEmpty) {
      return Center(
        child: Text(
          'No admins found',
          style: AppDesignSystem.bodyLarge(context),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(AppDesignSystem.spaceM),
      itemCount: _filteredAdmins.length,
      itemBuilder: (context, index) {
        final admin = _filteredAdmins[index];
        final roleColor = _roleColors[admin['role']] ?? AppDesignSystem.brandBlue;
        final isSelected = _selectedAdmin?['userId'] == admin['userId'];

        return Padding(
          padding: EdgeInsets.only(bottom: AppDesignSystem.spaceM),
          child: Material(
            color: isSelected ? AppDesignSystem.primaryContainer(context) : Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _selectedAdmin = admin),
              child: AppCard(
                variant: isSelected ? SurfaceVariant.elevated : SurfaceVariant.standard,
                child: Padding(
                  padding: EdgeInsets.all(AppDesignSystem.spaceM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  admin['name'] ?? 'Unknown',
                                  style: AppDesignSystem.titleSmall(context),
                                ),
                                SizedBox(height: AppDesignSystem.spaceXS),
                                Text(
                                  admin['email'] ?? 'No email',
                                  style: AppDesignSystem.bodySmall(context),
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
                              color: roleColor.withValues(alpha: 0.15),
                              borderRadius: AppDesignSystem.borderRadiusM,
                            ),
                            child: Text(
                              _formatRoleName(admin['role']),
                              style: AppDesignSystem.labelSmall(context)
                                  .copyWith(
                                color: roleColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (isSelected) ...[
                        SizedBox(height: AppDesignSystem.spaceM),
                        Text(
                          'Change Role',
                          style: AppDesignSystem.labelMedium(context)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: AppDesignSystem.spaceS),
                        Wrap(
                          spacing: AppDesignSystem.spaceS,
                          runSpacing: AppDesignSystem.spaceS,
                          children:
                              _roleDescriptions.keys.map((role) {
                            return OutlinedButton(
                              onPressed: () =>
                                  _assignRole(admin['userId'], role),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: _roleColors[role] ??
                                      AppDesignSystem.brandBlue,
                                ),
                              ),
                              child: Text(
                                _formatRoleName(role),
                                style: AppDesignSystem.labelSmall(context),
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: AppDesignSystem.spaceM),
                        ElevatedButton(
                          onPressed: () =>
                              _removeAdminRole(admin['userId']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD32F2F),
                          ),
                          child: Text(
                            'Remove Admin Access',
                            style: AppDesignSystem.labelMedium(context)
                                .copyWith(color: botsWhite),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrainersList() {
    if (_filteredTrainers.isEmpty) {
      return Center(
        child: Text(
          'No trainers found',
          style: AppDesignSystem.bodyLarge(context),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(AppDesignSystem.spaceM),
      itemCount: _filteredTrainers.length,
      itemBuilder: (context, index) {
        final trainer = _filteredTrainers[index];
        final trainerColor = Colors.amber;

        return Padding(
          padding: EdgeInsets.only(bottom: AppDesignSystem.spaceM),
          child: AppCard(
            child: Padding(
              padding: EdgeInsets.all(AppDesignSystem.spaceM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: trainer['userImage'] != null
                            ? NetworkImage(trainer['userImage']!)
                            : null,
                        backgroundColor: trainerColor.withValues(alpha: 0.2),
                        child: trainer['userImage'] == null
                            ? Icon(Icons.school, color: trainerColor)
                            : null,
                      ),
                      SizedBox(width: AppDesignSystem.spaceM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trainer['name'] ?? 'Unknown',
                              style: AppDesignSystem.titleSmall(context),
                            ),
                            SizedBox(height: AppDesignSystem.spaceXS),
                            Text(
                              trainer['email'] ?? 'No email',
                              style: AppDesignSystem.bodySmall(context),
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
                          color: trainerColor.withValues(alpha: 0.15),
                          borderRadius: AppDesignSystem.borderRadiusM,
                        ),
                        child: Text(
                          'Trainer',
                          style: AppDesignSystem.labelSmall(context)
                              .copyWith(
                            color: trainerColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (trainer['bio'] != null && trainer['bio']!.isNotEmpty) ...[
                    SizedBox(height: AppDesignSystem.spaceM),
                    Text(
                      'Bio',
                      style: AppDesignSystem.labelSmall(context)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: AppDesignSystem.spaceXS),
                    Text(
                      trainer['bio']!,
                      style: AppDesignSystem.bodySmall(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  SizedBox(height: AppDesignSystem.spaceM),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _revokeTrainerRole(
                        trainer['userId'],
                        trainer['email'],
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                      ),
                      child: Text(
                        'Revoke Trainer Access',
                        style: AppDesignSystem.labelMedium(context)
                            .copyWith(color: botsWhite),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatRoleName(String role) {
    return role
        .replaceAll(RegExp(r'(?<=[a-z])(?=[A-Z])'), ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatPermission(String permission) {
    return permission
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
