import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participants; // User IDs
  final String? lastMessage;
  final DateTime lastMessageTime;
  final String? jobId; // Optional context: Linked to a job application
  final Map<String, dynamic>? extraData; // For names/photos cache if needed
  final int? unreadCount; // Number of unread messages for current user

  ChatModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    required this.lastMessageTime,
    this.jobId,
    this.extraData,
    this.unreadCount,
  });

  factory ChatModel.fromMap(String id, Map<String, dynamic> map) {
    return ChatModel(
      id: id,
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'],
      lastMessageTime: (map['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      jobId: map['jobId'],
      extraData: map['extraData'],
      unreadCount: map['unreadCount'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'jobId': jobId,
      'extraData': extraData,
      'unreadCount': unreadCount,
    };
  }
}

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final String? imageUrl;
  final String? fileUrl;
  final DateTime timestamp;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    this.imageUrl,
    this.fileUrl,
    required this.timestamp,
    this.isRead = false,
  });

  factory MessageModel.fromMap(String id, Map<String, dynamic> map) {
    return MessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      imageUrl: map['imageUrl'],
      fileUrl: map['fileUrl'],
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'imageUrl': imageUrl,
      'fileUrl': fileUrl,
      'timestamp': timestamp,
      'isRead': isRead,
    };
  }
}
