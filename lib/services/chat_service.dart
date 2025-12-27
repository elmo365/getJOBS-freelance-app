import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:freelance_app/models/chat_model.dart';
import 'package:freelance_app/services/notifications/notification_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  Future<String> getOrCreateChat(String userId1, String userId2) async {
    final participants = [userId1, userId2]..sort();

    final existing = await _firestore
        .collection('chats')
        .where('participants', isEqualTo: participants)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }

    final doc = await _firestore.collection('chats').add({
      'participants': participants,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    String? imageUrl,
    String? recipientId, // Optimization: Pass if known
  }) async {
    final msgData = {
      'senderId': senderId,
      'text': text,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    };

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(msgData);

    // Update Chat Metadata
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    // Notification Logic
    try {
      String targetUserId = recipientId ?? '';

      // If we don't know the recipient, find them from the chat doc
      if (targetUserId.isEmpty) {
        final chatDoc = await _firestore.collection('chats').doc(chatId).get();
        final participants =
            List<String>.from(chatDoc.data()?['participants'] ?? []);
        targetUserId =
            participants.firstWhere((id) => id != senderId, orElse: () => '');
      }

      if (targetUserId.isNotEmpty) {
        await _notificationService.sendNotification(
          userId: targetUserId,
          title: 'New Message',
          body: text.length > 50 ? '${text.substring(0, 50)}...' : text,
          type: 'message',
          data: {'chatId': chatId},
          actionUrl: '/chat', // Deep link to chat inbox
        );
      }
    } catch (e) {
      debugPrint('Failed to send notification: $e');
    }
  }

  Future<void> markMessagesAsRead(String chatId, String userId) async {
    final messages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('senderId', isNotEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in messages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Stream<List<ChatModel>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final chats = <ChatModel>[];
      for (var doc in snapshot.docs) {
        final chatData = doc.data();
        // Calculate unread count for this user
        final unreadCount = await _getUnreadCount(doc.id, userId);
        chats.add(ChatModel.fromMap(doc.id, {
          ...chatData,
          'unreadCount': unreadCount,
        }));
      }
      return chats;
    });
  }

  Future<int> _getUnreadCount(String chatId, String userId) async {
    try {
      final unreadMessages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      return unreadMessages.docs.length;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }
}
