import 'package:flutter/material.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';
import 'package:freelance_app/services/connectivity_service.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';
import 'package:freelance_app/widgets/ui/portfolio_section.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/utils/colors.dart';
import 'package:freelance_app/screens/admin/admin_pending_companies_screen.dart';
import 'package:freelance_app/screens/admin/admin_approved_companies_screen.dart';
import 'package:freelance_app/screens/admin/admin_rejected_companies_screen.dart';
import 'package:freelance_app/screens/admin/admin_jobs_screen.dart';
import 'package:freelance_app/screens/admin/admin_plugins_screen.dart';

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen>
    with ConnectivityAware {
  final _dbService = FirebaseDatabaseService();
  List<Map<String, dynamic>> _pendingCompanies = [];
  List<Map<String, dynamic>> _approvedCompanies = [];
  List<Map<String, dynamic>> _rejectedCompanies = [];
  List<Map<String, dynamic>> _pendingJobs = [];
  List<Map<String, dynamic>> _pendingGigs = [];
  List<Map<String, dynamic>> _pendingCourses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!await checkConnectivity(context,
        message:
            'Cannot load statistics without internet. Please connect and try again.')) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      if (mounted) {
        setState(() => _isLoading = true);
      }

      // Load companies
      final companiesResult = await _dbService.searchUsers(isCompany: true, limit: 100);
      final allCompanies = companiesResult.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final docId = doc.id;
            if (docId.isEmpty) return null;
            return {
              ...data,
              'id': docId,
            };
          })
          .where((c) {
            if (c == null) return false;
            final id = c['id'] as String?;
            final isCompany = c['isCompany'] as bool? ?? false;
            return id != null && id.isNotEmpty && isCompany;
          })
          .cast<Map<String, dynamic>>()
          .toList();

      // Load pending jobs
      try {
        final jobsResult = await _dbService
            .getCollection('jobs')
            .where('isVerified', isEqualTo: false)
            .where('status', isEqualTo: 'pending')
            .get();
        _pendingJobs = jobsResult.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            ...data,
            'id': doc.id,
          };
        }).toList();
      } catch (e) {
        debugPrint('Error loading pending jobs: $e');
        _pendingJobs = [];
      }

      // Load pending plugins
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
        _pendingGigs = [];
      }

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
        _pendingCourses = [];
      }

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
      debugPrint('Error loading statistics: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = _pendingCompanies.length;
    final approved = _approvedCompanies.length;
    final rejected = _rejectedCompanies.length;
    final total = pending + approved + rejected;
    final pendingJobs = _pendingJobs.length;
    final pendingPlugins = _pendingGigs.length + _pendingCourses.length;

    return Scaffold(
      backgroundColor: botsSuperLightGrey,
      appBar: AppAppBar(
        title: 'Statistics',
        variant: AppBarVariant.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: AppDesignSystem.paddingL,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Overview
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
                                builder: (_) => const AdminApprovedCompaniesScreen(),
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminPendingCompaniesScreen(),
                              ),
                            );
                          },
                        ),
                        PortfolioCardData(
                          title: 'Approved',
                          value: approved.toString(),
                          subtitle: 'Verified companies',
                          icon: Icons.check_circle,
                          iconColor: AppDesignSystem.brandGreen,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminApprovedCompaniesScreen(),
                              ),
                            );
                          },
                        ),
                        PortfolioCardData(
                          title: 'Rejected',
                          value: rejected.toString(),
                          subtitle: 'Not approved',
                          icon: Icons.cancel,
                          iconColor: AppDesignSystem.errorColor(context),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminRejectedCompaniesScreen(),
                              ),
                            );
                          },
                        ),
                        PortfolioCardData(
                          title: 'Pending Jobs',
                          value: pendingJobs.toString(),
                          subtitle: 'Awaiting approval',
                          icon: Icons.work,
                          iconColor: AppDesignSystem.brandBlue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminJobsScreen(),
                              ),
                            );
                          },
                        ),
                        PortfolioCardData(
                          title: 'Pending Plugins',
                          value: pendingPlugins.toString(),
                          subtitle: 'Awaiting review',
                          icon: Icons.extension,
                          iconColor: AppDesignSystem.brandGreen,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminPluginsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
