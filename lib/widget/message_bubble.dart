// // import 'package:flutter/material.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:myapp/theme.dart';
// // import 'package:myapp/widget/message_timeline_dialog.dart';
// // import 'package:myapp/widget/status_indicator.dart';

// // class MessageBubble extends StatelessWidget {
// //   final DocumentSnapshot doc;
// //   final bool isMe;
// //   final Timestamp? timestamp;

// //   const MessageBubble({
// //     super.key,
// //     required this.doc,
// //     required this.isMe,
// //     this.timestamp,
// //   });

// //   @override
// //   Widget build(BuildContext context) {
// //     final theme = Theme.of(context);
// //     final message = doc["text"];
// //     final status = doc.data().toString().contains('status')
// //         ? doc["status"]
// //         : "sent";
// //     final sentAt = doc.data().toString().contains('sentAt')
// //         ? doc["sentAt"] as Timestamp?
// //         : null;
// //     final deliveredAt = doc.data().toString().contains('deliveredAt')
// //         ? doc["deliveredAt"] as Timestamp?
// //         : null;
// //     final seenAt = doc.data().toString().contains('seenAt')
// //         ? doc["seenAt"] as Timestamp?
// //         : null;

// //     return GestureDetector(
// //       onTap: isMe
// //           ? () => showDialog(
// //               context: context,
// //               builder: (context) => MessageTimelineDialog(
// //                 sentAt: sentAt,
// //                 deliveredAt: deliveredAt,
// //                 seenAt: seenAt,
// //               ),
// //             )
// //           : null,
// //       onLongPress: isMe
// //           ? () => showDialog(
// //               context: context,
// //               builder: (context) => MessageTimelineDialog(
// //                 sentAt: sentAt,
// //                 deliveredAt: deliveredAt,
// //                 seenAt: seenAt,
// //               ),
// //             )
// //           : null,

// //       child: Container(
// //         margin: EdgeInsets.only(
// //           bottom: 12,
// //           left: isMe ? 48 : 0,
// //           right: isMe ? 0 : 48,
// //         ),
// //         child: Column(
// //           crossAxisAlignment: isMe
// //               ? CrossAxisAlignment.end
// //               : CrossAxisAlignment.start,
// //           children: [
// //             Container(
// //               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
// //               decoration: BoxDecoration(
// //                 color: isMe ? AppColors.primary : Colors.white,
// //                 borderRadius: BorderRadius.only(
// //                   topLeft: const Radius.circular(20),
// //                   topRight: const Radius.circular(20),
// //                   bottomLeft: Radius.circular(isMe ? 20 : 4),
// //                   bottomRight: Radius.circular(isMe ? 4 : 20),
// //                 ),
// //                 boxShadow: [
// //                   BoxShadow(
// //                     color: Colors.black.withOpacity(0.05),
// //                     blurRadius: 8,
// //                     offset: const Offset(0, 2),
// //                   ),
// //                 ],
// //               ),
// //               child: Text(
// //                 message,
// //                 style: theme.textTheme.bodyLarge?.copyWith(
// //                   color: isMe ? Colors.white : AppColors.textPrimary,
// //                   height: 1.4,
// //                 ),
// //               ),
// //             ),

// //             // Status indicators and timestamp
// //             Padding(
// //               padding: const EdgeInsets.only(top: 6, left: 8, right: 8),
// //               child: Row(
// //                 mainAxisSize: MainAxisSize.min,
// //                 children: [
// //                   if (timestamp != null)
// //                     Text(
// //                       _formatTime(timestamp!.toDate()),
// //                       style: theme.textTheme.labelSmall?.copyWith(
// //                         color: AppColors.textSecondary.withOpacity(0.7),
// //                         fontSize: 11,
// //                       ),
// //                     ),

// //                   if (isMe) ...[
// //                     const SizedBox(width: 8),
// //                     StatusIndicator(status: status),
// //                   ],
// //                 ],
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   String _formatTime(DateTime dateTime) {
// //     final now = DateTime.now();
// //     final difference = now.difference(dateTime);

// //     if (difference.inDays > 0) {
// //       return "${dateTime.day}/${dateTime.month}";
// //     } else if (difference.inHours > 0) {
// //       return "${difference.inHours}h ago";
// //     } else if (difference.inMinutes > 0) {
// //       return "${difference.inMinutes}m ago";
// //     } else {
// //       return "Just now";
// //     }
// //   }
// // }

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:myapp/theme.dart';
// import 'package:myapp/widget/message_timeline_dialog.dart';
// import 'package:myapp/widget/status_indicator.dart';
// import 'package:myapp/widget/message_delete_dialog.dart';

// class MessageBubble extends StatelessWidget {
//   final DocumentSnapshot doc;
//   final bool isMe;
//   final Timestamp? timestamp;
//   final String chatId;
//   final VoidCallback? onMessageDeleted;

//   const MessageBubble({
//     super.key,
//     required this.doc,
//     required this.isMe,
//     this.timestamp,
//     required this.chatId,
//     this.onMessageDeleted,
//   });

//   Future<void> _showDeleteOptions(BuildContext context) async {
//     HapticFeedback.mediumImpact();

//     final currentUser = FirebaseAuth.instance.currentUser;
//     if (currentUser == null || !isMe) return;

//     // Check if message can be deleted for everyone (within 1 hour)
//     final messageTime = timestamp?.toDate() ?? DateTime.now();
//     final canDeleteForEveryone =
//         DateTime.now().difference(messageTime).inHours < 1;

//     final result = await showDialog<String>(
//       context: context,
//       builder: (context) =>
//           MessageDeleteDialog(canDeleteForEveryone: canDeleteForEveryone),
//     );

//     if (result != null) {
//       await _deleteMessage(context, result);
//     }
//   }

//   Future<void> _deleteMessage(BuildContext context, String deleteType) async {
//     try {
//       final currentUser = FirebaseAuth.instance.currentUser;
//       if (currentUser == null) return;

//       final messageRef = FirebaseFirestore.instance
//           .collection("chats")
//           .doc(chatId)
//           .collection("messages")
//           .doc(doc.id);

//       if (deleteType == 'everyone') {
//         // Delete for everyone - update the message to show it's deleted
//         await messageRef.update({
//           'isDeleted': true,
//           'deletedBy': currentUser.uid,
//           'deletedAt': FieldValue.serverTimestamp(),
//           'originalText':
//               doc['text'], // Store original text for potential recovery
//           'text': 'This message was deleted',
//         });

//         // Update last message in chat if this was the last message
//         await _updateLastMessageIfNeeded();
//       } else if (deleteType == 'me') {
//         // Delete for me - add current user to deletedFor array
//         await messageRef.update({
//           'deletedFor': FieldValue.arrayUnion([currentUser.uid]),
//         });
//       }

//       if (onMessageDeleted != null) {
//         onMessageDeleted!();
//       }

//       // Show success message
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             deleteType == 'everyone'
//                 ? 'Message deleted for everyone'
//                 : 'Message deleted for you',
//           ),
//           backgroundColor: AppColors.success,
//           duration: const Duration(seconds: 2),
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to delete message: ${e.toString()}'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   Future<void> _updateLastMessageIfNeeded() async {
//     try {
//       // Get chat document
//       final chatDoc = await FirebaseFirestore.instance
//           .collection("chats")
//           .doc(chatId)
//           .get();

//       if (!chatDoc.exists) return;

//       final chatData = chatDoc.data() as Map<String, dynamic>;
//       final lastMessageTime = chatData['lastMessageTime'] as Timestamp?;

//       // Check if this message was the last message
//       if (lastMessageTime != null &&
//           timestamp != null &&
//           lastMessageTime.millisecondsSinceEpoch ==
//               timestamp!.millisecondsSinceEpoch) {
//         // Get the most recent non-deleted message
//         final recentMessages = await FirebaseFirestore.instance
//             .collection("chats")
//             .doc(chatId)
//             .collection("messages")
//             .where('isDeleted', isNotEqualTo: true)
//             .orderBy('createdAt', descending: true)
//             .limit(1)
//             .get();

//         if (recentMessages.docs.isNotEmpty) {
//           final latestMessage = recentMessages.docs.first;
//           await FirebaseFirestore.instance
//               .collection("chats")
//               .doc(chatId)
//               .update({
//                 'lastMessage': latestMessage['text'],
//                 'lastMessageTime': latestMessage['createdAt'],
//                 'lastMessageSenderId': latestMessage['senderId'],
//               });
//         } else {
//           // No messages left, clear last message
//           await FirebaseFirestore.instance
//               .collection("chats")
//               .doc(chatId)
//               .update({
//                 'lastMessage': '',
//                 'lastMessageTime': null,
//                 'lastMessageSenderId': null,
//               });
//         }
//       }
//     } catch (e) {
//       print('Error updating last message: $e');
//     }
//   }

//   Widget _buildDeletedMessage(BuildContext context) {
//     final theme = Theme.of(context);

//     return Container(
//       margin: EdgeInsets.only(
//         bottom: 12,
//         left: isMe ? 48 : 0,
//         right: isMe ? 0 : 48,
//       ),
//       child: Column(
//         crossAxisAlignment: isMe
//             ? CrossAxisAlignment.end
//             : CrossAxisAlignment.start,
//         children: [
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             decoration: BoxDecoration(
//               color: Colors.grey.withOpacity(0.1),
//               borderRadius: BorderRadius.only(
//                 topLeft: const Radius.circular(20),
//                 topRight: const Radius.circular(20),
//                 bottomLeft: Radius.circular(isMe ? 20 : 4),
//                 bottomRight: Radius.circular(isMe ? 4 : 20),
//               ),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(Icons.block, size: 16, color: AppColors.textSecondary),
//                 const SizedBox(width: 8),
//                 Text(
//                   isMe
//                       ? 'You deleted this message'
//                       : 'This message was deleted',
//                   style: theme.textTheme.bodyMedium?.copyWith(
//                     color: AppColors.textSecondary,
//                     fontStyle: FontStyle.italic,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           if (timestamp != null)
//             Padding(
//               padding: const EdgeInsets.only(top: 6, left: 8, right: 8),
//               child: Text(
//                 _formatTime(timestamp!.toDate()),
//                 style: theme.textTheme.labelSmall?.copyWith(
//                   color: AppColors.textSecondary.withOpacity(0.7),
//                   fontSize: 11,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final currentUser = FirebaseAuth.instance.currentUser;

//     // Check if message is deleted
//     final isDeleted = doc.data().toString().contains('isDeleted')
//         ? doc['isDeleted'] ?? false
//         : false;

//     // Check if message is deleted for current user
//     final deletedFor = doc.data().toString().contains('deletedFor')
//         ? List<String>.from(doc['deletedFor'] ?? [])
//         : <String>[];

//     final isDeletedForMe =
//         currentUser != null && deletedFor.contains(currentUser.uid);

//     // Don't show message if it's deleted for current user
//     if (isDeletedForMe) {
//       return const SizedBox.shrink();
//     }

//     // Show deleted message placeholder if deleted for everyone
//     if (isDeleted) {
//       return _buildDeletedMessage(context);
//     }

//     // Normal message
//     final message = doc["text"];
//     final status = doc.data().toString().contains('status')
//         ? doc["status"]
//         : "sent";
//     final sentAt = doc.data().toString().contains('sentAt')
//         ? doc["sentAt"] as Timestamp?
//         : null;
//     final deliveredAt = doc.data().toString().contains('deliveredAt')
//         ? doc["deliveredAt"] as Timestamp?
//         : null;
//     final seenAt = doc.data().toString().contains('seenAt')
//         ? doc["seenAt"] as Timestamp?
//         : null;

//     return GestureDetector(
//       onTap: isMe
//           ? () => showDialog(
//               context: context,
//               builder: (context) => MessageTimelineDialog(
//                 sentAt: sentAt,
//                 deliveredAt: deliveredAt,
//                 seenAt: seenAt,
//               ),
//             )
//           : null,
//       onLongPress: isMe ? () => _showDeleteOptions(context) : null,
//       child: Container(
//         margin: EdgeInsets.only(
//           bottom: 12,
//           left: isMe ? 48 : 0,
//           right: isMe ? 0 : 48,
//         ),
//         child: Column(
//           crossAxisAlignment: isMe
//               ? CrossAxisAlignment.end
//               : CrossAxisAlignment.start,
//           children: [
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//               decoration: BoxDecoration(
//                 color: isMe ? AppColors.primary : Colors.white,
//                 borderRadius: BorderRadius.only(
//                   topLeft: const Radius.circular(20),
//                   topRight: const Radius.circular(20),
//                   bottomLeft: Radius.circular(isMe ? 20 : 4),
//                   bottomRight: Radius.circular(isMe ? 4 : 20),
//                 ),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.05),
//                     blurRadius: 8,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: Text(
//                 message,
//                 style: theme.textTheme.bodyLarge?.copyWith(
//                   color: isMe ? Colors.white : AppColors.textPrimary,
//                   height: 1.4,
//                 ),
//               ),
//             ),

//             // Status indicators and timestamp
//             Padding(
//               padding: const EdgeInsets.only(top: 6, left: 8, right: 8),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   if (timestamp != null)
//                     Text(
//                       _formatTime(timestamp!.toDate()),
//                       style: theme.textTheme.labelSmall?.copyWith(
//                         color: AppColors.textSecondary.withOpacity(0.7),
//                         fontSize: 11,
//                       ),
//                     ),

//                   if (isMe) ...[
//                     const SizedBox(width: 8),
//                     StatusIndicator(status: status),
//                   ],
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _formatTime(DateTime dateTime) {
//     final now = DateTime.now();
//     final difference = now.difference(dateTime);

//     if (difference.inDays > 0) {
//       return "${dateTime.day}/${dateTime.month}";
//     } else if (difference.inHours > 0) {
//       return "${difference.inHours}h ago";
//     } else if (difference.inMinutes > 0) {
//       return "${difference.inMinutes}m ago";
//     } else {
//       return "Just now";
//     }
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/theme.dart';
import 'package:myapp/widget/message_action_dialog.dart';
import 'package:myapp/widget/status_indicator.dart';

class MessageBubble extends StatelessWidget {
  final DocumentSnapshot doc;
  final bool isMe;
  final Timestamp? timestamp;
  final String chatId;
  final VoidCallback? onMessageDeleted;
  final Function(String)? onReplyMessage;
  final Function(String, String)? onStarMessage;

  const MessageBubble({
    super.key,
    required this.doc,
    required this.isMe,
    this.timestamp,
    required this.chatId,
    this.onMessageDeleted,
    this.onReplyMessage,
    this.onStarMessage,
  });

  Future<void> _showMessageActions(BuildContext context) async {
    HapticFeedback.mediumImpact();

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Check if message can be deleted for everyone (within 1 hour)
    final messageTime = timestamp?.toDate() ?? DateTime.now();
    final canDeleteForEveryone =
        isMe && DateTime.now().difference(messageTime).inHours < 1;

    // Get message data
    final message = doc["text"];
    final isStarred = doc.data().toString().contains('isStarred')
        ? doc['isStarred'] ?? false
        : false;

    // Get status data for message info
    final sentAt = doc.data().toString().contains('sentAt')
        ? doc["sentAt"] as Timestamp?
        : timestamp;
    final deliveredAt = doc.data().toString().contains('deliveredAt')
        ? doc["deliveredAt"] as Timestamp?
        : null;
    final seenAt = doc.data().toString().contains('seenAt')
        ? doc["seenAt"] as Timestamp?
        : null;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => MessageActionDialog(
        messageText: message,
        canDeleteForEveryone: canDeleteForEveryone,
        isStarred: isStarred,
        sentAt: sentAt,
        deliveredAt: deliveredAt,
        seenAt: seenAt,
        showInfo: isMe, // Only show info for own messages
        messageId: doc.id,
        chatId: chatId,
      ),
    );

    if (result != null && context.mounted) {
      await _handleAction(context, result, message);
    }
  }

  Future<void> _handleAction(
    BuildContext context,
    String action,
    String messageText,
  ) async {
    switch (action) {
      case 'reply':
        if (onReplyMessage != null) {
          onReplyMessage!(messageText);
        }
        break;
      case 'copy':
        // Already handled in dialog
        break;
      case 'star':
        await _toggleStarMessage(context);
        break;
      case 'delete_me':
        await _deleteMessage(context, 'me');
        break;
      case 'delete_everyone':
        await _deleteMessage(context, 'everyone');
        break;
    }
  }

  Future<void> _toggleStarMessage(BuildContext context) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final messageRef = FirebaseFirestore.instance
          .collection("chats")
          .doc(chatId)
          .collection("messages")
          .doc(doc.id);

      final currentIsStarred = doc.data().toString().contains('isStarred')
          ? doc['isStarred'] ?? false
          : false;

      await messageRef.update({
        'isStarred': !currentIsStarred,
        'starredBy': !currentIsStarred ? currentUser.uid : FieldValue.delete(),
        'starredAt': !currentIsStarred
            ? FieldValue.serverTimestamp()
            : FieldValue.delete(),
      });

      if (onStarMessage != null) {
        onStarMessage!(doc.id, !currentIsStarred ? 'starred' : 'unstarred');
      }
    } catch (e) {

    }
  }

  Future<void> _deleteMessage(BuildContext context, String deleteType) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final messageRef = FirebaseFirestore.instance
          .collection("chats")
          .doc(chatId)
          .collection("messages")
          .doc(doc.id);

      if (deleteType == 'everyone') {
        // Delete for everyone - update the message to show it's deleted
        await messageRef.update({
          'isDeleted': true,
          'deletedBy': currentUser.uid,
          'deletedAt': FieldValue.serverTimestamp(),
          'originalText':
              doc['text'], // Store original text for potential recovery
          'text': 'This message was deleted',
        });

        // Update last message in chat if this was the last message
        await _updateLastMessageIfNeeded();
      } else if (deleteType == 'me') {
        // Delete for me - add current user to deletedFor array
        await messageRef.update({
          'deletedFor': FieldValue.arrayUnion([currentUser.uid]),
        });
      }

      if (onMessageDeleted != null) {
        onMessageDeleted!();
      }
    } catch (e) {
 
    }
  }

  Future<void> _updateLastMessageIfNeeded() async {
    try {
      // Get chat document
      final chatDoc = await FirebaseFirestore.instance
          .collection("chats")
          .doc(chatId)
          .get();

      if (!chatDoc.exists) return;

      final chatData = chatDoc.data() as Map<String, dynamic>;
      final lastMessageTime = chatData['lastMessageTime'] as Timestamp?;

      // Check if this message was the last message
      if (lastMessageTime != null &&
          timestamp != null &&
          lastMessageTime.millisecondsSinceEpoch ==
              timestamp!.millisecondsSinceEpoch) {
        // Get the most recent non-deleted message
        final recentMessages = await FirebaseFirestore.instance
            .collection("chats")
            .doc(chatId)
            .collection("messages")
            .where('isDeleted', isNotEqualTo: true)
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();

        if (recentMessages.docs.isNotEmpty) {
          final latestMessage = recentMessages.docs.first;
          await FirebaseFirestore.instance
              .collection("chats")
              .doc(chatId)
              .update({
                'lastMessage': latestMessage['text'],
                'lastMessageTime': latestMessage['createdAt'],
                'lastMessageSenderId': latestMessage['senderId'],
              });
        } else {
          // No messages left, clear last message
          await FirebaseFirestore.instance
              .collection("chats")
              .doc(chatId)
              .update({
                'lastMessage': '',
                'lastMessageTime': null,
                'lastMessageSenderId': null,
              });
        }
      }
    } catch (e) {
      print('Error updating last message: $e');
    }
  }

  Widget _buildDeletedMessage(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.only(
        bottom: 12,
        left: isMe ? 48 : 0,
        right: isMe ? 0 : 48,
      ),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.block, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  isMe
                      ? 'You deleted this message'
                      : 'This message was deleted',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          if (timestamp != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 8, right: 8),
              child: Text(
                _formatTime(timestamp!.toDate()),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary.withOpacity(0.7),
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;

    // Check if message is deleted
    final isDeleted = doc.data().toString().contains('isDeleted')
        ? doc['isDeleted'] ?? false
        : false;

    // Check if message is deleted for current user
    final deletedFor = doc.data().toString().contains('deletedFor')
        ? List<String>.from(doc['deletedFor'] ?? [])
        : <String>[];

    final isDeletedForMe =
        currentUser != null && deletedFor.contains(currentUser.uid);

    // Don't show message if it's deleted for current user
    if (isDeletedForMe) {
      return const SizedBox.shrink();
    }

    // Show deleted message placeholder if deleted for everyone
    if (isDeleted) {
      return _buildDeletedMessage(context);
    }

    // Normal message
    final message = doc["text"];
    final status = doc.data().toString().contains('status')
        ? doc["status"]
        : "sent";

    final isStarred = doc.data().toString().contains('isStarred')
        ? doc['isStarred'] ?? false
        : false;

    return GestureDetector(
      onLongPress: () => _showMessageActions(context),
      child: Container(
        margin: EdgeInsets.only(
          bottom: 12,
          left: isMe ? 48 : 0,
          right: isMe ? 0 : 48,
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMe ? 20 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isMe ? Colors.white : AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
                // Star indicator
                if (isStarred)
                  Positioned(
                    top: 4,
                    right: isMe ? 4 : null,
                    left: isMe ? null : 4,
                    child: Icon(
                      Icons.star,
                      size: 12,
                      color: isMe
                          ? Colors.white.withOpacity(0.8)
                          : AppColors.warning,
                    ),
                  ),
              ],
            ),

            // Status indicators and timestamp
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 8, right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (timestamp != null)
                    Text(
                      _formatTime(timestamp!.toDate()),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),

                  if (isMe) ...[
                    const SizedBox(width: 8),
                    StatusIndicator(status: status),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return "${dateTime.day}/${dateTime.month}";
    } else if (difference.inHours > 0) {
      return "${difference.inHours}h ago";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes}m ago";
    } else {
      return "Just now";
    }
  }
}
