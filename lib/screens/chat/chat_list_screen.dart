import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_app/models/chat_model.dart';
import 'package:freelance_app/services/chat_service.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/utils/layout.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';
import 'package:freelance_app/widgets/common/common_widgets.dart';
import 'package:freelance_app/screens/chat/chat_screen.dart';
import 'package:freelance_app/services/cache/firestore_cache_service.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Scaffold(body: Center(child: Text('Please Log In')));
    
    final service = ChatService();

    return HintsWrapper(
      screenId: 'chat_list',
      child: AppLayout.screenScaffold(
      context: context,
      appBar: AppAppBar(
        title: 'Messages',
        variant: AppBarVariant.standard,
      ),
      body: StreamBuilder<List<ChatModel>>(
        stream: service.getUserChats(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Unable to load messages',
              message: 'Please check your connection and try again.',
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final chats = snapshot.data!;
          if (chats.isEmpty) {
            return EmptyState(
              icon: Icons.message_outlined,
              title: 'No messages yet',
              message: 'Start a conversation by messaging someone from their profile.',
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              // Find other user ID
              final otherUserId = chat.participants.firstWhere((id) => id != currentUser.uid, orElse: () => 'Unknown');
              
              return _ChatListItem(chat: chat, otherUserId: otherUserId);
            },
          );
        },
      ),
      ),
    );
  }
}

class _ChatListItem extends StatelessWidget {
  final ChatModel chat;
  final String otherUserId;

  const _ChatListItem({required this.chat, required this.otherUserId});

  Future<Map<String, dynamic>> _fetchUser() async {
    try {
      final cacheService = FirestoreCacheService();
      
      // Try cache first (1 hour TTL for user profiles)
      Map<String, dynamic>? cachedUser = cacheService.getCachedDoc(
        collection: 'users',
        docId: otherUserId,
        ttl: Duration(hours: 1),
      );
      
      if (cachedUser != null) {
        return cachedUser;
      }

      // Cache miss, fetch from Firestore
      final doc = await FirebaseFirestore.instance.collection('users').doc(otherUserId).get();
      final userData = doc.data() ?? {};
      
      // Cache the user document
      if (userData.isNotEmpty) {
        cacheService.cacheDoc(
          collection: 'users',
          docId: otherUserId,
          data: userData,
        );
      }

      return userData;
    } catch (e) {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchUser(),
      builder: (context, snapshot) {
        final userData = snapshot.data ?? {};
        final name = userData['company_name'] ?? userData['name'] ?? 'User';
        // Basic fallback avatar logic
        
        final unreadCount = chat.unreadCount ?? 0;
        final userImage = userData['user_image'] as String? ?? userData['company_logo'] as String?;
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppDesignSystem.brandBlue.withValues(alpha: 0.1),
            backgroundImage: userImage != null && userImage.isNotEmpty
                ? NetworkImage(userImage)
                : null,
            child: userImage == null || userImage.isEmpty
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(color: AppDesignSystem.brandBlue),
                  )
                : null,
          ),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
            chat.lastMessage ?? 'No messages',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTime(chat.lastMessageTime),
                style: TextStyle(
                  fontSize: 12,
                  color: unreadCount > 0
                      ? AppDesignSystem.brandBlue
                      : Colors.grey[600],
                  fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (unreadCount > 0) ...[
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                Container(
                  padding: AppDesignSystem.paddingSymmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppDesignSystem.brandBlue,
                    borderRadius: AppDesignSystem.borderRadiusM,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  chatId: chat.id,
                  otherUserName: name,
                  otherUserId: otherUserId,
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    // Simple formatter
    final now = DateTime.now();
    if (now.day == time.day && now.month == time.month && now.year == time.year) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
    return '${time.day}/${time.month}';
  }
}
