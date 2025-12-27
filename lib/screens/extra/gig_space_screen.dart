import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/app_chip.dart';
import 'package:freelance_app/widgets/common/standard_button.dart';
import 'package:freelance_app/utils/currency_formatter.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';
import 'package:freelance_app/widgets/common/common_widgets.dart';
import 'package:freelance_app/screens/plugins_hub/gig_posting_screen.dart';

class GigSpaceScreen extends StatefulWidget {
  const GigSpaceScreen({super.key});

  @override
  State<GigSpaceScreen> createState() => _GigSpaceScreenState();
}

class _GigSpaceScreenState extends State<GigSpaceScreen> {
  String _keyword = '';
  final _authService = FirebaseAuthService();
  final _firestore = FirebaseFirestore.instance;

  // Error handling helper methods
  double? _parseGigPrice(dynamic gig) {
    try {
      final price = (gig['price'] as num?)?.toDouble();
      if (price == null || price < 0) {
        return null;
      }
      return price;
    } catch (e) {
      debugPrint('❌ ERROR: Failed to parse gig price: $e');
      return null;
    }
  }

  double? _parseGigRating(dynamic gig) {
    try {
      final rating = (gig['rating'] as num?)?.toDouble();
      // Rating can be 0, just ensure it's a valid number
      if (rating == null) {
        return null;
      }
      return rating;
    } catch (e) {
      debugPrint('⚠️ Warning: Failed to parse gig rating: $e');
      return null;
    }
  }

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

  Widget _buildPlaceholderGigCard(String message) {
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
      screenId: 'gig_space',
      child: Scaffold(
      resizeToAvoidBottomInset: true, // Critical for keyboard handling
      appBar: AppAppBar(
        title: 'Gig Space',
        variant: AppBarVariant.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GigPostingScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
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
                child: const TabBar(
                  tabs: [
                    Tab(text: 'Browse Gigs'),
                    Tab(text: 'My Gigs'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildBrowseGigs(),
                  _buildMyGigs(),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildBrowseGigs() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('gigs')
          .where('status', isEqualTo: 'active')
          .where('approvalStatus', isEqualTo: 'approved')
          .where('isApproved', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading gigs: ${snapshot.error}'),
          );
        }

        final allGigs = snapshot.data?.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            ...data,
            'id': doc.id,
          };
        }).toList() ?? [];

        final keyword = _keyword.trim().toLowerCase();
        final filtered = keyword.isEmpty
            ? allGigs
            : allGigs.where((g) {
                final title = (g['title'] ?? '').toString().toLowerCase();
                final freelancer = (g['freelancerName'] ?? '').toString().toLowerCase();
                final category = (g['category'] ?? '').toString().toLowerCase();
                return title.contains(keyword) ||
                    freelancer.contains(keyword) ||
                    category.contains(keyword);
              }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Padding(
              padding: AppDesignSystem.paddingM,
              child: Text(
                keyword.isEmpty
                    ? 'No gigs available'
                    : 'No gigs match your search',
              ),
            ),
          );
        }

        return ListView(
          padding: AppDesignSystem.paddingM,
          children: filtered.map((g) {
            final gigId = (g['id'] ?? '').toString();
            final title = (g['title'] ?? '').toString();
            final freelancer = (g['freelancerName'] ?? '').toString();
            
            // Error handling: price is required
            final price = _parseGigPrice(g);
            if (price == null) {
              debugPrint('⚠️ Warning: Missing price for gig $gigId, showing placeholder');
              return _buildPlaceholderGigCard('Price unavailable');
            }
            
            final deliveryTime = (g['deliveryTime'] ?? '').toString();
            
            // Error handling: rating should not be missing but show placeholder if null
            final rating = _parseGigRating(g);
            if (rating == null) {
              debugPrint('⚠️ Warning: Missing rating for gig $gigId');
            }
            final category = (g['category'] ?? '').toString();

            return _GigCard(
              title: title,
              freelancer: freelancer,
              price: price,
              deliveryTime: deliveryTime,
              rating: rating ?? 0.0,
              category: category,
              onTap: () {
                _showGigDetails(
                  gigId: gigId,
                  title: title,
                  freelancer: freelancer,
                  price: price,
                  deliveryTime: deliveryTime,
                  rating: rating ?? 0.0,
                  category: category,
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  void _showSearchDialog() {
    final controller = TextEditingController(text: _keyword);
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          scrollable: true, // Allow scrolling when keyboard appears
          title: const Text('Search Gigs'),
          content: TextField(
            controller: controller,
            scrollPadding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 80,
            ),
            decoration: const InputDecoration(
              labelText: 'Keyword',
              hintText: 'e.g. Flutter, design, writing',
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
        );
      },
    ).then((_) => controller.dispose());
  }

  void _showGigDetails({
    required String gigId,
    required String title,
    required String freelancer,
    required double price,
    required String deliveryTime,
    required double rating,
    required String category,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Category: $category'),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
              Text('Freelancer: $freelancer'),
              Text('Rating: ${rating.toStringAsFixed(1)}'),
              Text('Delivery: $deliveryTime'),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
              Text('Price: ${CurrencyFormatter.formatBWP(price)}'),
            ],
          ),
          actions: [
            StandardButton(
              label: 'Apply for Gig',
              type: StandardButtonType.primary,
              onPressed: () {
                Navigator.pop(context);
                _applyForGig(gigId, title);
              },
              icon: Icons.send,
            ),
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

  Future<void> _applyForGig(String gigId, String gigTitle) async {
    final user = _authService.getCurrentUser();
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to apply')),
        );
      }
      return;
    }

    try {
      // Check if already applied
      final existing = await _firestore
          .collection('gigs')
          .doc(gigId)
          .collection('applications')
          .where('applicantId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You have already applied to this gig')),
          );
        }
        return;
      }

      // Create application
      await _firestore
          .collection('gigs')
          .doc(gigId)
          .collection('applications')
          .add({
        'applicantId': user.uid,
        'applicantEmail': user.email ?? '',
        'status': 'pending',
        'appliedAt': FieldValue.serverTimestamp(),
        'gigTitle': gigTitle,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application submitted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error applying: $e')),
        );
      }
    }
  }

  Widget _buildMyGigs() {
    final user = _authService.getCurrentUser();
    if (user == null) {
      return EmptyState(
        icon: Icons.login,
        title: 'Please log in',
        message: 'You need to be logged in to view your gigs.',
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('gigs')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading gigs: ${snapshot.error}'),
          );
        }

        final myGigs = snapshot.data?.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            ...data,
            'id': doc.id,
          };
        }).toList() ?? [];

        if (myGigs.isEmpty) {
          final colorScheme = Theme.of(context).colorScheme;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.work_outline,
                  size: 64,
                  color: colorScheme.onSurfaceVariant,
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                const Text(
                  'No gigs posted yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                StandardButton(
                  label: 'Create Your First Gig',
                  type: StandardButtonType.primary,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GigPostingScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: AppDesignSystem.paddingM,
          children: myGigs.map((g) {
            final gigId = (g['id'] ?? '').toString();
            final title = (g['title'] ?? '').toString();
            final freelancer = (g['freelancerName'] ?? '').toString();
            
            // Error handling: price is required
            final price = _parseGigPrice(g);
            if (price == null) {
              debugPrint('❌ ERROR: Missing price for my gig $gigId');
              return _buildErrorCard('Unable to load gig pricing');
            }
            
            final deliveryTime = (g['deliveryTime'] ?? '').toString();
            
            // Error handling: rating missing (show 0 but log warning)
            final rating = _parseGigRating(g);
            if (rating == null) {
              debugPrint('⚠️ Warning: Missing rating for my gig ${g['id']}');
            }
            
            final category = (g['category'] ?? '').toString();
            final status = (g['status'] ?? '').toString();
            final approvalStatus = (g['approvalStatus'] ?? '').toString();

            return _GigCard(
              title: title,
              freelancer: freelancer,
              price: price,
              deliveryTime: deliveryTime,
              rating: rating ?? 0.0,
              category: category,
              status: status,
              approvalStatus: approvalStatus,
              onTap: () {
                _showGigDetails(
                  gigId: gigId,
                  title: title,
                  freelancer: freelancer,
                  price: price,
                  deliveryTime: deliveryTime,
                  rating: rating ?? 0.0,
                  category: category,
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
}

class _GigCard extends StatelessWidget {
  final String title;
  final String freelancer;
  final double price;
  final String deliveryTime;
  final double rating;
  final String category;
  final String? status;
  final String? approvalStatus;
  final VoidCallback onTap;

  const _GigCard({
    required this.title,
    required this.freelancer,
    required this.price,
    required this.deliveryTime,
    required this.rating,
    required this.category,
    this.status,
    this.approvalStatus,
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
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              AppChip(
                label: category,
              ),
              if (status == 'pending' || approvalStatus == 'pending')
                AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
              if (status == 'pending' || approvalStatus == 'pending')
                Container(
                  padding: AppDesignSystem.paddingS,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: AppDesignSystem.borderRadiusS,
                  ),
                  child: Text(
                    'Pending',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
          Row(
            children: [
              Icon(Icons.person, size: 16, color: colorScheme.onSurfaceVariant),
              AppDesignSystem.horizontalSpace(AppDesignSystem.spaceXS),
              Text(
                freelancer,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
              Icon(Icons.star, size: 16, color: colorScheme.secondary),
              AppDesignSystem.horizontalSpace(AppDesignSystem.spaceXS),
              Text(
                rating.toString(),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 16, color: colorScheme.onSurfaceVariant),
                  AppDesignSystem.horizontalSpace(AppDesignSystem.spaceXS),
                  Text(
                    deliveryTime,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Text(
                CurrencyFormatter.formatBWP(price),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: colorScheme.tertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
