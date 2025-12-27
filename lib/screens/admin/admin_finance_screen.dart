import 'package:flutter/material.dart';
import 'package:freelance_app/models/wallet_model.dart';
import 'package:freelance_app/services/wallet_service.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/utils/currency_formatter.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/role_guard.dart';
import 'package:freelance_app/services/auth/app_user_role.dart';
import 'package:freelance_app/widgets/common/standard_button.dart';
import 'package:freelance_app/widgets/common/snackbar_helper.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';
import 'package:freelance_app/widgets/common/common_widgets.dart';
import 'package:freelance_app/widgets/common/standard_input.dart';
import 'package:freelance_app/utils/colors.dart';

class AdminFinanceScreen extends StatefulWidget {
  const AdminFinanceScreen({super.key});

  @override
  State<AdminFinanceScreen> createState() => _AdminFinanceScreenState();
}

class _AdminFinanceScreenState extends State<AdminFinanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _walletService = WalletService();

  // Settings Controllers
  final _companyJobCostController = TextEditingController();
  final _individualJobCostController = TextEditingController();
  final _appCostController = TextEditingController();
  final _bluePageCostController = TextEditingController();
  final _discountController = TextEditingController();
  final _bankController = TextEditingController();
  bool _isIndividualMonetizationEnabled = false;
  bool _isCompanyMonetizationEnabled = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _walletService.getSettings();
    setState(() {
      _isIndividualMonetizationEnabled =
          settings.isIndividualMonetizationEnabled;
      _isCompanyMonetizationEnabled = settings.isCompanyMonetizationEnabled;
      _companyJobCostController.text = settings.companyJobPostFee.toString();
      _individualJobCostController.text =
          settings.individualJobPostFee.toString();
      _appCostController.text = settings.applicationFee.toString();
      _bluePageCostController.text = settings.bluePageListingFee.toString();
      _discountController.text = settings.globalDiscountPercentage.toString();
      _bankController.text = settings.bankDetails;
    });
  }

  Future<void> _saveSettings() async {
    final settings = MonetizationSettingsModel(
      isIndividualMonetizationEnabled: _isIndividualMonetizationEnabled,
      isCompanyMonetizationEnabled: _isCompanyMonetizationEnabled,
      companyJobPostFee:
          double.tryParse(_companyJobCostController.text) ?? 50.0,
      individualJobPostFee:
          double.tryParse(_individualJobCostController.text) ?? 5.0,
      applicationFee: double.tryParse(_appCostController.text) ?? 1.0,
      bluePageListingFee:
          double.tryParse(_bluePageCostController.text) ?? 100.0,
      globalDiscountPercentage:
          double.tryParse(_discountController.text) ?? 0.0,
      bankDetails: _bankController.text,
    );
    await _walletService.updateSettings(settings);
    if (mounted) {
      SnackbarHelper.showSuccess(context, 'Settings Saved!');
    }
  }

  // ... _approve method unchanged ...

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allow: const {AppUserRole.admin},
      child: HintsWrapper(
        screenId: 'admin_finance',
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: botsSuperLightGrey,
          appBar: const AppAppBar(
            title: 'Finance & Monetization',
            variant: AppBarVariant.primary,
          ),
          body: Column(
            children: [
              // Tab bar styled to match Gig Space
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
                    controller: _tabController,
                    tabs: const [
                      Tab(
                        text: 'Top-Up Requests',
                        icon: Icon(Icons.account_balance_wallet),
                      ),
                      Tab(
                        text: 'Settings & Pricing',
                        icon: Icon(Icons.settings),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRequestsTab(),
                    _buildSettingsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _approveTransaction(TransactionModel tx) async {
    try {
      await _walletService.approveTopUp(tx.id);
      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Top-up Approved!');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error: $e');
      }
    }
  }

  Widget _buildRequestsTab() {
    return StreamBuilder<List<TransactionModel>>(
      stream: _walletService.getPendingTopUps(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.error_outline,
            title: 'Unable to load requests',
            message: 'Please check your connection and try again.',
          );
        }
        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return EmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: 'No pending requests',
            message: 'All top-up requests have been processed.',
          );
        }

        return ListView.builder(
          padding: AppDesignSystem.paddingM,
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final tx = requests[index];
            return AppCard(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(CurrencyFormatter.formatBWP(tx.amount)),
                subtitle: Text('By: ${tx.userId}\nRef: ${tx.id}'),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (tx.proofOfPaymentUrl != null)
                      IconButton(
                        icon: const Icon(Icons.image),
                        onPressed: () => _showImage(tx.proofOfPaymentUrl!),
                      ),
                    StandardButton(
                      label: 'Approve',
                      onPressed: () => _approveTransaction(tx),
                      type: StandardButtonType.success,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSettingsTab() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: AppDesignSystem.paddingL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Monetization toggles card
          AppCard(
            margin: const EdgeInsets.only(bottom: 16),
            variant: SurfaceVariant.elevated,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monetization Modes',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                Text(
                  'Control whether companies and individuals are charged for jobs, applications, and Blue Page listings.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Company Monetization'),
                  subtitle: const Text(
                    'Charge companies for Jobs & Blue Pages. (Default: ON)',
                  ),
                  value: _isCompanyMonetizationEnabled,
                  onChanged: (val) => setState(
                    () => _isCompanyMonetizationEnabled = val,
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Individual Monetization'),
                  subtitle: const Text(
                    'Charge individuals/seekers for Jobs & Applications. (Free Mode: OFF)',
                  ),
                  value: _isIndividualMonetizationEnabled,
                  onChanged: (val) => setState(
                    () => _isIndividualMonetizationEnabled = val,
                  ),
                ),
              ],
            ),
          ),

          // Base pricing card
          AppCard(
            margin: const EdgeInsets.only(bottom: 16),
            variant: SurfaceVariant.elevated,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Base Pricing (Credits / BWP)',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                StandardInput(
                  controller: _companyJobCostController,
                  label: 'Company Job Post Fee',
                  hint: 'Standard: 50.00',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.business,
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                StandardInput(
                  controller: _individualJobCostController,
                  label: 'Individual Job Post Fee',
                  hint: 'Standard: 5.00',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.person,
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                StandardInput(
                  controller: _appCostController,
                  label: 'Application Fee',
                  hint: 'Standard: 1.00',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.assignment_turned_in,
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                StandardInput(
                  controller: _bluePageCostController,
                  label: 'Blue Page Listing Fee',
                  hint: 'Standard: 100.00',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.bookmark,
                ),
              ],
            ),
          ),

          // Discounts card
          AppCard(
            margin: const EdgeInsets.only(bottom: 16),
            variant: SurfaceVariant.elevated,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Promotions & Discounts',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                StandardInput(
                  controller: _discountController,
                  label: 'Global Discount Percentage (0–100%)',
                  hint: 'e.g. 50 for half price',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.percent,
                ),
              ],
            ),
          ),

          // Bank details card
          AppCard(
            margin: const EdgeInsets.only(bottom: 16),
            variant: SurfaceVariant.elevated,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bank Details (for EFT)',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                StandardInput(
                  controller: _bankController,
                  label: 'Instructions',
                  hint: 'Bank Name, Account Number, Ref Code...',
                  maxLines: 4,
                  prefixIcon: Icons.account_balance,
                ),
              ],
            ),
          ),

          AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
          StandardButton(
            label: 'Save Settings',
            onPressed: _saveSettings,
            type: StandardButtonType.primary,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  void _showImage(String url) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => Scaffold(
                  appBar: AppAppBar(
                    title: 'Proof of Payment',
                    variant: AppBarVariant.standard,
                  ),
                  body: Center(child: Image.network(url)),
                )));
  }
}
