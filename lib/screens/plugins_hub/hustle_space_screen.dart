import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/standard_button.dart';
import 'package:freelance_app/widgets/common/standard_input.dart';
import 'package:freelance_app/widgets/common/snackbar_helper.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';
import 'package:freelance_app/utils/currency_formatter.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';

/// Hustle Space - Dynamic plugin for quick job opportunities
/// Production-ready: Loads from Firestore 'hustles' collection
class HustleSpaceScreen extends StatefulWidget {
  const HustleSpaceScreen({super.key});

  @override
  State<HustleSpaceScreen> createState() => _HustleSpaceScreenState();
}

class _HustleSpaceScreenState extends State<HustleSpaceScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _authService = FirebaseAuthService();
  String _keyword = '';

  // Error handling helper methods
  double? _parsePayAmount(dynamic hustle) {
    try {
      final amount = (hustle['payAmount'] as num?)?.toDouble();
      if (amount == null || amount < 0) {
        return null;
      }
      return amount;
    } catch (e) {
      debugPrint('❌ ERROR: Failed to parse payAmount: $e');
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

  @override
  Widget build(BuildContext context) {
    final user = _authService.getCurrentUser();
    final canPost = user != null; // Authenticated users can post

    return HintsWrapper(
      screenId: 'hustle_space',
      child: Scaffold(
      resizeToAvoidBottomInset: true, // Critical for keyboard handling
      appBar: AppAppBar(
        title: 'Hustle Space',
        variant: AppBarVariant.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          if (canPost)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showPostHustleDialog,
              tooltip: 'Post Hustle Opportunity',
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('hustles')
            .where('status', isEqualTo: 'active')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading hustles: ${snapshot.error}'),
            );
          }

          final allHustles = snapshot.data?.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              ...data,
              'id': doc.id,
            };
          }).toList() ?? [];

          final keyword = _keyword.trim().toLowerCase();
          final filtered = keyword.isEmpty
              ? allHustles
              : allHustles.where((h) {
                  final title = (h['title'] ?? '').toString().toLowerCase();
                  final description =
                      (h['description'] ?? '').toString().toLowerCase();
                  final location = (h['location'] ?? '').toString().toLowerCase();
                  final postedBy =
                      (h['postedBy'] ?? h['postedByName'] ?? '')
                          .toString()
                          .toLowerCase();
                  return title.contains(keyword) ||
                      description.contains(keyword) ||
                      location.contains(keyword) ||
                      postedBy.contains(keyword);
                }).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Padding(
                padding: AppDesignSystem.paddingM,
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
                      keyword.isEmpty
                          ? 'No hustle opportunities available'
                          : 'No hustles match your search',
                      style: AppDesignSystem.titleMedium(context),
                      textAlign: TextAlign.center,
                    ),
                    if (canPost) ...[
                      AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                      StandardButton(
                        label: 'Post First Hustle',
                        onPressed: _showPostHustleDialog,
                        type: StandardButtonType.primary,
                        icon: Icons.add,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: AppDesignSystem.paddingM,
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final hustle = filtered[index];
              final title = (hustle['title'] ?? '').toString();
              final description = (hustle['description'] ?? '').toString();
              
              // Error handling: payment amount is required
              final payAmount = _parsePayAmount(hustle);
              if (payAmount == null) {
                debugPrint('❌ ERROR: Missing payAmount for hustle ${hustle['id']}');
                return _buildErrorCard('Unable to load payment information');
              }
              
              final payType = (hustle['payType'] ?? 'hour').toString();
              final location = (hustle['location'] ?? '').toString();
              final postedBy =
                  (hustle['postedBy'] ?? hustle['postedByName'] ?? 'Unknown')
                      .toString();
              final hustleId = (hustle['id'] ?? '').toString();

              return _HustleCard(
                title: title,
                description: description,
                payAmount: payAmount,
                payType: payType,
                location: location,
                postedBy: postedBy,
                onTap: () {
                  _showHustleDetails(
                    hustleId: hustleId,
                    title: title,
                    description: description,
                    payAmount: payAmount,
                    payType: payType,
                    location: location,
                    postedBy: postedBy,
                  );
                },
              );
            },
          );
        },
      ),
      ),
    );
  }

  void _showSearchDialog() {
    final controller = TextEditingController(text: _keyword);
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          scrollable: true, // Allow scrolling when keyboard appears
          title: const Text('Search Hustles'),
          content: TextField(
            controller: controller,
            scrollPadding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 80,
            ),
            decoration: const InputDecoration(
              labelText: 'Keyword',
              hintText: 'e.g. delivery, event, remote',
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

  void _showPostHustleDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final payController = TextEditingController();
    final locationController = TextEditingController();
    final postedByController = TextEditingController();
    String selectedPayType = 'hour';
    bool isSubmitting = false;

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              scrollable: true, // Allow scrolling when keyboard appears
              title: const Text('Post Hustle Opportunity'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StandardInput(
                      controller: titleController,
                      label: 'Title *',
                      hint: 'e.g. Part-time Delivery Driver',
                      prefixIcon: Icons.title,
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                    StandardInput(
                      controller: descriptionController,
                      label: 'Description *',
                      hint: 'Describe the opportunity',
                      prefixIcon: Icons.description,
                      maxLines: 3,
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                    Row(
                      children: [
                        Expanded(
                          child: StandardInput(
                            controller: payController,
                            label: 'Pay Amount *',
                            hint: 'e.g. 15',
                            prefixIcon: Icons.payments,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
                        DropdownButton<String>(
                          value: selectedPayType,
                          items: const [
                            DropdownMenuItem(value: 'hour', child: Text('/hour')),
                            DropdownMenuItem(value: 'day', child: Text('/day')),
                            DropdownMenuItem(value: 'project', child: Text('/project')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() => selectedPayType = value);
                            }
                          },
                        ),
                      ],
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                    StandardInput(
                      controller: locationController,
                      label: 'Location *',
                      hint: 'e.g. Downtown, Remote',
                      prefixIcon: Icons.location_on,
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                    StandardInput(
                      controller: postedByController,
                      label: 'Posted By *',
                      hint: 'Company/Organization name',
                      prefixIcon: Icons.business,
                    ),
                  ],
                ),
              ),
              actions: [
                StandardButton(
                  label: 'Cancel',
                  type: StandardButtonType.text,
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(context),
                ),
                StandardButton(
                  label: isSubmitting ? 'Posting...' : 'Post',
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (titleController.text.trim().isEmpty ||
                              descriptionController.text.trim().isEmpty ||
                              payController.text.trim().isEmpty ||
                              locationController.text.trim().isEmpty ||
                              postedByController.text.trim().isEmpty) {
                            if (context.mounted) {
                              SnackbarHelper.showError(context, 'Please fill all required fields');
                            }
                            return;
                          }

                          setDialogState(() => isSubmitting = true);

                          try {
                            final user = _authService.getCurrentUser();
                            await _firestore.collection('hustles').add({
                              'title': titleController.text.trim(),
                              'description': descriptionController.text.trim(),
                              'payAmount': double.parse(payController.text.trim()),
                              'payType': selectedPayType,
                              'location': locationController.text.trim(),
                              'postedBy': user?.uid ?? '',
                              'postedByName': postedByController.text.trim(),
                              'status': 'active',
                              'approvalStatus': 'pending',
                              'createdAt': FieldValue.serverTimestamp(),
                            });

                            if (context.mounted) {
                              Navigator.pop(context);
                              SnackbarHelper.showSuccess(context, 'Hustle posted successfully!');
                            }
                          } catch (e) {
                            if (context.mounted) {
                              setDialogState(() => isSubmitting = false);
                              SnackbarHelper.showError(context, 'Error posting hustle: $e');
                            }
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      titleController.dispose();
      descriptionController.dispose();
      payController.dispose();
      locationController.dispose();
      postedByController.dispose();
    });
  }

  void _showHustleDetails({
    required String hustleId,
    required String title,
    required String description,
    required double payAmount,
    required String payType,
    required String location,
    required String postedBy,
  }) {
    final pay = payAmount > 0
        ? '${CurrencyFormatter.formatBWP(payAmount, includeDecimals: false)}/$payType'
        : 'Negotiable';

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                Text('Pay: $pay'),
                Text('Location: $location'),
                Text('Posted by: $postedBy'),
              ],
            ),
          ),
          actions: [
            StandardButton(
              label: 'Apply for Hustle',
              type: StandardButtonType.primary,
              onPressed: () {
                Navigator.pop(context);
                _applyForHustle(hustleId, title);
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

  Future<void> _applyForHustle(String hustleId, String hustleTitle) async {
    final user = _authService.getCurrentUser();
    if (user == null) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Please login to apply');
      }
      return;
    }

    try {
      // Check if already applied
      final existing = await _firestore
          .collection('hustles')
          .doc(hustleId)
          .collection('applications')
          .where('applicantId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        if (mounted) {
          SnackbarHelper.showError(context, 'You have already applied to this hustle');
        }
        return;
      }

      // Create application
      await _firestore
          .collection('hustles')
          .doc(hustleId)
          .collection('applications')
          .add({
        'applicantId': user.uid,
        'applicantEmail': user.email ?? '',
        'status': 'pending',
        'appliedAt': FieldValue.serverTimestamp(),
        'hustleTitle': hustleTitle,
      });

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Application submitted successfully!');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error applying: $e');
      }
    }
  }

}

class _HustleCard extends StatelessWidget {
  final String title;
  final String description;
  final double payAmount;
  final String payType;
  final String location;
  final String postedBy;
  final VoidCallback onTap;

  const _HustleCard({
    required this.title,
    required this.description,
    required this.payAmount,
    required this.payType,
    required this.location,
    required this.postedBy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pay = payAmount > 0
        ? '${CurrencyFormatter.formatBWP(payAmount, includeDecimals: false)}/$payType'
        : 'Negotiable';

    return AppCard(
      margin: EdgeInsets.only(bottom: AppDesignSystem.spaceM),
      onTap: onTap,
      padding: AppDesignSystem.paddingM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
          Row(
            children: [
              Icon(Icons.payments_outlined,
                  size: 16, color: colorScheme.tertiary),
              AppDesignSystem.horizontalSpace(AppDesignSystem.spaceXS),
              Text(
                pay,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.tertiary,
                ),
              ),
              AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
              Icon(Icons.location_on,
                  size: 16, color: colorScheme.onSurfaceVariant),
              AppDesignSystem.horizontalSpace(AppDesignSystem.spaceXS),
              Text(
                location,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
          Text(
            'Posted by: $postedBy',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
          StandardButton(
            label: 'Apply Now',
            onPressed: onTap,
            type: StandardButtonType.primary,
            icon: Icons.send,
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}
