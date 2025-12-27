import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:freelance_app/models/wallet_model.dart';
import 'package:freelance_app/services/wallet_service.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/utils/currency_formatter.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/standard_button.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:intl/intl.dart';

class UserWalletScreen extends StatefulWidget {
  const UserWalletScreen({super.key});

  @override
  State<UserWalletScreen> createState() => _UserWalletScreenState();
}

class _UserWalletScreenState extends State<UserWalletScreen> {
  final _walletService = WalletService();
  final _authService = FirebaseAuthService();
  late String _userId;

  @override
  void initState() {
    super.initState();
    final user = _authService.getCurrentUser();
    if (user != null) {
      _userId = user.uid;
      // Ensure wallet exists - this will create it if it doesn't
      _ensureWalletExists();
    } else {
      // Handle guest/error
      Navigator.pop(context);
    }
  }

  /// Ensure wallet exists in Firestore - this helps prevent infinite loading
  Future<void> _ensureWalletExists() async {
    try {
      await _walletService.getWallet(_userId);
    } catch (e) {
      debugPrint('Error ensuring wallet exists: $e');
      // Continue anyway - stream will handle errors
    }
  }

  void _showTopUpDialog(MonetizationSettingsModel settings) {
    showDialog(
      context: context,
      builder: (context) => _TopUpDialog(settings: settings, userId: _userId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Critical for keyboard handling
      appBar: AppAppBar(
        title: 'My Wallet',
        variant: AppBarVariant.primary, // Blue background with white text
      ),
      body: HintsWrapper(
        screenId: 'wallet',
        child: StreamBuilder<WalletModel>(
        stream: _walletService.getWalletStream(_userId),
        builder: (context, snapshot) {
          // Handle connection state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: AppDesignSystem.paddingL,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                    Text(
                      'Error loading wallet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          
          // If no data but connection is active, still show loading briefly
          if (!snapshot.hasData) {
            // Create wallet if it doesn't exist
            _walletService.getWallet(_userId).then((wallet) {
              // Wallet created or retrieved, stream will update
            }).catchError((e) {
              debugPrint('Error creating wallet: $e');
            });
            return const Center(child: CircularProgressIndicator());
          }

          final wallet = snapshot.data!;
          return SingleChildScrollView(
            padding: AppDesignSystem.paddingM,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBalanceCard(wallet),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
                const Text('Transaction History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                _buildHistoryList(),
              ],
            ),
          );
        },
        ),
      ),
    );
  }

  Widget _buildBalanceCard(WalletModel wallet) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return AppCard(
      padding: AppDesignSystem.paddingL,
      child: Column(
        children: [
          Text(
            'Current Balance',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
          Text(
            CurrencyFormatter.formatBWP(wallet.balance),
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.primary, // Use theme primary color for better contrast
            ),
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
          FutureBuilder<MonetizationSettingsModel>(
            future: _walletService.getSettings(),
            builder: (context, snapshot) {
              final settings = snapshot.data;
              return StandardButton(
                label: 'Top Up Credits',
                icon: Icons.add_card,
                onPressed: settings == null ? () {} : () => _showTopUpDialog(settings),
                type: StandardButtonType.primary,
                fullWidth: true,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return StreamBuilder<List<TransactionModel>>(
      stream: _walletService.getUserTransactions(_userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text('Error: ${snapshot.error}');
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final txs = snapshot.data!;
        if (txs.isEmpty) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          return Padding(
            padding: AppDesignSystem.paddingXL,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 64,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                Text(
                  'No transactions yet',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                Text(
                  'Your transaction history will appear here once you make a deposit or payment',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: txs.length,
          separatorBuilder: (c, i) => const Divider(),
          itemBuilder: (context, index) {
            final tx = txs[index];
            final isCredit = tx.amount > 0;
            final theme = Theme.of(context);
            final colorScheme = theme.colorScheme;
            
            return ListTile(
              leading: Container(
                padding: AppDesignSystem.paddingS,
                decoration: BoxDecoration(
                  color: (isCredit ? colorScheme.primaryContainer : colorScheme.errorContainer)
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isCredit ? colorScheme.primary : colorScheme.error,
                  size: 20,
                ),
              ),
              title: Text(
                tx.description,
                style: theme.textTheme.bodyLarge,
              ),
              subtitle: Text(
                DateFormat.yMMMd().format(tx.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${isCredit ? "+" : ""}${CurrencyFormatter.formatBWP(tx.amount.abs())}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isCredit ? colorScheme.primary : colorScheme.error,
                    ),
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
                    ),
                    child: Text(
                      tx.status.name.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _TopUpDialog extends StatefulWidget {
  final MonetizationSettingsModel settings;
  final String userId;

  const _TopUpDialog({required this.settings, required this.userId});

  @override
  State<_TopUpDialog> createState() => _TopUpDialogState();
}

class _TopUpDialogState extends State<_TopUpDialog> {
  final _amountController = TextEditingController();
  File? _popFile;
  bool _isUploading = false;
  final _walletService = WalletService();

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() => _popFile = File(result.files.single.path!));
    }
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Amount')));
      return;
    }
    if (_popFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload Proof of Payment')));
      return;
    }

    setState(() => _isUploading = true);
    try {
      await _walletService.requestTopUp(
        userId: widget.userId,
        amount: amount,
        proofOfPayment: _popFile!,
      );
      if(mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Top-Up Requested! Admin will review.')));
      }
    } catch (e) {
      if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
         setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Top Up via EFT'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bank Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                  Text(widget.settings.bankDetails.isEmpty ? 'Contact Admin for details' : widget.settings.bankDetails),
                ],
              ),
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            TextField(
              controller: _amountController,
              scrollPadding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 80,
              ),
              decoration: const InputDecoration(labelText: 'Amount (BWP)', prefixText: 'BWP '),
              keyboardType: TextInputType.number,
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            InkWell(
              onTap: _pickFile,
              child: Container(
                padding: AppDesignSystem.paddingM,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: AppDesignSystem.borderRadiusS,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.upload_file),
                    AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
                    Expanded(child: Text(_popFile == null ? 'Upload Proof of Payment' : 'File Selected')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        StandardButton(label: 'Cancel', onPressed: () => Navigator.pop(context), type: StandardButtonType.text),
        if (_isUploading)
          const CircularProgressIndicator()
        else
          StandardButton(label: 'Submit Request', onPressed: _submit, type: StandardButtonType.primary),
      ],
    );
  }
}

