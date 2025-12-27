import 'package:freelance_app/services/wallet_service.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';

/// Service to check monetization visibility based on admin settings
/// Hides wallet and monetization features when disabled
class MonetizationVisibilityService {
  static final MonetizationVisibilityService _instance =
      MonetizationVisibilityService._internal();
  factory MonetizationVisibilityService() => _instance;
  MonetizationVisibilityService._internal();

  final WalletService _walletService = WalletService();
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirebaseDatabaseService _dbService = FirebaseDatabaseService();

  /// Check if wallet should be visible for current user
  Future<bool> isWalletVisible() async {
    try {
      final user = _authService.getCurrentUser();
      if (user == null) return false;

      final userDoc = await _dbService.getUser(user.uid);
      if (userDoc == null) return false;

      final userData = userDoc.data() as Map<String, dynamic>? ?? {};
      final isCompany = userData['isCompany'] == true;

      final settings = await _walletService.getSettings();

      // Companies always see wallet if company monetization is enabled
      if (isCompany) {
        return settings.isCompanyMonetizationEnabled;
      }

      // Job seekers see wallet only if individual monetization is enabled
      return settings.isIndividualMonetizationEnabled;
    } catch (e) {
      // On error, hide wallet to be safe
      return false;
    }
  }

  /// Check if monetization features should be visible for current user
  /// This includes payment dialogs, pricing info, etc.
  Future<bool> isMonetizationVisible() async {
    return await isWalletVisible();
  }

  /// Check if monetization is enabled for a specific user type
  Future<bool> isMonetizationEnabledForUser({required bool isCompany}) async {
    try {
      final settings = await _walletService.getSettings();
      return isCompany
          ? settings.isCompanyMonetizationEnabled
          : settings.isIndividualMonetizationEnabled;
    } catch (e) {
      return false;
    }
  }

  /// Check if user can post jobs with monetization
  /// Returns true if monetization is disabled OR if user has sufficient balance
  Future<bool> canPostJobWithMonetization() async {
    try {
      final user = _authService.getCurrentUser();
      if (user == null) return false;

      final userDoc = await _dbService.getUser(user.uid);
      if (userDoc == null) return false;

      final userData = userDoc.data() as Map<String, dynamic>? ?? {};
      final isCompany = userData['isCompany'] == true;

      final settings = await _walletService.getSettings();
      final monetizationEnabled = isCompany
          ? settings.isCompanyMonetizationEnabled
          : settings.isIndividualMonetizationEnabled;

      // If monetization is disabled, posting is free
      if (!monetizationEnabled) return true;

      // If monetization is enabled, check balance
      final wallet = await _walletService.getWallet(user.uid);
      final baseCost = isCompany
          ? settings.companyJobPostFee
          : settings.individualJobPostFee;

      // Apply discount
      double discountAmount = 0.0;
      if (settings.globalDiscountPercentage > 0) {
        discountAmount = baseCost * (settings.globalDiscountPercentage / 100);
      }
      final finalCost = (baseCost - discountAmount).clamp(0.0, double.infinity);

      return wallet.balance >= finalCost;
    } catch (e) {
      return false;
    }
  }
}

