import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/services/connectivity_service.dart';
import 'package:freelance_app/widgets/common/standard_button.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/snackbar_helper.dart';

/// Web Admin Dashboard - Optimized for desktop/tablet browsers
/// Provides a responsive interface for managing company approvals
class WebAdminDashboard extends StatefulWidget {
  const WebAdminDashboard({super.key});

  @override
  State<WebAdminDashboard> createState() => _WebAdminDashboardState();
}

class _WebAdminDashboardState extends State<WebAdminDashboard>
    with ConnectivityAware {
  String _selectedTab = 'pending'; // pending, approved, rejected, stats
  String _searchQuery = '';
  bool _isSidebarCollapsed = false;
  final _dbService = FirebaseDatabaseService();
  final _authService = FirebaseAuthService();
  List<Map<String, dynamic>> _pendingCompanies = [];
  List<Map<String, dynamic>> _approvedCompanies = [];
  List<Map<String, dynamic>> _rejectedCompanies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    if (!await checkConnectivity(context,
        message:
            'Cannot load companies without internet. Please connect and try again.')) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      setState(() => _isLoading = true);

      final result = await _dbService.searchUsers(isCompany: true, limit: 100);

      final allCompanies = result.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              ...data,
              'id': doc.id,
            };
          })
          .where((c) {
            // Filter out invalid entries: must have id and be a company
            final id = c['id'] as String?;
            final isCompany = c['isCompany'] as bool? ?? false;
            return id != null && id.isNotEmpty && isCompany;
          })
          .toList();

      if (mounted) {
        setState(() {
          _pendingCompanies = allCompanies
              .where((c) =>
                  (c['approvalStatus'] as String? ?? 'pending') == 'pending')
              .toList();
          _approvedCompanies = allCompanies
              .where(
                  (c) => (c['approvalStatus'] as String? ?? '') == 'approved')
              .toList();
          _rejectedCompanies = allCompanies
              .where(
                  (c) => (c['approvalStatus'] as String? ?? '') == 'rejected')
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 600 && screenWidth <= 1200;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: true, // Critical for keyboard handling
      backgroundColor: colorScheme.surface,
      body: Row(
        children: [
          // Sidebar Navigation
          if (!_isSidebarCollapsed) _buildSidebar(isDesktop: isDesktop),

          // Main Content Area
          Expanded(
            child: Column(
              children: [
                _buildTopBar(isDesktop: isDesktop),
                Expanded(
                  child:
                      _buildContent(isDesktop: isDesktop, isTablet: isTablet),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar({required bool isDesktop}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: isDesktop ? 260 : 200,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.6),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo Header
          Container(
            padding: AppDesignSystem.paddingL,
            child: Column(
              children: [
                Image.asset(
                  'assets/images/BOTSJOBSCONNECT logo.png',
                  height: 50,
                  fit: BoxFit.contain,
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                Text(
                  'Admin Dashboard',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildNavItem(
                  icon: Icons.pending_actions,
                  label: 'Pending',
                  badge: _getPendingCount(),
                  isSelected: _selectedTab == 'pending',
                  onTap: () => setState(() => _selectedTab = 'pending'),
                ),
                _buildNavItem(
                  icon: Icons.check_circle,
                  label: 'Approved',
                  isSelected: _selectedTab == 'approved',
                  onTap: () => setState(() => _selectedTab = 'approved'),
                ),
                _buildNavItem(
                  icon: Icons.cancel,
                  label: 'Rejected',
                  isSelected: _selectedTab == 'rejected',
                  onTap: () => setState(() => _selectedTab = 'rejected'),
                ),
                _buildNavItem(
                  icon: Icons.analytics,
                  label: 'Statistics',
                  isSelected: _selectedTab == 'stats',
                  onTap: () => setState(() => _selectedTab = 'stats'),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Admin Profile
          _buildAdminProfile(),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    Widget? badge,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
        borderRadius: AppDesignSystem.borderRadiusS,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color:
              isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          size: 22,
        ),
        title: Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: isSelected ? colorScheme.primary : colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        trailing: badge,
        onTap: onTap,
        dense: true,
      ),
    );
  }

  Widget? _getPendingCount() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final count = _pendingCompanies.length;
    if (count == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.secondary,
        borderRadius: AppDesignSystem.borderRadiusM,
      ),
      child: Text(
        count.toString(),
        style: textTheme.labelSmall?.copyWith(
          color: colorScheme.onSecondary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildAdminProfile() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final user = _authService.getCurrentUser();

    return Container(
      padding: AppDesignSystem.paddingM,
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: colorScheme.primary,
            child: Text(
              ((user?.email ?? 'A')[0]).toUpperCase(),
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Admin',
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  user?.email ?? 'admin@example.com',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar({required bool isDesktop}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.6),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Toggle Sidebar Button
          IconButton(
            icon: Icon(_isSidebarCollapsed ? Icons.menu : Icons.menu_open),
            onPressed: () {
              setState(() => _isSidebarCollapsed = !_isSidebarCollapsed);
            },
          ),

          AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),

          // Page Title
          Text(
            _getPageTitle(),
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.primary,
            ),
          ),

          const Spacer(),

          // Search Bar
          if (isDesktop) ...[
            SizedBox(
              width: 400,
              child: _buildSearchBar(),
            ),
            AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
          ],

          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
      decoration: InputDecoration(
        hintText: 'Search companies...',
        prefixIcon:
            Icon(Icons.search, size: 20, color: colorScheme.onSurfaceVariant),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear,
                    size: 20, color: colorScheme.onSurfaceVariant),
                onPressed: () => setState(() => _searchQuery = ''),
              )
            : null,
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: AppDesignSystem.borderRadiusS,
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildContent({required bool isDesktop, required bool isTablet}) {
    switch (_selectedTab) {
      case 'pending':
      case 'approved':
      case 'rejected':
        return _buildCompanyGrid(
          status: _selectedTab,
          isDesktop: isDesktop,
          isTablet: isTablet,
        );
      case 'stats':
        return _buildStatsView(isDesktop: isDesktop);
      default:
        return const Center(child: Text('Unknown tab'));
    }
  }

  Widget _buildCompanyGrid({
    required String status,
    required bool isDesktop,
    required bool isTablet,
  }) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary),
      );
    }

    List<Map<String, dynamic>> companies;
    if (status == 'pending') {
      companies = _pendingCompanies;
    } else if (status == 'approved') {
      companies = _approvedCompanies;
    } else {
      companies = _rejectedCompanies;
    }

    // Filter by search query and validate data
    final filtered = companies
        .where((company) {
          // Validate company has required fields
          final id = company['id'] as String?;
          if (id == null || id.isEmpty) return false;

          // Apply search filter if query exists
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
        })
        .toList();

    if (filtered.isEmpty) {
      return _buildEmptyState(status);
    }

    // Responsive grid
    final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);

    return RefreshIndicator(
      onRefresh: _loadCompanies,
      child: GridView.builder(
        padding: AppDesignSystem.paddingL,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.3,
        ),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final company = filtered[index];
          final docId = company['id'] as String? ?? '';
          // Skip rendering if docId is empty
          if (docId.isEmpty) {
            return const SizedBox.shrink();
          }
          return _buildCompanyCard(company, docId, status);
        },
      ),
    );
  }

  Widget _buildCompanyCard(
      Map<String, dynamic> company, String docId, String status) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final companyName = company['company_name'] ?? 'Unknown Company';
    final regNumber = company['registration_number'] ?? 'N/A';
    final industry = company['industry'] ?? 'N/A';
    final email = company['email'] ?? 'N/A';
    final website = company['website'] ?? '';
    final userImage = company['user_image'] ?? '';
    final createdAt = company['createdAt'] ?? company['created'];
    DateTime? created;
    if (createdAt != null) {
      if (createdAt is Timestamp) {
        created = createdAt.toDate();
      } else if (createdAt is String && createdAt.isNotEmpty) {
        try {
          created = DateTime.parse(createdAt);
        } catch (e) {
          created = null;
        }
      } else if (createdAt is DateTime) {
        created = createdAt;
      }
    }

    return AppCard(
      elevation: 6,
      variant: SurfaceVariant.elevated,
      borderRadius: AppDesignSystem.borderRadiusM,
      onTap: () => _showCompanyDetails(company, docId, status),
      padding: AppDesignSystem.paddingM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: colorScheme.surfaceContainerHighest,
                backgroundImage:
                    userImage.isNotEmpty ? NetworkImage(userImage) : null,
                child: userImage.isEmpty
                    ? Icon(Icons.business, color: colorScheme.primary)
                    : null,
              ),
              AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      companyName,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      industry,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),

          // Details
          _buildDetailChip(Icons.numbers, 'Reg: $regNumber'),
          AppDesignSystem.verticalSpace(6),
          _buildDetailChip(Icons.email, email),
          if (website.isNotEmpty) ...[
            AppDesignSystem.verticalSpace(6),
            _buildDetailChip(Icons.language, website),
          ],

          const Spacer(),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (created != null)
                Text(
                  DateFormat('MMM d, y').format(created),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              if (status == 'pending')
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, size: 20),
                      color: colorScheme.tertiary,
                      onPressed: () => _approveCompany(docId, companyName),
                      tooltip: 'Approve',
                    ),
                    IconButton(
                      icon:
                          Icon(Icons.close, color: colorScheme.error, size: 20),
                      onPressed: () => _showRejectDialog(docId, companyName),
                      tooltip: 'Reject',
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
        AppDesignSystem.horizontalSpace(6),
        Expanded(
          child: Text(
            text,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String status) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            status == 'pending' ? Icons.inbox : Icons.check_circle_outline,
            size: 80,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
          Text(
            'No $status companies',
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsView({required bool isDesktop}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final pending = _pendingCompanies.length;
    final approved = _approvedCompanies.length;
    final rejected = _rejectedCompanies.length;
    final total = pending + approved + rejected;

    return SingleChildScrollView(
                padding: AppDesignSystem.paddingL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isDesktop ? 4 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.8,
            children: [
              _buildStatCard(
                'Total Companies',
                total.toString(),
                Icons.business,
                colorScheme.primary,
              ),
              _buildStatCard(
                'Pending',
                pending.toString(),
                Icons.pending_actions,
                colorScheme.secondary,
              ),
              _buildStatCard(
                'Approved',
                approved.toString(),
                Icons.check_circle,
                colorScheme.tertiary,
              ),
              _buildStatCard(
                'Rejected',
                rejected.toString(),
                Icons.cancel,
                colorScheme.error,
              ),
            ],
          ),

          AppDesignSystem.verticalSpace(AppDesignSystem.spaceXL),

          // Recent Activity
          if (pending > 0)
            AppCard(
              elevation: 6,
      variant: SurfaceVariant.elevated,
              borderRadius: AppDesignSystem.borderRadiusM,
              child: Padding(
                padding: AppDesignSystem.paddingL,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Action Required',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.primary,
                      ),
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                    ListTile(
                      leading: Container(
                        padding: AppDesignSystem.paddingM,
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: AppDesignSystem.borderRadiusS,
                        ),
                        child: Icon(
                          Icons.pending_actions,
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                      title: const Text('Review Pending Companies'),
                      subtitle: Text('$pending companies waiting for approval'),
                      trailing: StandardButton(
                        label: 'Review Now',
                        type: StandardButtonType.primary,
                        onPressed: () =>
                            setState(() => _selectedTab = 'pending'),
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

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    return AppCard(
      elevation: 6,
      variant: SurfaceVariant.elevated,
      borderRadius: AppDesignSystem.borderRadiusM,
      child: Padding(
        padding: AppDesignSystem.paddingL,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: AppDesignSystem.paddingS,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: AppDesignSystem.borderRadiusS,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Text(
              value,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
            Text(
              title,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompanyDetails(
      Map<String, dynamic> company, String docId, String status) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: AppDesignSystem.borderRadiusL),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: AppDesignSystem.paddingL,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      backgroundImage: company['user_image'] != null &&
                              company['user_image'].isNotEmpty
                          ? NetworkImage(company['user_image'])
                          : null,
                      child: company['user_image'] == null ||
                              company['user_image'].isEmpty
                          ? Icon(Icons.business,
                              color: Theme.of(context).colorScheme.primary,
                              size: 32)
                          : null,
                    ),
                    AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            company['company_name'] ?? 'Unknown',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            company['industry'] ?? 'N/A',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const Divider(height: 32),

                // Details
                _buildDialogDetail(
                    'Contact Person', company['name'], Icons.person),
                _buildDialogDetail('Email', company['email'], Icons.email),
                _buildDialogDetail(
                    'Phone', company['phone_number'], Icons.phone),
                _buildDialogDetail(
                    'Address', company['address'], Icons.location_on),
                _buildDialogDetail('Registration Number',
                    company['registration_number'], Icons.numbers),
                if (company['website'] != null && company['website'].isNotEmpty)
                  _buildDialogDetail(
                      'Website', company['website'], Icons.language),

                AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),

                Text(
                  'Company Description',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                Text(
                  company['company_description'] ?? 'No description',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                ),

                AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),

                // Actions
                if (status == 'pending')
                  Row(
                    children: [
                      Expanded(
                        child: StandardButton(
                          label: 'Approve',
                          type: StandardButtonType.success,
                          onPressed: () {
                            Navigator.pop(context);
                            _approveCompany(docId, company['company_name']);
                          },
                          icon: Icons.check,
                        ),
                      ),
                      AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
                      Expanded(
                        child: StandardButton(
                          label: 'Reject',
                          type: StandardButtonType.danger,
                          onPressed: () {
                            Navigator.pop(context);
                            _showRejectDialog(docId, company['company_name']);
                          },
                          icon: Icons.close,
                        ),
                      ),
                    ],
                  ),

                if (status == 'rejected' && company['rejectionReason'] != null)
                  Container(
                    padding: AppDesignSystem.paddingM,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      borderRadius: AppDesignSystem.borderRadiusS,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rejection Reason:',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onError,
                                  ),
                        ),
                        AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                        Text(
                          company['rejectionReason'],
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onError,
                                  ),
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

  Widget _buildDialogDetail(String label, dynamic value, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                AppDesignSystem.verticalSpace(2),
                Text(
                  value?.toString() ?? 'N/A',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPageTitle() {
    switch (_selectedTab) {
      case 'pending':
        return 'Pending Companies';
      case 'approved':
        return 'Approved Companies';
      case 'rejected':
        return 'Rejected Companies';
      case 'stats':
        return 'Statistics & Overview';
      default:
        return 'Admin Dashboard';
    }
  }

  Future<void> _approveCompany(String docId, String companyName) async {
    if (!await checkConnectivity(context,
        message:
            'Cannot approve company without internet. Please connect and try again.')) {
      return;
    }

    try {
      final updateData = <String, dynamic>{
        'isApproved': true,
        'approvalStatus': 'approved',
        'approvalDate': DateTime.now().toIso8601String(),
      };
      await _dbService.updateUser(
        userId: docId,
        data: updateData,
      );

      await _loadCompanies(); // Reload data

      if (!mounted) return;
      SnackbarHelper.showSuccess(context, '✓ $companyName approved successfully');
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.showError(context, 'Error: $e');
    }
  }

  void _showRejectDialog(String docId, String companyName) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true, // Allow scrolling when keyboard appears
        title: Text('Reject $companyName'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Provide a reason for rejection:'),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
              TextField(
                controller: reasonController,
                maxLines: 3,
                scrollPadding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 80,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g., Invalid registration number',
                  border: OutlineInputBorder(
                    borderRadius: AppDesignSystem.borderRadiusS,
                  ),
                ),
              ),
            ],
          ),
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
    if (!await checkConnectivity(context,
        message:
            'Cannot reject company without internet. Please connect and try again.')) {
      return;
    }

    try {
      await _dbService.updateUser(
        userId: docId,
        data: {
          'isApproved': false,
          'approvalStatus': 'rejected',
          'approvalDate': DateTime.now().toIso8601String(),
          'rejectionReason': reason,
        },
      );

      await _loadCompanies(); // Reload data

      if (!mounted) return;
      SnackbarHelper.showError(context, '✗ $companyName rejected');
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.showError(context, 'Error: $e');
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          StandardButton(
            label: 'Cancel',
            type: StandardButtonType.text,
            onPressed: () => Navigator.pop(context, false),
          ),
          StandardButton(
            label: 'Logout',
            type: StandardButtonType.danger,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/admin/login');
  }
}
