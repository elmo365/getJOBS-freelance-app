import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:freelance_app/models/job_model.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/services/firebase/firebase_config.dart';
import 'package:freelance_app/services/search/saved_search_service.dart';
import 'package:freelance_app/services/validation/input_validators.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/utils/global_variables.dart';
import 'package:freelance_app/widgets/common/micro_interactions.dart';
import 'package:freelance_app/widgets/shimmer_loading.dart';
import 'package:freelance_app/widgets/common/page_transitions.dart';
import 'package:freelance_app/widgets/modern_job_card.dart';

import '../homescreen/sidebar.dart';
import '../homescreen/components/job_details.dart';
import 'package:freelance_app/services/ai/gemini_ai_service.dart';
import 'package:freelance_app/widgets/common/snackbar_helper.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';

class Search extends StatefulWidget {
  static const routename = 'search';

  final String? initialCategory;

  const Search({super.key, this.initialCategory});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final _authService = FirebaseAuthService();
  final _savedSearchService = SavedSearchService();
  final _firestore = FirebaseFirestore.instance;

  final _keywordController = TextEditingController();
  final _locationController = TextEditingController();

  String? _category;
  String? _experienceLevel;
  String _sort = 'newest'; // newest | oldest

  // Simple Firestore pagination: fetch in growing batches using `limit`.
  static const int _pageSize = 20;
  int _currentLimit = _pageSize;

  String? get _uid => _authService.getCurrentUser()?.uid;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialCategory?.trim();
    if (initial != null && initial.isNotEmpty && initial != 'RECENT JOBS') {
      _category = initial;
    }
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Query<Map<String, dynamic>> _buildJobsQuery() {
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirebaseConfig.jobsCollection)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(50);

    if (_category != null && _category!.isNotEmpty) {
      query = query.where('jobCategory', isEqualTo: _category);
    }

    if (_experienceLevel != null && _experienceLevel!.isNotEmpty) {
      query = query.where('experienceLevel', isEqualTo: _experienceLevel);
    }

    return query;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _applyClientSideFilters(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    // Sanitize search input to prevent injection attacks
    final keyword = InputValidators.sanitizeSearchInput(_keywordController.text).toLowerCase();
    final locationQuery = InputValidators.sanitizeSearchInput(_locationController.text).toLowerCase();

    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> filtered = docs;
    if (keyword.isNotEmpty) {
      filtered = filtered.where((doc) {
        final data = doc.data();
        final title = (data['title'] ?? '').toString().toLowerCase();
        final desc = (data['description'] ?? data['desc'] ?? '')
            .toString()
            .toLowerCase();
        final company = (data['name'] ?? data['employerName'] ?? '')
            .toString()
            .toLowerCase();
        final category = (data['jobCategory'] ?? data['category'] ?? '')
            .toString()
            .toLowerCase();
        return title.contains(keyword) ||
            desc.contains(keyword) ||
            company.contains(keyword) ||
            category.contains(keyword);
      });
    }

    if (locationQuery.isNotEmpty) {
      filtered = filtered.where((doc) {
        final data = doc.data();
        final location = (data['location'] ??
                data['address'] ??
                data['jobLocation'] ??
                data['job_location'] ??
                '')
            .toString()
            .toLowerCase();
        return location.contains(locationQuery);
      });
    }

    final list = filtered.toList(growable: false);
    if (_sort == 'oldest') {
      return list.reversed.toList(growable: false);
    }
    return list;
  }

  Future<void> _saveCurrentSearch() async {
    final uid = _uid;
    if (uid == null) return;

    final keyword = _keywordController.text.trim();
    final locationQuery = _locationController.text.trim();
    final parts = <String>[];
    if (keyword.isNotEmpty) parts.add(keyword);
    if (_category != null && _category!.isNotEmpty) parts.add(_category!);
    if (_experienceLevel != null && _experienceLevel!.isNotEmpty) {
      parts.add(_experienceLevel!);
    }
    if (locationQuery.isNotEmpty) parts.add(locationQuery);
    final label = parts.isEmpty ? 'Saved search' : parts.join(' • ');

    await _savedSearchService.saveSearch(
      userId: uid,
      label: label,
      keyword: keyword.isEmpty ? null : keyword,
      category: _category,
      experienceLevel: _experienceLevel,
      locationQuery: locationQuery.isEmpty ? null : locationQuery,
      sort: _sort,
    );

    if (!mounted) return;
    SnackbarHelper.showSuccess(
      context,
      'Your search has been saved. You can access it from your saved searches.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final uid = _uid;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppAppBar(
        title: 'Job Discovery',
        variant: AppBarVariant.primary,
        actions: [
          MicroInteractions.scaleOnTap(
            onTap: uid == null ? () {} : _saveCurrentSearch,
            child: Container(
              margin: const EdgeInsets.only(right: AppDesignSystem.spaceS),
              padding: AppDesignSystem.paddingS,
              decoration: BoxDecoration(
                color: AppDesignSystem.brandYellow
                    .withValues(alpha: 0.15), // BOTS Yellow (balanced)
                borderRadius: AppDesignSystem.borderRadiusM,
              ),
              child: Icon(
                Icons.bookmark_add_outlined,
                color: uid == null
                    ? colorScheme.onSurface.withValues(alpha: 0.38)
                    : AppDesignSystem.brandYellow, // BOTS Yellow (balanced)
                size: 22,
              ),
            ),
          ),
        ],
      ),
      drawer: const SideBar(),
      body: HintsWrapper(
        screenId: 'search',
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: AppDesignSystem.heroCard(
                context: context,
                primaryColor: AppDesignSystem
                    .brandBlue, // Blue gradient instead of yellow
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MicroInteractions.fadeInListItem(
                      child: Text(
                        'Find Your Perfect Job',
                        style: AppDesignSystem.screenTitle(context).copyWith(
                          color: Theme.of(context).colorScheme.surface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      index: 0,
                      delayPerItem: const Duration(milliseconds: 100),
                    ),
                    const SizedBox(height: AppDesignSystem.spaceS),
                    MicroInteractions.fadeInListItem(
                      child: Text(
                        'Discover opportunities that match your skills and career goals',
                        style: AppDesignSystem.bodyLarge(context).copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .surface
                              .withValues(alpha: 0.9),
                          height: 1.6,
                        ),
                      ),
                      index: 1,
                      delayPerItem: const Duration(milliseconds: 100),
                    ),
                  ],
                ),
              ),
            ),
            // Search Filters
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppDesignSystem.spaceL),
                child: Column(
                  children: [
                    // Main Search Inputs
                    MicroInteractions.fadeInListItem(
                      child: Container(
                        padding: const EdgeInsets.all(AppDesignSystem.spaceM),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                          borderRadius:
                              BorderRadius.circular(AppDesignSystem.radiusL),
                          border: Border.all(
                            color: colorScheme.outlineVariant
                                .withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(
                                    AppDesignSystem.radiusM),
                              ),
                              child: TextField(
                                controller: _keywordController,
                                textInputAction: TextInputAction.search,
                                onSubmitted: (value) {
                                  if (value.trim().split(' ').length > 3) {
                                    SnackbarHelper.showInfo(
                                      context,
                                      'Tip: For longer searches, tap the ✨ button to use AI Smart Search for better results!',
                                    );
                                  }
                                  setState(() {});
                                },
                                decoration: InputDecoration(
                                  hintText: 'Job title, company, or keywords',
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: colorScheme.primary,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.auto_awesome),
                                    color: AppDesignSystem.brandYellow,
                                    tooltip: 'AI Smart Search',
                                    onPressed: _performSmartSearch,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: AppDesignSystem.spaceM,
                                    vertical: AppDesignSystem.spaceM,
                                  ),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(height: AppDesignSystem.spaceS),
                            // Location Search
                            Container(
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(
                                    AppDesignSystem.radiusM),
                              ),
                              child: TextField(
                                controller: _locationController,
                                decoration: InputDecoration(
                                  hintText:
                                      'Location (city, country, or "remote")',
                                  prefixIcon: Icon(
                                    Icons.location_on_outlined,
                                    color: colorScheme.secondary,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: AppDesignSystem.spaceM,
                                    vertical: AppDesignSystem.spaceM,
                                  ),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                      ),
                      index: 2,
                      delayPerItem: const Duration(milliseconds: 100),
                    ),
                    const SizedBox(height: AppDesignSystem.spaceL),
                    // Advanced Filters
                    MicroInteractions.fadeInListItem(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Filters',
                            style:
                                AppDesignSystem.titleMedium(context).copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppDesignSystem.spaceM),
                          Row(
                            children: [
                              Expanded(
                                child: _ModernDropdownField<String>(
                                  label: 'Category',
                                  value: _category,
                                  items: jobCategories,
                                  onChanged: (v) => setState(() {
                                    _category = v;
                                    _currentLimit = _pageSize;
                                  }),
                                  allowClear: true,
                                ),
                              ),
                              const SizedBox(width: AppDesignSystem.spaceM),
                              Expanded(
                                child: _ModernDropdownField<String>(
                                  label: 'Experience',
                                  value: _experienceLevel,
                                  items: const ['Entry', 'Mid', 'Senior'],
                                  onChanged: (v) => setState(() {
                                    _experienceLevel = v;
                                    _currentLimit = _pageSize;
                                  }),
                                  allowClear: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDesignSystem.spaceM),
                          Row(
                            children: [
                              Expanded(
                                child: _ModernDropdownField<String>(
                                  label: 'Sort by',
                                  value: _sort,
                                  items: const ['newest', 'oldest'],
                                  itemLabel: (v) => v == 'newest'
                                      ? 'Newest First'
                                      : 'Oldest First',
                                  onChanged: (v) => setState(() {
                                    _sort = v ?? 'newest';
                                    _currentLimit = _pageSize;
                                  }),
                                  allowClear: false,
                                ),
                              ),
                              const SizedBox(width: AppDesignSystem.spaceM),
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: BorderRadius.circular(
                                      AppDesignSystem.radiusM),
                                ),
                                child: IconButton(
                                  onPressed: _clearFilters,
                                  icon: Icon(
                                    Icons.clear_all,
                                    color: colorScheme.onPrimary,
                                  ),
                                  tooltip: 'Clear all filters',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      index: 3,
                      delayPerItem: const Duration(milliseconds: 100),
                    ),
                  ],
                ),
              ),
            ),
            // Results header
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDesignSystem.spaceL,
                vertical: AppDesignSystem.spaceM,
              ),
              sliver: SliverToBoxAdapter(
                child: _buildResultsHeader(),
              ),
            ),
            // Job results list (full-height, scrolls with screen)
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDesignSystem.spaceL,
              ),
              sliver: SliverToBoxAdapter(
                child: _buildResultsList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the "X jobs found" / "No jobs available" header text.
  Widget _buildResultsHeader() {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildJobsQuery().limit(_currentLimit).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text(
            'Searching...',
            style: AppDesignSystem.titleMedium(context),
          );
        }

        final docs = snapshot.data?.docs ??
            <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        final totalJobs = docs.length;
        final filtered = _applyClientSideFilters(
            docs.cast<QueryDocumentSnapshot<Map<String, dynamic>>>());
        final count = filtered.length;

        if (totalJobs == 0) {
          return Text(
            'No jobs available',
            style: AppDesignSystem.titleMedium(context),
          );
        } else if (count == 0) {
          return Text(
            'No jobs match your search',
            style: AppDesignSystem.titleMedium(context),
          );
        } else {
          return Text(
            count == 1 ? '1 job found' : '$count jobs found',
            style: AppDesignSystem.titleMedium(context),
          );
        }
      },
    );
  }

  /// Builds the job results list as part of the main scroll (no inner scroll box).
  Widget _buildResultsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildJobsQuery().limit(_currentLimit).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: List.generate(
              5,
              (index) => const ShimmerListItem(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: AppDesignSystem.spaceM),
                Text(
                  'Unable to Load Jobs',
                  style: AppDesignSystem.headlineSmall(context),
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                Text(
                  'We couldn\'t load job listings right now. Please check your internet connection and try again.',
                  style: AppDesignSystem.bodyMedium(context).copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data?.docs ??
            <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        final hasMorePotential = docs.length == _currentLimit;
        final filtered = _applyClientSideFilters(
            docs.cast<QueryDocumentSnapshot<Map<String, dynamic>>>());

        if (filtered.isEmpty) {
          final totalJobs = docs.length;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  totalJobs == 0 ? Icons.work_off_outlined : Icons.search_off,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                Text(
                  totalJobs == 0
                      ? 'No Jobs Available'
                      : 'No Jobs Match Your Search',
                  style: AppDesignSystem.headlineSmall(context),
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                Text(
                  totalJobs == 0
                      ? 'There are currently no job listings in the database. Check back later or contact support if you believe this is an error.'
                      : 'Try adjusting your search filters or clearing some filters to see more results.',
                  style: AppDesignSystem.bodyMedium(context).copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final children = filtered.asMap().entries.map((entry) {
          final index = entry.key;
          final doc = entry.value;
          final data = doc.data();
          final job = JobModel.fromMap(data, doc.id);

          return MicroInteractions.fadeInListItem(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppDesignSystem.spaceM),
              child: ModernJobCard(
                job: job,
                contactEmail: data['email'] ?? '',
                contactName: data['employerName'] ?? data['name'] ?? '',
                contactImage: data['employerImage'] ?? data['userImage'] ?? '',
                borderRadius: BorderRadius.zero,
                showHero: true,
                onTap: () {
                  context.pushModern(
                    page: JobDetailsScreen(
                      id: job.employerId,
                      jobId: job.jobId,
                    ),
                    type: RouteType.hero,
                    heroTag: 'job-${job.jobId}',
                  );
                },
              ),
            ),
            index: index,
            delayPerItem: const Duration(milliseconds: 50),
          );
        }).toList();

        if (hasMorePotential) {
          children.add(
            Padding(
              padding: const EdgeInsets.only(top: AppDesignSystem.spaceS),
              child: Center(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentLimit += _pageSize;
                    });
                  },
                  icon: const Icon(Icons.expand_more),
                  label: const Text('Load more jobs'),
                ),
              ),
            ),
          );
        }

        return Column(children: children);
      },
    );
  }

  void _clearFilters() {
    setState(() {
      _keywordController.clear();
      _locationController.clear();
      _category = null;
      _experienceLevel = null;
      _sort = 'newest';
      _currentLimit = _pageSize;
    });
  }

  Future<void> _performSmartSearch() async {
    final query = _keywordController.text.trim();
    if (query.isEmpty) {
      SnackbarHelper.showInfo(
        context,
        'Please type what you\'re looking for in the search box, then tap the ✨ button for AI-powered search.',
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: AppDesignSystem.paddingL,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: AppDesignSystem.borderRadiusL,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
              Text(
                'AI is analyzing your request...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final filters = await GeminiAIService().parseSearchQuery(query);

      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading

      setState(() {
        // Apply extracted filters
        if (filters['keyword'] != null) {
          _keywordController.text = filters['keyword'];
        }
        if (filters['location'] != null) {
          _locationController.text = filters['location'];
        }

        // Map category if it matches widely known categories
        if (filters['category'] != null) {
          final extracted = filters['category'].toString().toLowerCase();
          // Simple matching logic - in production, use better fuzzy matching
          for (final cat in jobCategories) {
            if (cat.toLowerCase().contains(extracted) ||
                extracted.contains(cat.toLowerCase())) {
              _category = cat;
              break;
            }
          }
        }

        if (filters['experienceLevel'] != null) {
          final extracted = filters['experienceLevel'].toString().toLowerCase();
          if (['entry', 'mid', 'senior'].contains(extracted)) {
            _experienceLevel =
                extracted[0].toUpperCase() + extracted.substring(1);
          }
        }

        // Reset pagination whenever AI search changes filters.
        _currentLimit = _pageSize;
      });

      SnackbarHelper.showSuccess(
        context,
        'AI has analyzed your search and applied the best filters. Check the results below!',
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      debugPrint('AI Search error: $e');

      // User-friendly error message
      String errorMessage =
          'Unable to process your search request at the moment. ';
      final errorStr = e.toString().toLowerCase();

      if (errorStr.contains('not ready') ||
          errorStr.contains('not configured')) {
        errorMessage +=
            'AI search is currently unavailable. Please use the standard search filters instead.';
      } else if (errorStr.contains('quota') ||
          errorStr.contains('limit') ||
          errorStr.contains('429')) {
        errorMessage +=
            'AI search is temporarily busy. Please try again in a few moments or use standard search.';
      } else if (errorStr.contains('network') ||
          errorStr.contains('connection')) {
        errorMessage += 'Please check your internet connection and try again.';
      } else {
        errorMessage += 'Please try using the standard search filters below.';
      }

      SnackbarHelper.showError(context, errorMessage);
    }
  }
}

class _ModernDropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T)? itemLabel;
  final void Function(T?) onChanged;
  final bool allowClear;

  const _ModernDropdownField({
    required this.label,
    required this.value,
    required this.items,
    this.itemLabel,
    required this.onChanged,
    required this.allowClear,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppDesignSystem.spaceS),
            child: Text(
              label,
              style: AppDesignSystem.bodyMedium(context).copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          isExpanded: true,
          padding:
              const EdgeInsets.symmetric(horizontal: AppDesignSystem.spaceS),
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
          items: [
            if (allowClear && value != null)
              DropdownMenuItem<T>(
                value: null,
                child: Row(
                  children: [
                    Icon(
                      Icons.clear,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: AppDesignSystem.spaceS),
                    Text(
                      'Clear',
                      style: AppDesignSystem.bodyMedium(context).copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ...items.map((item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Text(
                  itemLabel?.call(item) ?? item.toString(),
                  style: AppDesignSystem.bodyMedium(context),
                ),
              );
            }),
          ],
          onChanged: onChanged,
          dropdownColor: colorScheme.surfaceContainerHighest,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
