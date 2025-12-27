import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/standard_button.dart';
import 'package:freelance_app/widgets/common/app_chip.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';
import 'package:freelance_app/models/opportunity_model.dart';

/// Youth Opportunities Hub - Dynamic plugin for youth opportunities
/// Production-ready: Loads from Firestore 'youth_opportunities' collection
class YouthOpportunitiesScreen extends StatefulWidget {
  const YouthOpportunitiesScreen({super.key});

  @override
  State<YouthOpportunitiesScreen> createState() =>
      _YouthOpportunitiesScreenState();
}

class _YouthOpportunitiesScreenState extends State<YouthOpportunitiesScreen> {
  final _firestore = FirebaseFirestore.instance;
  String _keyword = '';
  int _selectedTabIndex = 0;

  // Error handling helper methods
  Widget _buildErrorCard(String message) {
    final theme = Theme.of(context);
    return AppCard(
      padding: AppDesignSystem.paddingM,
      elevation: 2,
      child: Text(
        message,
        style: theme.textTheme.labelLarge?.copyWith(
          color: Colors.red,
        ),
      ),
    );
  }

  Widget _buildWarningCard(String message) {
    final theme = Theme.of(context);
    return AppCard(
      padding: AppDesignSystem.paddingM,
      elevation: 2,
      child: Text(
        message,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HintsWrapper(
      screenId: 'youth_opportunities',
      child: Scaffold(
        resizeToAvoidBottomInset: true, // Critical for keyboard handling
        appBar: AppAppBar(
          title: 'Youth Opportunities Hub',
          variant: AppBarVariant.primary,
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
            ),
          ],
        ),
        body: DefaultTabController(
          length: 4,
          initialIndex: _selectedTabIndex,
          child: Column(
            children: [
              Material(
                color: Theme.of(context).colorScheme.surface,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  child: TabBar(
                    isScrollable: true,
                    onTap: (index) {
                      setState(() => _selectedTabIndex = index);
                    },
                    tabs: const [
                      Tab(text: 'All'),
                      Tab(text: 'Internships'),
                      Tab(text: 'Scholarships'),
                      Tab(text: 'Programs'),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildOpportunityList(category: null),
                    _buildOpportunityList(category: 'Internship'),
                    _buildOpportunityList(category: 'Scholarship'),
                    _buildOpportunityList(category: 'Program'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOpportunityList({String? category}) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('youth_opportunities')
        .where('status', isEqualTo: 'active')
        .where('approvalStatus', isEqualTo: 'approved')
        .orderBy('approvalStatus', descending: false)
        .orderBy('createdAt', descending: true);

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading opportunities: ${snapshot.error}'),
          );
        }

        final allOpportunities = snapshot.data?.docs
                .map((doc) => OpportunityModel.fromMap(doc.data(), doc.id))
                .toList() ??
            [];

        final keyword = _keyword.trim().toLowerCase();
        final filtered = keyword.isEmpty
            ? allOpportunities
            : allOpportunities.where((o) {
                final title = o.title.toLowerCase();
                final org = o.organizationName.toLowerCase();
                final cat = o.category.toLowerCase();
                return title.contains(keyword) ||
                    org.contains(keyword) ||
                    cat.contains(keyword);
              }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Padding(
              padding: AppDesignSystem.paddingM,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                  Text(
                    keyword.isEmpty
                        ? 'No opportunities available'
                        : 'No opportunities match your filter',
                    style: AppDesignSystem.titleMedium(context),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: AppDesignSystem.paddingM,
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final opportunity = filtered[index];
            
            // Validate critical fields
            if (opportunity.title.isEmpty) {
              debugPrint('❌ ERROR: Missing title for opportunity');
              return _buildErrorCard('Opportunity data incomplete (missing title)');
            }
            
            if (opportunity.organizationName.isEmpty) {
              debugPrint('⚠️ Warning: Missing organization name for opportunity');
              return _buildWarningCard('Organization information unavailable');
            }
            
            return _OpportunityCard(
              opportunity: opportunity,
              onTap: () => _showOpportunityDetails(opportunity),
            );
          },
        );
      },
    );
  }

  void _showFilterDialog() {
    final controller = TextEditingController(text: _keyword);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true, // Allow scrolling when keyboard appears
        title: const Text('Filter Opportunities'),
        content: TextField(
          controller: controller,
          scrollPadding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 80,
          ),
          decoration: const InputDecoration(
            labelText: 'Keyword',
            hintText: 'e.g. internship, scholarship, tech',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          StandardButton(
            label: 'Clear',
            type: StandardButtonType.text,
            onPressed: () {
              setState(() => _keyword = '');
              Navigator.pop(context);
            },
          ),
          StandardButton(
            label: 'Apply',
            onPressed: () {
              setState(() => _keyword = controller.text);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  void _showOpportunityDetails(OpportunityModel opportunity) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(opportunity.title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Organization: ${opportunity.organizationName}'),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                Text('Category: ${opportunity.category}'),
                if (opportunity.ageRange != null)
                  Text('Age range: ${opportunity.ageRange}'),
                if (opportunity.location != null)
                  Text('Location: ${opportunity.location}'),
                if (opportunity.deadline != null) ...[
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                  Text(
                    'Deadline: ${opportunity.deadline!.day}/${opportunity.deadline!.month}/${opportunity.deadline!.year}',
                  ),
                ],
                if (opportunity.description.isNotEmpty) ...[
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                  Text(opportunity.description),
                ],
                if (opportunity.applicationUrl != null) ...[
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                  StandardButton(
                    label: 'Apply Now',
                    onPressed: () {
                      // Open application URL
                      Navigator.pop(context);
                    },
                    type: StandardButtonType.primary,
                    icon: Icons.open_in_new,
                  ),
                ],
              ],
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
}

class _OpportunityCard extends StatelessWidget {
  final OpportunityModel opportunity;
  final VoidCallback onTap;

  const _OpportunityCard({
    required this.opportunity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      margin: EdgeInsets.only(bottom: AppDesignSystem.spaceM),
      onTap: onTap,
      padding: AppDesignSystem.paddingM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  opportunity.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              AppChip(
                label: opportunity.category,
              ),
            ],
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
          Text(
            opportunity.organizationName,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
          Row(
            children: [
              if (opportunity.ageRange != null) ...[
                Icon(Icons.cake, size: 16, color: colorScheme.onSurfaceVariant),
                AppDesignSystem.horizontalSpace(AppDesignSystem.spaceXS),
                Text(
                  'Age: ${opportunity.ageRange}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
              ],
              if (opportunity.deadline != null) ...[
                Icon(Icons.calendar_today,
                    size: 16, color: colorScheme.onSurfaceVariant),
                AppDesignSystem.horizontalSpace(AppDesignSystem.spaceXS),
                Text(
                  'Deadline: ${opportunity.deadline!.day}/${opportunity.deadline!.month}/${opportunity.deadline!.year}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
          StandardButton(
            label: 'View Details & Apply',
            onPressed: onTap,
            type: StandardButtonType.primary,
            icon: Icons.arrow_forward,
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}
