import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:freelance_app/models/wallet_model.dart';
import 'package:freelance_app/services/notifications/notification_service.dart';
import 'package:uuid/uuid.dart';

class WalletService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  // --- Wallet Management ---

  /// Get a user's wallet. Creates one if it doesn't exist.
  Stream<WalletModel> getWalletStream(String userId) {
    return _db.collection('wallets').doc(userId).snapshots().map((doc) {
      if (!doc.exists) {
        // If wallet doesn't exist yet, we'll return a virtual one with the bonus
        // The actual creation happens in getWallet() or first interaction.
        return WalletModel(
            userId: userId, balance: 50.00, updatedAt: DateTime.now());
      }
      return WalletModel.fromMap(doc.data()!, userId);
    });
  }

  Future<WalletModel> getWallet(String userId) async {
    final walletRef = _db.collection('wallets').doc(userId);
    const double welcomeBonus = 50.00;

    return await _db.runTransaction((transaction) async {
      final doc = await transaction.get(walletRef);
      if (doc.exists) {
        return WalletModel.fromMap(doc.data()!, userId);
      }

      // Create default wallet with WELCOME BONUS
      final newWallet = WalletModel(
        userId: userId,
        balance: welcomeBonus,
        updatedAt: DateTime.now(),
      );

      transaction.set(walletRef, newWallet.toMap());

      // Record the Welcome Bonus transaction
      final txId = _uuid.v4();
      final tx = TransactionModel(
        id: txId,
        userId: userId,
        type: TransactionType.deposit,
        amount: welcomeBonus,
        status: TransactionStatus.completed,
        description: 'Welcome Bonus 🎉',
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
      );

      transaction.set(_db.collection('transactions').doc(txId), tx.toMap());

      return newWallet;
    });
  }

  // --- Transactions ---

  /// Request a Top Up (Deposit) via EFT. Uploads proof and creates pending transaction.
  Future<void> requestTopUp({
    required String userId,
    required double amount,
    required File proofOfPayment,
  }) async {
    // 1. Upload Image
    final String fileName =
        'pop_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('proof_of_payments').child(fileName);
    await ref.putFile(proofOfPayment);
    final String downloadUrl = await ref.getDownloadURL();

    // 2. Create Transaction Record
    final String txId = _uuid.v4();
    final tx = TransactionModel(
      id: txId,
      userId: userId,
      type: TransactionType.deposit,
      amount: amount,
      status: TransactionStatus.pending,
      description: 'EFT Deposit Request',
      proofOfPaymentUrl: downloadUrl,
      createdAt: DateTime.now(),
    );

    await _db.collection('transactions').doc(txId).set(tx.toMap());
  }

  /// Spend credits (Post Job / Apply). Checks balance strictly.
  Future<void> spendCredits({
    required String userId,
    required double amount,
    required TransactionType type,
    required String description,
  }) async {
    final walletRef = _db.collection('wallets').doc(userId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(walletRef);
      if (!snapshot.exists) {
        throw Exception("Wallet does not exist.");
      }

      final double currentBalance =
          (snapshot.data()?['balance'] ?? 0).toDouble();
      if (currentBalance < amount) {
        throw Exception("Insufficient funds.");
      }

      final double newBalance = currentBalance - amount;

      // Update Wallet
      transaction.update(walletRef, {
        'balance': newBalance,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create Transaction Record
      final String txId = _uuid.v4();
      final tx = TransactionModel(
        id: txId,
        userId: userId,
        type: type,
        amount: -amount, // Negative for spending
        status: TransactionStatus.completed,
        description: description,
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
      );

      transaction.set(_db.collection('transactions').doc(txId), tx.toMap());
    });
  }

  // --- Admin Actions ---

  Stream<List<TransactionModel>> getPendingTopUps() {
    return _db
        .collection('transactions')
        .where('status', isEqualTo: 'pending')
        .where('type', isEqualTo: 'deposit')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<TransactionModel>> getUserTransactions(String userId) {
    return _db
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> approveTopUp(String transactionId) async {
    final txRef = _db.collection('transactions').doc(transactionId);
    final notificationService = NotificationService();

    TransactionModel? txData;

    await _db.runTransaction((transaction) async {
      final txSnapshot = await transaction.get(txRef);
      if (!txSnapshot.exists) throw Exception("Transaction not found");

      txData = TransactionModel.fromMap(txSnapshot.data()!, transactionId);
      if (txData!.status != TransactionStatus.pending) {
        throw Exception("Transaction already processed");
      }

      final walletRef = _db.collection('wallets').doc(txData!.userId);

      // Credit Wallet
      transaction.set(
          walletRef,
          {
            'balance': FieldValue.increment(txData!.amount),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));

      // Update Transaction
      transaction.update(txRef, {
        'status': TransactionStatus.completed.name,
        'completedAt': FieldValue.serverTimestamp(),
      });
    });

    // Send Notification regarding success
    if (txData != null) {
      try {
        await notificationService.sendNotification(
          userId: txData!.userId,
          title: 'Top-up Approved',
          body:
              'Your wallet has been credited with BWP ${txData!.amount.toStringAsFixed(2)}.',
          type: 'wallet_credit',
          sendEmail: true,
        );
      } catch (e) {
        debugPrint('Notification error: $e');
      }
    }
  }

  Future<void> rejectTopUp(String transactionId) async {
    await _db.collection('transactions').doc(transactionId).update({
      'status': TransactionStatus.rejected.name,
      'completedAt': DateTime.now(),
    });
  }

  // --- Settings ---

  Stream<MonetizationSettingsModel> getSettingsStream() {
    return _db.collection('system').doc('monetization').snapshots().map((doc) {
      if (!doc.exists) return MonetizationSettingsModel();
      return MonetizationSettingsModel.fromMap(doc.data()!);
    });
  }

  Future<MonetizationSettingsModel> getSettings() async {
    final doc = await _db.collection('system').doc('monetization').get();
    if (!doc.exists) return MonetizationSettingsModel();
    return MonetizationSettingsModel.fromMap(doc.data()!);
  }

  Future<void> updateSettings(MonetizationSettingsModel settings) async {
    await _db.collection('system').doc('monetization').set(settings.toMap());
  }
}
