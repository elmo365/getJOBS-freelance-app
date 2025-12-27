import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a User's Wallet containing their credit balance.
class WalletModel {
  final String userId;
  final double balance;
  final DateTime updatedAt;

  WalletModel({
    required this.userId,
    required this.balance,
    required this.updatedAt,
  });

  factory WalletModel.fromMap(Map<String, dynamic> map, String userId) {
    return WalletModel(
      userId: userId,
      balance: (map['balance'] ?? 0).toDouble(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'balance': balance,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

/// Represents a financial transaction (Credit or Debit).
class TransactionModel {
  final String id;
  final String userId;
  final TransactionType type;
  final double amount; // Positive for deposit, Negative for spend
  final TransactionStatus status;
  final String description;
  final String? proofOfPaymentUrl; // For manual EFT verification
  final DateTime createdAt;
  final DateTime? completedAt;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.status,
    required this.description,
    this.proofOfPaymentUrl,
    required this.createdAt,
    this.completedAt,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return TransactionModel(
      id: id,
      userId: map['userId'] ?? '',
      type: TransactionType.values.firstWhere((e) => e.name == map['type'],
          orElse: () => TransactionType.unknown),
      amount: (map['amount'] ?? 0).toDouble(),
      status: TransactionStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => TransactionStatus.pending),
      description: map['description'] ?? '',
      proofOfPaymentUrl: map['proofOfPaymentUrl'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.name,
      'amount': amount,
      'status': status.name,
      'description': description,
      'proofOfPaymentUrl': proofOfPaymentUrl,
      'createdAt': createdAt, // Use serverTimestamp when writing if new
      'completedAt': completedAt,
    };
  }
}

enum TransactionType {
  deposit, // User adding money (EFT)
  withdrawal, // Cash out (future)
  jobFee, // Cost to post a job
  applicationFee, // Cost to apply
  bluePageFee, // Cost to list in Blue Pages
  adminAdjustment, // Admin manual credit/debit
  unknown,
}

enum TransactionStatus {
  pending,
  completed,
  rejected,
}

/// Global settings for Monetization controlled by Admin.
/// Global settings for Monetization controlled by Admin.
/// Global settings for Monetization controlled by Admin.
class MonetizationSettingsModel {
  final bool
      isIndividualMonetizationEnabled; // For Job Seekers & Individual Employers
  final bool
      isCompanyMonetizationEnabled; // For Company Employers (Default: True)
  final double companyJobPostFee; // Standard: P50
  final double individualJobPostFee; // Standard: P5
  final double applicationFee; // Standard: P1
  final double bluePageListingFee; // Standard: P100 (Business Directory)
  final double globalDiscountPercentage; // 0-100%
  final String bankDetails;

  // Deprecated getters for backward compatibility
  bool get isMonetizationEnabled => isIndividualMonetizationEnabled;

  MonetizationSettingsModel({
    this.isIndividualMonetizationEnabled = false,
    this.isCompanyMonetizationEnabled = true,
    this.companyJobPostFee = 50.0,
    this.individualJobPostFee = 5.0,
    this.applicationFee = 1.0,
    this.bluePageListingFee = 100.0,
    this.globalDiscountPercentage = 0.0,
    this.bankDetails = '',
  });

  factory MonetizationSettingsModel.fromMap(Map<String, dynamic> map) {
    return MonetizationSettingsModel(
      isIndividualMonetizationEnabled: map['isIndividualMonetizationEnabled'] ??
          map['isMonetizationEnabled'] ??
          false,
      isCompanyMonetizationEnabled: map['isCompanyMonetizationEnabled'] ?? true,
      companyJobPostFee:
          (map['companyJobPostFee'] ?? map['costPerJobPost'] ?? 50.0)
              .toDouble(),
      individualJobPostFee: (map['individualJobPostFee'] ?? 5.0).toDouble(),
      applicationFee:
          (map['applicationFee'] ?? map['costPerApplication'] ?? 1.0)
              .toDouble(),
      bluePageListingFee: (map['bluePageListingFee'] ?? 100.0).toDouble(),
      globalDiscountPercentage:
          (map['globalDiscountPercentage'] ?? 0.0).toDouble(),
      bankDetails: map['bankDetails'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isIndividualMonetizationEnabled': isIndividualMonetizationEnabled,
      'isCompanyMonetizationEnabled': isCompanyMonetizationEnabled,
      // Keep old key for compatibility
      'isMonetizationEnabled': isIndividualMonetizationEnabled,
      'companyJobPostFee': companyJobPostFee,
      'individualJobPostFee': individualJobPostFee,
      'applicationFee': applicationFee,
      'bluePageListingFee': bluePageListingFee,
      'globalDiscountPercentage': globalDiscountPercentage,
      'bankDetails': bankDetails,
    };
  }
}
