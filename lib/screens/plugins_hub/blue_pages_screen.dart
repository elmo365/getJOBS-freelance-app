import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freelance_app/models/wallet_model.dart';
import 'package:freelance_app/services/wallet_service.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/utils/colors.dart';
import 'package:freelance_app/utils/currency_formatter.dart';
import 'package:freelance_app/utils/layout.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/contact_action_row.dart';
import 'package:freelance_app/widgets/common/standard_button.dart';
import 'package:freelance_app/widgets/common/snackbar_helper.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';
import 'package:freelance_app/widgets/common/common_widgets.dart';

class BluePagesScreen extends StatefulWidget {
  const BluePagesScreen({super.key});

  @override
  State<BluePagesScreen> createState() => _BluePagesScreenState();
}

class _BluePagesScreenState extends State<BluePagesScreen> {
  final _walletService = WalletService();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Error handling helper methods
  Widget _buildErrorCard(String message) {
    return AppCard(
      padding: AppDesignSystem.paddingM,
      elevation: 2,
      child: Text(
        message,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Colors.red,
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return HintsWrapper(
      screenId: 'blue_pages',
      child: AppLayout.screenScaffold(
      context: context,
      appBar: AppAppBar(
        title: 'Blue Pages',
        variant: AppBarVariant.standard,
        actions: [
          // Only show add button for companies
          FutureBuilder<Map<String, dynamic>?>(
            future: _getCurrentUserData(),
            builder: (context, snapshot) {
              final isCompany = snapshot.data?['isCompany'] == true;
              if (!isCompany) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.add_business),
                onPressed: _addListing,
                tooltip: 'List Your Business',
              );
            },
          ),
        ],
      ),
      floatingActionButton: FutureBuilder<Map<String, dynamic>?>(
        future: _getCurrentUserData(),
        builder: (context, snapshot) {
          final isCompany = snapshot.data?['isCompany'] == true;
          if (!isCompany) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: _addListing,
            label: const Text('List Business'),
            icon: const Icon(Icons.add),
            backgroundColor: AppDesignSystem.brandBlue,
            foregroundColor: botsWhite, // White text/icon on blue background
          );
        },
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('blue_pages')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Unable to load businesses',
              message: 'Please check your connection and try again.',
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return EmptyState(
              icon: Icons.business_outlined,
              title: 'No businesses listed yet',
              message: 'Be the first to list your company in the Blue Pages directory!',
            );
          }

          return ListView.builder(
            padding: AppDesignSystem.paddingM,
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              
              // Validate critical fields
              final businessName = (data['businessName'] ?? data['name'] ?? '').toString().trim();
              if (businessName.isEmpty) {
                debugPrint('❌ ERROR: Missing business name for listing');
                return _buildErrorCard('Business listing incomplete (missing name)');
              }
              
              final description = (data['description'] ?? '').toString().trim();
              if (description.isEmpty) {
                debugPrint('⚠️ Warning: Missing description for business "$businessName"');
              }
              
              return _buildBusinessCard(data);
            },
          );
        },
      ),
      ),
    );
  }

  Widget _buildBusinessCard(Map<String, dynamic> data) {
    return AppCard(
      margin: AppDesignSystem.paddingOnly(bottom: AppDesignSystem.spaceM),
      padding: AppDesignSystem.paddingM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: AppDesignSystem.borderRadiusS,
                  image: data['logoUrl'] != null && data['logoUrl'].isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(data['logoUrl']),
                          fit: BoxFit.cover)
                      : null,
                ),
                child: data['logoUrl'] == null || data['logoUrl'].isEmpty
                    ? const Icon(Icons.business, color: Colors.blue)
                    : null,
              ),
              AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['companyName'] ?? 'No Name',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      data['category'] ?? 'General',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (data['isVerified'] == true)
                const Icon(Icons.verified, color: Colors.blue),
            ],
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
          Text(data['description'] ?? ''),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
          const Divider(),
          ContactActionRow(
            email: data['email'],
            phoneNumber: data['phone'],
            compact: true,
          ),
        ],
      ),
    );
  }

  Future<void> _addListing() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Please login to list your business.');
      }
      return;
    }

    // Role Check: Only Companies
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (!mounted) return;
    if (userDoc.data()?['isCompany'] != true) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Only Company accounts can list in Blue Pages.');
      }
      return;
    }

    // Monetization Check
    final settings = await _walletService.getSettings();
    double cost = settings.bluePageListingFee;

    // Check Company Monetization Toggle
    if (!settings.isCompanyMonetizationEnabled) {
      cost = 0;
    }

    // Global Discount
    if (settings.globalDiscountPercentage > 0 && cost > 0) {
      cost = cost - (cost * (settings.globalDiscountPercentage / 100));
    }
    if (cost < 0) cost = 0;

    // Show Confirmation + Form Dialog together
    // We will handle payment inside the dialog submit
    if (!mounted) return;
    _showListingForm(user.uid, cost);
  }

  void _showListingForm(String userId, double cost) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ListingFormDialog(userId: userId, cost: cost),
    );
  }
}

class _ListingFormDialog extends StatefulWidget {
  final String userId;
  final double cost;
  const _ListingFormDialog({required this.userId, required this.cost});

  @override
  State<_ListingFormDialog> createState() => _ListingFormDialogState();
}

class _ListingFormDialogState extends State<_ListingFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController(); // Auto-fill?
  final _categoryController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      try {
        // 1. Process Payment
        if (widget.cost > 0) {
          final walletService = WalletService();
          await walletService.spendCredits(
              userId: widget.userId,
              amount: widget.cost,
              type: TransactionType.bluePageFee,
              description: 'Blue Page Listing Fee');
        }

        // 2. Create Listing
        await FirebaseFirestore.instance.collection('blue_pages').add({
          'companyName': _nameController.text,
          'description': _descController.text,
          'phone': _phoneController.text,
          'email': _emailController.text,
          'category': _categoryController.text,
          'ownerId': widget.userId,
          'approvalStatus': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'isVerified': false,
        });

        if (mounted) {
          Navigator.pop(context);
          SnackbarHelper.showSuccess(context, 'Listing Created Successfully!');
        }
      } catch (e) {
        if (mounted) {
          SnackbarHelper.showError(context, 'Failed: $e');
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('List Your Business'),
          Text('Cost: ${CurrencyFormatter.formatBWP(widget.cost)}',
              style: const TextStyle(fontSize: 12, color: Colors.blue)),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Company Name'),
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                      labelText: 'Category (e.g. Plumbing)'),
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3),
              TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone),
              TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress),
            ],
          ),
        ),
      ),
      actions: [
        if (!_isSubmitting)
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
        StandardButton(
            label: _isSubmitting ? 'Processing...' : 'Pay & Save',
            onPressed: _isSubmitting ? () {} : _submit,
            type: StandardButtonType.primary),
      ],
    );
  }
}
