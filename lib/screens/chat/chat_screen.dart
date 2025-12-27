import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:freelance_app/models/chat_model.dart';
import 'package:freelance_app/services/chat_service.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';
import 'package:freelance_app/widgets/common/common_widgets.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserName;
  final String otherUserId;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserName,
    required this.otherUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;
  final _service = ChatService();
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _markRead();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _markRead() {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      _service.markMessagesAsRead(widget.chatId, currentUser.uid);
    }
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    _service.sendMessage(
      chatId: widget.chatId,
      senderId: currentUser.uid,
      text: text,
      recipientId: widget.otherUserId,
    );
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Please Log In')));
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppAppBar(
        title: widget.otherUserName,
        variant: AppBarVariant.primary, // Blue background with white text
      ),
      body: HintsWrapper(
        screenId: 'chat',
        child: Column(
        children: [
          // Warning Banner
          Container(
            width: double.infinity,
            padding: AppDesignSystem.paddingS,
            color: Colors.yellow[100],
            child: Text(
              '⚠️ Keep payments on the platform to ensure safety and prevent scams.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.orange[900]),
            ),
          ),

          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _service.getMessages(widget.chatId),
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

                final messages = snapshot.data!;
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                        AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                        Text(
                          'No messages yet',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                        Text(
                          'Start the conversation!',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  reverse: true,
                  padding: AppDesignSystem.paddingM,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == currentUser.uid;
                    final showDateSeparator = index == 0 || 
                        !_isSameDay(messages[index - 1].timestamp, msg.timestamp);
                    
                    return Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        if (showDateSeparator)
                          Padding(
                            padding: AppDesignSystem.paddingVertical(
                                AppDesignSystem.spaceS),
                            child: Text(
                              _formatDate(msg.timestamp),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: AppDesignSystem.paddingVertical(
                                AppDesignSystem.spaceXS),
                            padding: AppDesignSystem.paddingSymmetric(
                                horizontal: AppDesignSystem.spaceS,
                                vertical: AppDesignSystem.spaceS),
                            constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.75),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? AppDesignSystem.primaryColor
                                  : Colors.grey[200],
                              borderRadius: AppDesignSystem.borderRadiusL,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (msg.imageUrl != null && msg.imageUrl!.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: AppDesignSystem.borderRadiusS,
                                    child: CachedNetworkImage(
                                      imageUrl: msg.imageUrl!,
                                      width: 200,
                                      height: 200,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                if (msg.text.isNotEmpty) ...[
                                  if (msg.imageUrl != null && msg.imageUrl!.isNotEmpty)
                                    AppDesignSystem.verticalSpace(
                                        AppDesignSystem.spaceS),
                                  Text(
                                    msg.text,
                                    style: TextStyle(
                                      color: isMe ? Colors.white : Colors.black87,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                                AppDesignSystem.verticalSpace(
                                    AppDesignSystem.spaceXS),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formatMessageTime(msg.timestamp),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isMe
                                            ? Colors.white70
                                            : Colors.grey[600],
                                      ),
                                    ),
                                    if (isMe) ...[
                                      AppDesignSystem.horizontalSpace(
                                          AppDesignSystem.spaceXS),
                                      Icon(
                                        msg.isRead ? Icons.done_all : Icons.done,
                                        size: 14,
                                        color: msg.isRead
                                            ? Colors.blue[300]
                                            : Colors.white70,
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Input Area
          Container(
            padding: AppDesignSystem.paddingS,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send,
                      color: AppDesignSystem.primaryColor),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);
    
    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }

  String _formatMessageTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }
}
