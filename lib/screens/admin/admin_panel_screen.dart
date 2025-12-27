import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';
import 'package:freelance_app/services/notifications/notification_service.dart';
import 'package:freelance_app/services/connectivity_service.dart';
import 'package:freelance_app/widgets/common/standard_button.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/screens/homescreen/sidebar.dart';
import 'package:freelance_app/screens/notifications/notifications_screen.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/widgets/common/role_guard.dart';
import 'package:freelance_app/services/auth/app_user_role.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/screens/common/cv_document_viewer_screen.dart';
import 'package:freelance_app/screens/admin/admin_finance_screen.dart';
import 'package:freelance_app/screens/admin/admin_api_settings_screen.dart';
import 'package:freelance_app/widgets/common/contact_action_row.dart';
import 'package:freelance_app/widgets/common/snackbar_helper.dart';
import 'package:freelance_app/services/hints/hints_service.dart';
import 'package:freelance_app/services/hints/ai_hints_service.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:freelance_app/widgets/ui/category_rail.dart';
import 'package:freelance_app/widgets/ui/portfolio_section.dart';
import 'package:freelance_app/utils/colors.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';
import 'package:freelance_app/screens/admin/admin_companies_list_screen.dart';
import 'package:freelance_app/screens/admin/admin_pending_companies_screen.dart';
import 'package:freelance_app/screens/admin/admin_approved_companies_screen.dart';
import 'package:freelance_app/screens/admin/admin_rejected_companies_screen.dart';
import 'package:freelance_app/screens/admin/admin_jobs_screen.dart';
import 'package:freelance_app/screens/admin/admin_ratings_moderation_screen.dart';
import 'package:freelance_app/screens/admin/admin_plugins_screen.dart';
import 'package:freelance_app/screens/admin/admin_stats_screen.dart';
import 'package:freelance_app/screens/admin/admin_hints_screen.dart';
import 'package:freelance_app/screens/admin/admin_job_statistics_screen.dart';
import 'package:freelance_app/screens/admin/admin_audit_logs_screen.dart';
import 'package:freelance_app/screens/admin/admin_user_suspension_screen.dart';
import 'package:freelance_app/screens/admin/admin_compliance_warnings_screen.dart';
import 'package:freelance_app/screens/admin/admin_bulk_approval_screen.dart';
import 'package:freelance_app/screens/admin/admin_disputes_screen.dart';
import 'package:freelance_app/screens/admin/admin_rbac_screen.dart';
import 'package:freelance_app/screens/admin/admin_content_moderation_screen.dart';
import 'package:freelance_app/screens/admin/admin_monitoring_dashboard_screen.dart';
import 'package:freelance_app/screens/admin/admin_trainer_approval_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with ConnectivityAware {
  int _selectedIndex = 0; // Track selected navigation item
  String _searchQuery = '';
  Timer? _debounce;
  final _searchController = TextEditingController();
  final _dbService = FirebaseDatabaseService();
  final _notificationService = NotificationService();
  final _authService = FirebaseAuthService();
  String? _userId;
  List<Map<String, dynamic>> _pendingCompanies = [];
  List<Map<String, dynamic>> _approvedCompanies = [];
  List<Map<String, dynamic>> _rejectedCompanies = [];
  List<Map<String, dynamic>> _pendingJobs = [];
  List<Map<String, dynamic>> _pendingGigs = [];
  List<Map<String, dynamic>> _pendingCourses = [];
  bool _isLoading = true;

  Stream<int> _getUnreadCount() {
    if (_userId == null) {
      return Stream.value(0);
    }
    return _notificationService.getUnreadCount(_userId!);
  }

  @override
  void initState() {
    super.initState();
    final user = _authService.getCurrentUser();
    _userId = user?.uid;
    _loadCompanies();
    _loadPendingJobs();
  }

  Future<void> _loadCompanies() async {
    if (!await checkConnectivity(context,
        message:
            'Cannot load companies without internet. Please connect and try again.')) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      if (mounted) {
        setState(() => _isLoading = true);
      }

      // Load all companies
      final result = await _dbService.searchUsers(isCompany: true, limit: 100);

      final allCompanies = result.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final docId = doc.id;
            // Ensure id is always set and valid
            if (docId.isEmpty) {
              return null;
            }
            return {
              ...data,
              'id': docId,
            };
          })
          .where((c) {
            if (c == null) return false;
            // Filter out invalid entries: must have id and be a company
            final id = c['id'] as String?;
            final isCompany = c['isCompany'] as bool? ?? false;
            return id != null && id.isNotEmpty && isCompany;
          })
          .cast<Map<String, dynamic>>()
          .toList();

      if (mounted) {
        setState(() {
          _pendingCompanies = allCompanies.where((c) {
            final id = c['id'] as String?;
            if (id == null || id.isEmpty) return false;
            final approvalStatus = c['approvalStatus'] as String? ?? 'pending';
            return approvalStatus == 'pending';
          }).toList();
          _approvedCompanies = allCompanies.where((c) {
            final id = c['id'] as String?;
            if (id == null || id.isEmpty) return false;
            final approvalStatus = c['approvalStatus'] as String? ?? '';
            return approvalStatus == 'approved';
          }).toList();
          _rejectedCompanies = allCompanies.where((c) {
            final id = c['id'] as String?;
            if (id == null || id.isEmpty) return false;
            final approvalStatus = c['approvalStatus'] as String? ?? '';
            return approvalStatus == 'rejected';
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading companies: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Initialize empty lists on error to prevent display issues
          _pendingCompanies = [];
          _approvedCompanies = [];
          _rejectedCompanies = [];
        });
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _searchQuery = query.toLowerCase();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allow: const {AppUserRole.admin},
      title: 'Admin only',
      message: 'This screen is only available to administrators.',
      child: HintsWrapper(
        screenId: 'admin_panel',
        child: Scaffold(
          backgroundColor: botsSuperLightGrey, // Match Job Seeker Dashboard
          resizeToAvoidBottomInset: true, // Critical for keyboard handling
          drawer: const SideBar(),
          appBar: AppAppBar(
            title: 'Admin Panel',
            variant: AppBarVariant.primary,
            actions: [
              // Notifications with badge
              StreamBuilder<int>(
                stream: _getUnreadCount(),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          );
                        },
                      ),
                      if (count > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.error,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              count > 9 ? '9+' : '$count',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onError,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
          body: SafeArea(
            child: Builder(
              builder: (context) {
                final colorScheme = Theme.of(context).colorScheme;
                // FIXED: Wrap entire content in CustomScrollView for proper keyboard handling
                return CustomScrollView(
                  slivers: [
                    // Search bar section - pinned at top
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: AppDesignSystem.paddingSymmetric(
                          horizontal: AppDesignSystem.spaceL,
                          vertical: AppDesignSystem.spaceM,
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          scrollPadding: EdgeInsets.only(
                            bottom:
                                MediaQuery.of(context).viewInsets.bottom + 120,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search companies, jobs...',
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
                    ),

                    // Navigation Section - Use CategoryRail like Job Seeker Dashboard
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: AppDesignSystem.paddingHorizontal(
                            AppDesignSystem.spaceL),
                        child: CategoryRail(
                          items: [
                            CategoryItem(
                              id: 'pending',
                              label: 'Pending',
                              icon: Icons.pending_actions,
                              color: AppDesignSystem.brandYellow,
                            ),
                            CategoryItem(
                              id: 'approved',
                              label: 'Approved',
                              icon: Icons.check_circle,
                              color: AppDesignSystem.brandGreen,
                            ),
                            CategoryItem(
                              id: 'rejected',
                              label: 'Rejected',
                              icon: Icons.cancel,
                              color: AppDesignSystem.errorColor(context),
                            ),
                            CategoryItem(
                              id: 'jobs',
                              label: 'Jobs',
                              icon: Icons.work,
                              color: AppDesignSystem.brandBlue,
                            ),
                            CategoryItem(
                              id: 'plugins',
                              label: 'Plugins',
                              icon: Icons.extension,
                              color: AppDesignSystem.brandGreen,
                            ),
                            CategoryItem(
                              id: 'api_settings',
                              label: 'API Settings',
                              icon: Icons.settings_applications,
                              color: AppDesignSystem.brandBlue,
                            ),
                            CategoryItem(
                              id: 'finances',
                              label: 'Finances',
                              icon: Icons.account_balance_wallet,
                              color: AppDesignSystem.brandYellow,
                            ),
                            CategoryItem(
                              id: 'stats',
                              label: 'Stats',
                              icon: Icons.analytics,
                              color: AppDesignSystem.brandBlue,
                            ),
                            CategoryItem(
                              id: 'hints',
                              label: 'Hints',
                              icon: Icons.lightbulb_outline,
                              color: AppDesignSystem.brandGreen,
                            ),
                            CategoryItem(
                              id: 'ratings',
                              label: 'Ratings',
                              icon: Icons.star_outline,
                              color: AppDesignSystem.brandYellow,
                            ),
                            CategoryItem(
                              id: 'audit_logs',
                              label: 'Audit Logs',
                              icon: Icons.history,
                              color: AppDesignSystem.brandBlue,
                            ),
                            CategoryItem(
                              id: 'suspensions',
                              label: 'Suspensions',
                              icon: Icons.block,
                              color: AppDesignSystem.errorColor(context),
                            ),
                            CategoryItem(
                              id: 'compliance_warnings',
                              label: 'Compliance',
                              icon: Icons.warning_amber,
                              color: AppDesignSystem.brandYellow,
                            ),
                            CategoryItem(
                              id: 'bulk_approval',
                              label: 'Bulk Approval',
                              icon: Icons.done_all,
                              color: AppDesignSystem.brandGreen,
                            ),
                            CategoryItem(
                              id: 'disputes',
                              label: 'Disputes',
                              icon: Icons.gavel,
                              color: AppDesignSystem.brandBlue,
                            ),
                            CategoryItem(
                              id: 'rbac',
                              label: 'Admin Roles',
                              icon: Icons.security,
                              color: const Color(0xFFD32F2F),
                            ),
                            CategoryItem(
                              id: 'content_moderation',
                              label: 'Content Moderation',
                              icon: Icons.filter_alt,
                              color: Colors.orange,
                            ),
                            CategoryItem(
                              id: 'monitoring',
                              label: 'System Health',
                              icon: Icons.dashboard,
                              color: AppDesignSystem.brandGreen,
                            ),
                          ],
                          onItemSelected: (id) {
                            // Navigate to separate screens for each item
                            switch (id) {
                              case 'pending':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const AdminPendingCompaniesScreen(),
                                  ),
                                );
                                break;
                              case 'approved':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const AdminApprovedCompaniesScreen(),
                                  ),
                                );
                                break;
                              case 'rejected':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const AdminRejectedCompaniesScreen(),
                                  ),
                                );
                                break;
                              case 'jobs':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AdminJobsScreen(),
                                  ),
                                );
                                break;
                              case 'plugins':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AdminPluginsScreen(),
                                  ),
                                );
                                break;
                              case 'api_settings':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const AdminAPISettingsScreen(),
                                  ),
                                );
                                break;
                              case 'finances':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AdminFinanceScreen(),
                                  ),
                                );
                                break;
                              case 'stats':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AdminStatsScreen(),
                                  ),
                                );
                                break;
                              case 'hints':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AdminHintsScreen(),
                                  ),
                                );
                                break;
                              case 'ratings':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const AdminRatingsModerationScreen(),
                                  ),
                                );
                                break;
                              case 'audit_logs':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const AdminAuditLogsScreen(),
                                  ),
                                );
                                break;
                              case 'suspensions':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const AdminUserSuspensionScreen(),
                                  ),
                                );
                                break;
                              case 'compliance_warnings':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const AdminComplianceWarningsScreen(),
                                  ),
                                );
                                break;
                              case 'bulk_approval':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const AdminBulkApprovalScreen(),
                                  ),
                                );
                                break;
                              case 'disputes':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const AdminDisputesScreen(),
                                  ),
                                );
                                break;
                              case 'rbac':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const AdminRoleBasedAccessScreen(),
                                  ),
                                );
                                break;
                              case 'content_moderation':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const AdminContentModerationScreen(),
                                  ),
                                );
                                break;
                              case 'monitoring':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const AdminMonitoringDashboardScreen(),
                                  ),
                                );
                                break;
                            }
                          },
                        ),
                      ),
                    ),

                    // Vertical space
                    SliverToBoxAdapter(
                      child:
                          AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                    ),

                    // Content Area - Scrollable within the same scroll view
                    SliverToBoxAdapter(
                      child: _buildCurrentView(),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_selectedIndex) {
      case 0:
        return _buildCompanyList('pending');
      case 1:
        return _buildCompanyList('approved');
      case 2:
        return _buildCompanyList('rejected');
      case 3:
        return _buildJobApprovalList();
      case 4:
        return _buildPluginsApprovalList();
      case 5:
        return const AdminTrainerApprovalScreen();
      case 6:
        return const AdminAPISettingsScreen();
      case 7:
        return const AdminFinanceScreen();
      case 8:
        return _buildStatsView();
      case 9:
        return _buildHintsControlView();
      case 10:
        return const AdminRatingsModerationScreen();
      default:
        return _buildCompanyList('pending');
    }
  }

  Widget _buildCompanyList(String status) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return Padding(
        padding: AppDesignSystem.paddingL,
        child: Center(
          child: CircularProgressIndicator(
              color: AppDesignSystem.primary(context)),
        ),
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
    final filtered = companies.where((company) {
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
    }).toList();

    if (filtered.isEmpty) {
      return Padding(
        padding: AppDesignSystem.paddingL,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                status == 'pending' ? Icons.inbox : Icons.check_circle_outline,
                size: 64,
                color: colorScheme.onSurfaceVariant,
              ),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
              Text(
                _searchQuery.isEmpty
                    ? 'No $status companies'
                    : 'No results found',
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCompanies,
      child: ListView.builder(
        padding: AppDesignSystem.paddingHorizontal(AppDesignSystem.spaceL),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final company = filtered[index];
          final docId = company['id'] as String? ?? '';
          // Skip rendering if docId is empty
          if (docId.isEmpty) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: EdgeInsets.only(bottom: AppDesignSystem.spaceM),
            child: _buildCompanyCard(company, docId, status),
          );
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
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 6, // Increased for better visibility
      variant: SurfaceVariant.elevated,
      borderRadius: AppDesignSystem.borderRadiusM,
      onTap: () => _showCompanyDetailsFullScreen(company, docId, status),
      padding: AppDesignSystem.paddingM,
      child: Row(
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
                  companyName.isNotEmpty
                      ? companyName
                      : 'Company Name Not Available',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                if (industry.isNotEmpty) ...[
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                  Text(
                    industry,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (regNumber.isNotEmpty) ...[
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                  Text(
                    'Reg: $regNumber',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (created != null) ...[
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                  Text(
                    'Applied: ${DateFormat('MMM d, y').format(created)}',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  void _showCompanyDetailsFullScreen(
      Map<String, dynamic> company, String docId, String status) {
    final companyName = company['company_name'] as String? ??
        company['companyName'] as String? ??
        company['name'] as String? ??
        'Company';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _CompanyDetailsScreen(
          company: company,
          docId: docId,
          status: status,
          onApprove: () async {
            Navigator.pop(context);
            await _approveCompany(docId, companyName);
            if (mounted) _loadCompanies(); // Reload after action
          },
          onReject: () {
            Navigator.pop(context);
            _showRejectDialog(docId, companyName);
            if (mounted) _loadCompanies(); // Reload after action
          },
          onRevoke: () async {
            Navigator.pop(context);
            await _revokeApproval(docId, companyName);
            if (mounted) _loadCompanies(); // Reload after action
          },
          onReapprove: () async {
            Navigator.pop(context);
            await _reapproveCompany(docId, companyName);
            if (mounted) _loadCompanies(); // Reload after action
          },
          onViewKyc: () => _showKycDocsDialog(docId, companyName),
        ),
      ),
    );
  }

  Map<String, String> _getKYCDocumentLabels() {
    // Try to get from config/DB, fallback to defaults
    // This could be fetched from a config collection in Firestore
    return {
      'cipa_certificate': 'CIPA Certificate',
      'cipa_extract': 'CIPA Extract',
      'burs_tin': 'BURS TIN Evidence',
      'proof_of_address': 'Proof of Address',
      'authority_letter': 'Authority Letter (optional)',
    };
  }

  void _showKycDocsDialog(String companyId, String companyName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('KYC Documents: $companyName'),
          content: SizedBox(
            width: 520,
            child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('company_kyc')
                  .doc(companyId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Padding(
                    padding: AppDesignSystem.paddingL,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }

                final data = snapshot.data?.data() ?? {};
                final status = data['status'] as String? ?? '';
                final documents = (data['documents'] is Map<String, dynamic>)
                    ? (data['documents'] as Map<String, dynamic>)
                    : <String, dynamic>{};

                // Get KYC document labels from config or use defaults
                final kycLabels = _getKYCDocumentLabels();

                Widget row(String key, String label) {
                  String? url;
                  final doc = documents[key];
                  if (doc is Map) {
                    final u = doc['url'];
                    if (u is String && u.isNotEmpty) url = u;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(child: Text(label)),
                        Text(url != null ? 'Uploaded' : 'Missing'),
                        AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
                        if (url != null)
                          StandardButton(
                            label: 'View',
                            type: StandardButtonType.text,
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                this.context,
                                MaterialPageRoute(
                                  builder: (_) => CvDocumentViewerScreen(
                                    title: label,
                                    cvUrl: url!,
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'KYC status: ${status.isNotEmpty ? status : 'Not submitted'}'),
                      AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                      row('cipa_certificate',
                          kycLabels['cipa_certificate'] ?? 'CIPA Certificate'),
                      row('cipa_extract',
                          kycLabels['cipa_extract'] ?? 'CIPA Extract'),
                      row('burs_tin',
                          kycLabels['burs_tin'] ?? 'BURS TIN Evidence'),
                      row('proof_of_address',
                          kycLabels['proof_of_address'] ?? 'Proof of Address'),
                      row(
                          'authority_letter',
                          kycLabels['authority_letter'] ??
                              'Authority Letter (optional)'),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            StandardButton(
              label: 'Close',
              type: StandardButtonType.text,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsView() {
    final pending = _pendingCompanies.length;
    final approved = _approvedCompanies.length;
    final rejected = _rejectedCompanies.length;
    final total = pending + approved + rejected;
    final pendingJobs = _pendingJobs.length;
    final pendingPlugins = _pendingGigs.length + _pendingCourses.length;

    return RefreshIndicator(
      onRefresh: _loadCompanies,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Overview - Use PortfolioSection like Job Seeker Dashboard
          PortfolioSection(
            title: 'Overview',
            items: [
              PortfolioCardData(
                title: 'Total Companies',
                value: total.toString(),
                subtitle: 'All companies',
                icon: Icons.business,
                iconColor: AppDesignSystem.brandBlue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const AdminCompaniesListScreen(status: 'all'),
                    ),
                  );
                },
              ),
              PortfolioCardData(
                title: 'Pending Approval',
                value: pending.toString(),
                subtitle: 'Awaiting review',
                icon: Icons.pending_actions,
                iconColor: AppDesignSystem.brandYellow,
                onTap: () {
                  setState(() {
                    _selectedIndex = 0; // Show pending
                  });
                },
              ),
              PortfolioCardData(
                title: 'Approved',
                value: approved.toString(),
                subtitle: 'Verified companies',
                icon: Icons.check_circle,
                iconColor: AppDesignSystem.brandGreen,
                onTap: () {
                  setState(() {
                    _selectedIndex = 1; // Show approved
                  });
                },
              ),
              PortfolioCardData(
                title: 'Rejected',
                value: rejected.toString(),
                subtitle: 'Not approved',
                icon: Icons.cancel,
                iconColor: AppDesignSystem.errorColor(context),
                onTap: () {
                  setState(() {
                    _selectedIndex = 2; // Show rejected
                  });
                },
              ),
              PortfolioCardData(
                title: 'Pending Jobs',
                value: pendingJobs.toString(),
                subtitle: 'Awaiting approval',
                icon: Icons.work,
                iconColor: AppDesignSystem.brandBlue,
                onTap: () {
                  setState(() {
                    _selectedIndex = 3; // Show jobs
                  });
                },
              ),
              PortfolioCardData(
                title: 'Pending Plugins',
                value: pendingPlugins.toString(),
                subtitle: 'Awaiting review',
                icon: Icons.extension,
                iconColor: AppDesignSystem.brandGreen,
                onTap: () {
                  setState(() {
                    _selectedIndex = 4; // Show plugins
                  });
                },
              ),
              PortfolioCardData(
                title: 'Trainer Applications',
                value: 'Review',
                subtitle: 'Teaching certifications',
                icon: Icons.school,
                iconColor: Colors.amber,
                onTap: () {
                  setState(() {
                    _selectedIndex = 5; // Show trainer approvals
                  });
                },
              ),
              PortfolioCardData(
                title: 'Job Statistics',
                value: 'View',
                subtitle: 'Completion & ratings',
                icon: Icons.analytics,
                iconColor: AppDesignSystem.brandBlue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminJobStatisticsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceXL),
          // Quick Actions Card
          if (pending > 0)
            Padding(
              padding:
                  AppDesignSystem.paddingHorizontal(AppDesignSystem.spaceL),
              child: AppCard(
                variant: SurfaceVariant.elevated,
                child: ListTile(
                  leading: Container(
                    padding: AppDesignSystem.paddingS,
                    decoration: BoxDecoration(
                      color: AppDesignSystem.brandYellow.withValues(alpha: 0.1),
                      borderRadius: AppDesignSystem.borderRadiusS,
                    ),
                    child: Icon(
                      Icons.pending_actions,
                      color: AppDesignSystem.brandYellow,
                    ),
                  ),
                  title: Text(
                    'Review Pending Companies',
                    style: AppDesignSystem.titleMedium(context).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text('$pending companies waiting for approval'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    setState(() {
                      _selectedIndex = 0;
                    });
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _approveCompany(String docId, String companyName) async {
    if (!mounted) return;

    if (!await checkConnectivity(context,
        message:
            'Cannot approve company without internet. Please connect and try again.')) {
      return;
    }

    try {
      setState(() => _isLoading = true);
      // Require KYC submission before approval
      final kycDoc = await FirebaseFirestore.instance
          .collection('company_kyc')
          .doc(docId)
          .get();
      final kyc = kycDoc.data() ?? {};
      final kycStatus = (kyc['status'] as String?) ?? 'draft';
      if (kycStatus != 'submitted') {
        if (!mounted) return;
        SnackbarHelper.showError(context,
            'Cannot approve: company has not submitted KYC documents.');
        return;
      }

      final updateData = <String, dynamic>{
        'isApproved': true,
        'approvalStatus': 'approved',
        'approvalDate': DateTime.now().toIso8601String(),
      };
      await _dbService.updateUser(
        userId: docId,
        data: updateData,
      );

      await FirebaseFirestore.instance
          .collection('company_kyc')
          .doc(docId)
          .set({
        'status': 'approved',
        'reviewedAt': FieldValue.serverTimestamp(),
        'rejectionReason': FieldValue.delete(),
      }, SetOptions(merge: true));

      // Send notification
      await _notificationService.sendNotification(
        userId: docId,
        type: 'company_approval',
        title: 'Company Approved! ✅',
        body:
            'Your company "$companyName" has been approved. You can now post jobs!',
        data: {'companyId': docId},
        sendEmail: true,
      );

      await _loadCompanies(); // Reload data

      if (!mounted) return;
      setState(() => _isLoading = false);
      SnackbarHelper.showSuccess(
          context, '✓ $companyName approved successfully');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      SnackbarHelper.showError(context, 'Error approving company: $e');
      debugPrint('Error approving company: $e');
    }
  }

  void _showRejectDialog(String docId, String companyName) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject $companyName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide a reason for rejection:'),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g., Invalid registration number',
                border: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusS,
                ),
              ),
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
    if (!mounted) return;

    if (!await checkConnectivity(context,
        message:
            'Cannot reject company without internet. Please connect and try again.')) {
      return;
    }

    try {
      setState(() => _isLoading = true);
      await _dbService.updateUser(
        userId: docId,
        data: {
          'isApproved': false,
          'approvalStatus': 'rejected',
          'approvalDate': DateTime.now().toIso8601String(),
          'rejectionReason': reason,
        },
      );

      await FirebaseFirestore.instance
          .collection('company_kyc')
          .doc(docId)
          .set({
        'status': 'rejected',
        'reviewedAt': FieldValue.serverTimestamp(),
        'rejectionReason': reason,
      }, SetOptions(merge: true));

      // Notify the company with the rejection reason
      await _notificationService.sendNotification(
        userId: docId,
        type: 'company_rejected',
        title: 'Company Verification Rejected',
        body:
            'Your company verification application was rejected. Please review the reason below and resubmit your documents.',
        data: {
          'companyId': docId,
          'reason': reason,
          'companyName': companyName
        },
        sendEmail: true,
      );

      await _loadCompanies(); // Reload data

      if (!mounted) return;
      SnackbarHelper.showError(context, '✗ $companyName rejected');
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.showError(context, 'Error rejecting company: $e');
    }
  }

  Future<void> _revokeApproval(String docId, String companyName) async {
    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Approval'),
        content:
            Text('Are you sure you want to revoke approval for $companyName?'),
        actions: [
          StandardButton(
            label: 'Cancel',
            type: StandardButtonType.text,
            onPressed: () => Navigator.pop(context, false),
          ),
          StandardButton(
            label: 'Revoke',
            type: StandardButtonType.secondary,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() => _isLoading = true);
      await _dbService.updateUser(
        userId: docId,
        data: {
          'isApproved': false,
          'approvalStatus': 'pending',
        },
      );

      // Notify company about revocation
      await _notificationService.sendNotification(
        userId: docId,
        type: 'company_approval_revoked',
        title: 'Company Approval Revoked',
        body:
            'Your company "$companyName" approval has been revoked. Please contact support for more information.',
        data: {
          'companyId': docId,
          'companyName': companyName,
        },
        sendEmail: true,
      );

      await _loadCompanies(); // Reload data

      if (!mounted) return;
      setState(() => _isLoading = false);
      SnackbarHelper.showInfo(context, 'Approval revoked for $companyName');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      SnackbarHelper.showError(context, 'Error revoking approval: $e');
      debugPrint('Error revoking approval: $e');
    }
  }

  Future<void> _reapproveCompany(String docId, String companyName) async {
    if (!mounted) return;

    if (!await checkConnectivity(context,
        message:
            'Cannot re-approve company without internet. Please connect and try again.')) {
      return;
    }

    try {
      setState(() => _isLoading = true);
      final updateData = <String, dynamic>{
        'isApproved': true,
        'approvalStatus': 'approved',
        'approvalDate': DateTime.now().toIso8601String(),
      };
      await _dbService.updateUser(
        userId: docId,
        data: updateData,
      );

      // Send notification
      await _notificationService.sendNotification(
        userId: docId,
        type: 'company_approval',
        title: 'Company Approved! ✅',
        body:
            'Your company "$companyName" has been approved. You can now post jobs!',
        data: {'companyId': docId},
        sendEmail: true,
      );

      await _loadCompanies(); // Reload data

      if (!mounted) return;
      setState(() => _isLoading = false);
      SnackbarHelper.showSuccess(
          context, '✓ $companyName re-approved successfully');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      SnackbarHelper.showError(context, 'Error re-approving company: $e');
      debugPrint('Error re-approving company: $e');
    }
  }

  Future<void> _loadPendingJobs() async {
    try {
      final result = await _dbService
          .getCollection('jobs')
          .where('isVerified', isEqualTo: false)
          .where('status', isEqualTo: 'pending')
          .get();

      if (mounted) {
        setState(() {
          _pendingJobs = result.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              ...data,
              'id': doc.id,
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading pending jobs: $e');
    }
  }

  Future<void> _loadPendingPlugins() async {
    try {
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
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading pending plugins: $e');
    }
  }

  Widget _buildJobApprovalList() {
    if (_pendingJobs.isEmpty) {
      return Padding(
        padding: AppDesignSystem.paddingL,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.work_outline,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
              Text(
                'No pending jobs',
                style: AppDesignSystem.titleMedium(context).copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _pendingJobs.where((job) {
      if (_searchQuery.isNotEmpty) {
        final title = (job['title'] as String? ?? '').toLowerCase();
        return title.contains(_searchQuery);
      }
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return Padding(
        padding: AppDesignSystem.paddingL,
        child: Center(
          child: Text(
            'No results found',
            style: AppDesignSystem.titleMedium(context).copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: AppDesignSystem.paddingHorizontal(AppDesignSystem.spaceL),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: AppDesignSystem.spaceM),
          child: _buildJobCard(filtered[index]),
        );
      },
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final jobId = job['id'] as String;
    final jobTitle =
        job['title'] as String? ?? job['jobTitle'] as String? ?? 'Untitled';
    final employerName = job['name'] as String? ?? 'Unknown';
    final category = job['category'] as String? ?? '';

    return AppCard(
      margin: AppDesignSystem.paddingS,
      elevation: 6,
      variant: SurfaceVariant.elevated,
      child: ListTile(
        title: Text(
          jobTitle,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Employer: $employerName'),
            if (category.isNotEmpty) Text('Category: $category'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.check, color: colorScheme.tertiary),
              onPressed: () => _approveJob(jobId, jobTitle),
            ),
            IconButton(
              icon: Icon(Icons.close, color: colorScheme.error),
              onPressed: () => _rejectJob(jobId, jobTitle),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveJob(String jobId, String jobTitle) async {
    if (!mounted) return;

    if (!await checkConnectivity(context,
        message: 'Cannot approve job without internet.')) {
      return;
    }

    try {
      setState(() => _isLoading = true);
      await _dbService.updateJob(
        jobId: jobId,
        data: {
          'isVerified': true,
          'status': 'active',
          'isApproved': true,
          'approvalStatus': 'approved',
          'approvedAt': DateTime.now().toIso8601String(),
          'rejectionReason': FieldValue.delete(),
        },
      );

      // Get employer info
      final jobDoc = await _dbService.getJob(jobId);
      final jobData = jobDoc?.data() as Map<String, dynamic>?;
      final employerId = jobData?['userId'] as String?;

      if (employerId != null) {
        // Send notification
        await _notificationService.sendNotification(
          userId: employerId,
          type: 'job_approval',
          title: 'Job Approved! ✅',
          body:
              'Your job posting "$jobTitle" has been approved and is now live. Job seekers can now view and apply for this position.',
          data: {'jobId': jobId, 'jobTitle': jobTitle},
          sendEmail: true,
        );
      }

      await _loadPendingJobs();

      if (!mounted) return;
      setState(() => _isLoading = false);
      SnackbarHelper.showSuccess(context, '✓ "$jobTitle" approved');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      SnackbarHelper.showError(context, 'Error approving job: $e');
      debugPrint('Error approving job: $e');
    }
  }

  Future<void> _rejectJob(String jobId, String jobTitle) async {
    if (!mounted) return;

    final reasonController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Job'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to reject this job?'),
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
            onPressed: () => Navigator.pop(context, false),
          ),
          StandardButton(
            label: 'Reject',
            type: StandardButtonType.danger,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (result != true) return;

    if (!mounted) return;
    if (!await checkConnectivity(context,
        message: 'Cannot reject job without internet.')) {
      return;
    }

    try {
      setState(() => _isLoading = true);
      await _dbService.updateJob(
        jobId: jobId,
        data: {
          'status': 'rejected',
          'isVerified': false,
          'isApproved': false,
          'approvalStatus': 'rejected',
          'rejectedAt': DateTime.now().toIso8601String(),
          if (reasonController.text.isNotEmpty)
            'rejectionReason': reasonController.text,
        },
      );

      // Notify employer
      final jobDoc = await _dbService.getJob(jobId);
      final jobData = jobDoc?.data() as Map<String, dynamic>?;
      final employerId = (jobData?['userId'] ?? jobData?['id'])?.toString();

      if (employerId != null && employerId.isNotEmpty) {
        await _notificationService.sendNotification(
          userId: employerId,
          type: 'job_rejected',
          title: 'Job Rejected',
          body:
              'Your job posting "$jobTitle" was rejected. Please review the reason below and edit your job posting to resubmit.',
          data: {
            'jobId': jobId,
            'jobTitle': jobTitle,
            if (reasonController.text.isNotEmpty)
              'reason': reasonController.text,
          },
          sendEmail: true,
        );
      }

      await _loadPendingJobs();

      if (!mounted) return;
      setState(() => _isLoading = false);
      SnackbarHelper.showError(context, '✗ "$jobTitle" rejected');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      SnackbarHelper.showError(context, 'Error rejecting job: $e');
      debugPrint('Error rejecting job: $e');
    }
  }

  Widget _buildPluginsApprovalList() {
    final colorScheme = Theme.of(context).colorScheme;
    final allPending = [..._pendingGigs, ..._pendingCourses];

    if (allPending.isEmpty) {
      return Padding(
        padding: AppDesignSystem.paddingL,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                size: 64,
                color: colorScheme.tertiary,
              ),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
              Text(
                'No pending plugins',
                style: AppDesignSystem.titleMedium(context).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
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
      return Padding(
        padding: AppDesignSystem.paddingL,
        child: Center(
          child: Text(
            'No results found',
            style: AppDesignSystem.titleMedium(context).copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPendingPlugins,
      child: ListView.builder(
        padding: AppDesignSystem.paddingHorizontal(AppDesignSystem.spaceL),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
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
      elevation: 6, // Increased for better visibility
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

  Widget _buildHintsControlView() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: AppDesignSystem.paddingL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hints System Control',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
          Text(
            'Control whether hints and tips are shown to users across the app. When disabled, hints are hidden for all users regardless of their individual settings.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
          AppCard(
            variant: SurfaceVariant.elevated,
            child: FutureBuilder<bool>(
              future: HintsService().areHintsEnabled(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final hintsEnabled = snapshot.data ?? true;
                return SwitchListTile(
                  title: Text(
                    'Enable Hints Globally',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    hintsEnabled
                        ? 'Hints are currently enabled for all users'
                        : 'Hints are currently disabled for all users',
                    style: textTheme.bodySmall,
                  ),
                  value: hintsEnabled,
                  onChanged: (value) async {
                    try {
                      await HintsService().setAdminHintsEnabled(value);
                      HintsService().clearCache();
                      if (!context.mounted) return;
                      setState(() {});
                      if (!context.mounted) return;
                      SnackbarHelper.showSuccess(
                        context,
                        value
                            ? 'Hints enabled for all users'
                            : 'Hints disabled for all users',
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      SnackbarHelper.showError(
                        context,
                        'Failed to update hints setting: $e',
                      );
                    }
                  },
                );
              },
            ),
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
          AppCard(
            variant: SurfaceVariant.elevated,
            child: FutureBuilder<bool>(
              future: HintsService().areAIHintsEnabled(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final aiHintsEnabled = snapshot.data ?? false;
                return SwitchListTile(
                  title: Text(
                    'Enable AI-Powered Hints',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    aiHintsEnabled
                        ? 'AI hints are enabled. Hints will be generated using AI based on user context and codebase knowledge.'
                        : 'AI hints are disabled. Only regular hints will be shown.',
                    style: textTheme.bodySmall,
                  ),
                  value: aiHintsEnabled,
                  onChanged: (value) async {
                    try {
                      await HintsService().setAIHintsEnabled(value);
                      HintsService().clearCache();
                      AIHintsService().clearCache();
                      if (!context.mounted) return;
                      setState(() {});
                      if (!context.mounted) return;
                      SnackbarHelper.showSuccess(
                        context,
                        value
                            ? 'AI hints enabled. AI will generate smart, contextual hints.'
                            : 'AI hints disabled. Using regular hints only.',
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      SnackbarHelper.showError(
                        context,
                        'Failed to update AI hints setting: $e',
                      );
                    }
                  },
                );
              },
            ),
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
          AppCard(
            variant: SurfaceVariant.standard,
            child: Padding(
              padding: AppDesignSystem.paddingM,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
                      Text(
                        'About Hints System',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                  Text(
                    'Hints help users discover features and get the most out of the app. Users can also control hints in their profile settings, but this global setting takes precedence.\n\nAI-Powered Hints: When enabled, AI will generate contextual hints based on the user\'s role, profile, and screen context. AI hints learn from existing hints and the codebase to provide smarter guidance. If AI is not available, no hints will be shown (no fallback).',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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
}

/// Full screen company details view
class _CompanyDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> company;
  final String docId;
  final String status;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onRevoke;
  final VoidCallback onReapprove;
  final VoidCallback onViewKyc;

  const _CompanyDetailsScreen({
    required this.company,
    required this.docId,
    required this.status,
    required this.onApprove,
    required this.onReject,
    required this.onRevoke,
    required this.onReapprove,
    required this.onViewKyc,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final companyName = company['company_name'] ?? 'Unknown Company';
    final regNumber = company['registration_number'] ?? 'N/A';
    final industry = company['industry'] ?? 'N/A';
    final email = company['email'] ?? 'N/A';
    final phone = company['phone_number'] ?? 'N/A';
    final address = company['address'] ?? 'N/A';
    final website = company['website'] ?? '';
    final description = company['company_description'] ?? 'No description';
    final contactPerson = company['name'] ?? 'N/A';
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

    return Scaffold(
      appBar: AppAppBar(
        title: companyName,
        variant: AppBarVariant.primary,
      ),
      body: SingleChildScrollView(
        padding: AppDesignSystem.paddingL,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            AppCard(
              padding: AppDesignSystem.paddingL,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    backgroundImage:
                        userImage.isNotEmpty ? NetworkImage(userImage) : null,
                    child: userImage.isEmpty
                        ? Icon(Icons.business,
                            size: 40, color: colorScheme.primary)
                        : null,
                  ),
                  AppDesignSystem.horizontalSpace(AppDesignSystem.spaceL),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          companyName,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.primary,
                          ),
                        ),
                        AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                        Text(
                          industry,
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.tertiary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (created != null) ...[
                          AppDesignSystem.verticalSpace(
                              AppDesignSystem.spaceXS),
                          Text(
                            'Applied: ${DateFormat('MMM d, y').format(created)}',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),

            // Details Section
            AppCard(
              padding: AppDesignSystem.paddingL,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Company Information',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                  _buildDetailRow(
                      context, 'Registration Number', regNumber, Icons.numbers),
                  _buildDetailRow(
                      context, 'Contact Person', contactPerson, Icons.person),
                  if (email != 'N/A' || phone != 'N/A') ...[
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                    ContactActionRow(
                      email: email != 'N/A' ? email : null,
                      phoneNumber: phone != 'N/A' ? phone : null,
                      compact: false,
                    ),
                  ],
                  _buildDetailRow(
                      context, 'Address', address, Icons.location_on),
                  if (website.isNotEmpty)
                    _buildDetailRow(
                        context, 'Website', website, Icons.language),

                  const Divider(height: 32),

                  Text(
                    'Company Description',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                  Text(
                    description,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      height: 1.6,
                    ),
                  ),

                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceXL),

                  // KYC Docs
                  StandardButton(
                    label: 'View KYC Documents',
                    type: StandardButtonType.secondary,
                    onPressed: onViewKyc,
                    icon: Icons.folder_open,
                    fullWidth: true,
                  ),

                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),

                  // Action Buttons
                  if (status == 'pending')
                    Row(
                      children: [
                        Expanded(
                          child: StandardButton(
                            label: 'Approve',
                            type: StandardButtonType.success,
                            onPressed: onApprove,
                            icon: Icons.check,
                          ),
                        ),
                        AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
                        Expanded(
                          child: StandardButton(
                            label: 'Reject',
                            type: StandardButtonType.danger,
                            onPressed: onReject,
                            icon: Icons.close,
                          ),
                        ),
                      ],
                    ),

                  if (status == 'approved')
                    StandardButton(
                      label: 'Revoke Approval',
                      type: StandardButtonType.secondary,
                      onPressed: onRevoke,
                      icon: Icons.block,
                      fullWidth: true,
                    ),

                  if (status == 'rejected') ...[
                    if (company['rejectionReason'] != null) ...[
                      Container(
                        padding: AppDesignSystem.paddingM,
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: AppDesignSystem.borderRadiusM,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rejection Reason:',
                              style: textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onErrorContainer,
                              ),
                            ),
                            AppDesignSystem.verticalSpace(
                                AppDesignSystem.spaceS),
                            Text(
                              company['rejectionReason'],
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onErrorContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                    ],
                    StandardButton(
                      label: 'Re-approve',
                      type: StandardButtonType.success,
                      onPressed: onReapprove,
                      icon: Icons.check_circle,
                      fullWidth: true,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      BuildContext context, String label, String value, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: AppDesignSystem.spaceM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                Text(
                  value,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
