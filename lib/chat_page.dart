// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:myapp/theme.dart';
// import 'dart:async';
// import 'package:myapp/widget/message_bubble.dart';
// import 'package:myapp/widget/message_input.dart';
// import 'package:myapp/widget/typing_indicator_widget.dart';

// enum MessageStatus { sent, delivered, seen }

// class ChatPage extends StatefulWidget {
//   final String chatId;
//   final DocumentSnapshot otherUser;

//   const ChatPage({super.key, required this.chatId, required this.otherUser});

//   @override
//   State<ChatPage> createState() => _ChatPageState();
// }

// class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
//   final TextEditingController _controller = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   static const int _messagesLimit = 50;
//   bool _isChatVisible = true;

//   // Typing indicator variables
//   Timer? _typingTimer;
//   bool _isTyping = false;
//   bool _otherUserTyping = false;
//   StreamSubscription? _typingSubscription;
//   static const Duration _typingTimeout = Duration(seconds: 3);

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _updateUserPresence(true);
//     Future.delayed(const Duration(milliseconds: 500), () {
//       _markMessagesAsDelivered();
//       _markMessagesAsSeen();
//     });
//     _listenForStatusUpdates();
//     _setupTypingListener();
//     _setupTextControllerListener();
//   }

//   @override
//   void dispose() {
//     _updateUserPresence(false);
//     _stopTyping(); // Clear typing status when leaving
//     _typingTimer?.cancel();
//     _typingSubscription?.cancel();
//     WidgetsBinding.instance.removeObserver(this);
//     _controller.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }

//   // Setup text controller listener for typing detection
//   void _setupTextControllerListener() {
//     _controller.addListener(() {
//       final text = _controller.text;

//       if (text.isNotEmpty && !_isTyping) {
//         _startTyping();
//       } else if (text.isEmpty && _isTyping) {
//         _stopTyping();
//       } else if (text.isNotEmpty && _isTyping) {
//         _resetTypingTimer();
//       }
//     });
//   }

//   // Setup listener for other user's typing status
//   void _setupTypingListener() {
//     _typingSubscription = FirebaseFirestore.instance
//         .collection("chats")
//         .doc(widget.chatId)
//         .collection("typing")
//         .doc(widget.otherUser.id)
//         .snapshots()
//         .listen((snapshot) {
//           if (mounted && snapshot.exists) {
//             final data = snapshot.data() as Map<String, dynamic>;
//             final isTyping = data['isTyping'] ?? false;
//             final lastTypingTime = data['lastTypingTime'] as Timestamp?;

//             // Check if typing status is recent (within last 4 seconds to match timeout)
//             bool isRecentTyping = false;
//             if (lastTypingTime != null) {
//               final timeDiff = DateTime.now().difference(
//                 lastTypingTime.toDate(),
//               );
//               isRecentTyping = timeDiff.inSeconds < 4;
//             }

//             final shouldShowTyping = isTyping && isRecentTyping;

//             if (_otherUserTyping != shouldShowTyping) {
//               setState(() {
//                 _otherUserTyping = shouldShowTyping;
//               });
//             }
//           } else if (mounted) {
//             if (_otherUserTyping) {
//               setState(() {
//                 _otherUserTyping = false;
//               });
//             }
//           }
//         }, onError: (error) {});
//   }

//   // Start typing indicator
//   void _startTyping() {
//     if (_isTyping) return;

//     setState(() {
//       _isTyping = true;
//     });

//     _updateTypingStatus(true);
//     _resetTypingTimer();
//   }

//   // Stop typing indicator
//   void _stopTyping() {
//     if (!_isTyping) return;

//     setState(() {
//       _isTyping = false;
//     });

//     _updateTypingStatus(false);
//     _typingTimer?.cancel();
//   }

//   // Reset typing timer
//   void _resetTypingTimer() {
//     _typingTimer?.cancel();
//     _typingTimer = Timer(_typingTimeout, () {
//       if (_isTyping) {
//         _stopTyping();
//       }
//     });
//   }

//   // Update typing status in Firestore
//   Future<void> _updateTypingStatus(bool isTyping) async {
//     try {
//       final currentUser = FirebaseAuth.instance.currentUser;
//       if (currentUser == null) {
//         return;
//       }

//       await FirebaseFirestore.instance
//           .collection("chats")
//           .doc(widget.chatId)
//           .collection("typing")
//           .doc(currentUser.uid)
//           .set({
//             'isTyping': isTyping,
//             'lastTypingTime': FieldValue.serverTimestamp(),
//             'userId': currentUser.uid,
//           });
//     } catch (e) {}
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     switch (state) {
//       case AppLifecycleState.resumed:
//         _isChatVisible = true;
//         _updateUserPresence(true);
//         _markMessagesAsDelivered();
//         _markMessagesAsSeen();
//         break;
//       case AppLifecycleState.paused:
//         _isChatVisible = false;
//         _updateUserPresence(false);
//         _stopTyping(); // Stop typing when app is paused
//         break;
//       default:
//         break;
//     }
//   }

//   void _listenForStatusUpdates() {
//     final currentUser = FirebaseAuth.instance.currentUser;
//     if (currentUser == null) return;

//     // Listen for changes in other user's presence
//     FirebaseFirestore.instance
//         .collection("users")
//         .doc(widget.otherUser.id)
//         .snapshots()
//         .listen((snapshot) {
//           if (snapshot.exists) {
//             final userData = snapshot.data() as Map<String, dynamic>;
//             final isOnline = userData['isOnline'] ?? false;
//             final currentChatId = userData['currentChatId'];

//             // If other user comes online and enters this chat, mark messages as delivered/seen
//             if (isOnline && currentChatId == widget.chatId) {
//               _markMyUndeliveredMessages();
//             }
//           }
//         });
//   }

//   Future<void> _markMyUndeliveredMessages() async {
//     try {
//       final currentUser = FirebaseAuth.instance.currentUser;
//       if (currentUser == null) return;

//       final undeliveredMessages = await FirebaseFirestore.instance
//           .collection("chats")
//           .doc(widget.chatId)
//           .collection("messages")
//           .where("senderId", isEqualTo: currentUser.uid)
//           .where("status", isEqualTo: "sent")
//           .get();

//       if (undeliveredMessages.docs.isEmpty) return;

//       final batch = FirebaseFirestore.instance.batch();
//       final now = FieldValue.serverTimestamp();

//       for (var doc in undeliveredMessages.docs) {
//         batch.update(doc.reference, {
//           "deliveredAt": now,
//           "status": "delivered",
//         });
//       }

//       await batch.commit();

//       // Mark as seen after a delay
//       await Future.delayed(const Duration(milliseconds: 2000));

//       final deliveredMessages = await FirebaseFirestore.instance
//           .collection("chats")
//           .doc(widget.chatId)
//           .collection("messages")
//           .where("senderId", isEqualTo: currentUser.uid)
//           .where("status", isEqualTo: "delivered")
//           .get();

//       if (deliveredMessages.docs.isNotEmpty) {
//         final seenBatch = FirebaseFirestore.instance.batch();

//         for (var doc in deliveredMessages.docs) {
//           seenBatch.update(doc.reference, {"seenAt": now, "status": "seen"});
//         }

//         await seenBatch.commit();
//       }
//     } catch (e) {}
//   }

//   // Update user's online presence
//   void _updateUserPresence(bool isOnline) {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       FirebaseFirestore.instance
//           .collection("users")
//           .doc(user.uid)
//           .update({
//             "isOnline": isOnline,
//             "lastSeen": FieldValue.serverTimestamp(),
//             "currentChatId": isOnline ? widget.chatId : null,
//           })
//           .catchError((error) {});
//     }
//   }

//   // Mark messages as delivered when user opens chat
//   Future<void> _markMessagesAsDelivered() async {
//     try {
//       final currentUser = FirebaseAuth.instance.currentUser;
//       if (currentUser == null) return;

//       // First, get undelivered messages
//       final undeliveredMessages = await FirebaseFirestore.instance
//           .collection("chats")
//           .doc(widget.chatId)
//           .collection("messages")
//           .where("senderId", isNotEqualTo: currentUser.uid)
//           .where("status", isEqualTo: "sent")
//           .get();

//       if (undeliveredMessages.docs.isEmpty) return;

//       final batch = FirebaseFirestore.instance.batch();
//       final now = FieldValue.serverTimestamp();

//       for (var doc in undeliveredMessages.docs) {
//         batch.update(doc.reference, {
//           "deliveredAt": now,
//           "status": "delivered",
//         });
//       }

//       await batch.commit();
//     } catch (e) {}
//   }

//   // Mark messages as seen when chat is visible
//   Future<void> _markMessagesAsSeen() async {
//     if (!_isChatVisible) return;

//     try {
//       final currentUser = FirebaseAuth.instance.currentUser;
//       if (currentUser == null) return;

//       // Get messages that are sent or delivered but not seen
//       final unseenMessages = await FirebaseFirestore.instance
//           .collection("chats")
//           .doc(widget.chatId)
//           .collection("messages")
//           .where("senderId", isNotEqualTo: currentUser.uid)
//           .where("status", whereIn: ["sent", "delivered"])
//           .get();

//       if (unseenMessages.docs.isEmpty) return;

//       final batch = FirebaseFirestore.instance.batch();
//       final now = FieldValue.serverTimestamp();

//       for (var doc in unseenMessages.docs) {
//         final data = doc.data();

//         // Update to seen and add seenAt timestamp
//         batch.update(doc.reference, {
//           "seenAt": now,
//           "status": "seen",
//           // Also set deliveredAt if it doesn't exist
//           if (data['deliveredAt'] == null) "deliveredAt": now,
//         });
//       }

//       await batch.commit();
//     } catch (e) {}
//   }

//   Future<void> sendMessage() async {
//     final currentUser = FirebaseAuth.instance.currentUser!;
//     final messageText = _controller.text.trim();

//     if (messageText.isNotEmpty) {
//       // Stop typing indicator before sending
//       _stopTyping();

//       try {
//         // Add the message to messages collection with status tracking
//         await FirebaseFirestore.instance
//             .collection("chats")
//             .doc(widget.chatId)
//             .collection("messages")
//             .add({
//               "text": messageText,
//               "senderId": currentUser.uid,
//               "createdAt": FieldValue.serverTimestamp(),
//               "sentAt": FieldValue.serverTimestamp(),
//               "deliveredAt": null,
//               "seenAt": null,
//               "status": "sent",
//             });

//         // Update chat document with last message info
//         await FirebaseFirestore.instance
//             .collection("chats")
//             .doc(widget.chatId)
//             .update({
//               "lastMessage": messageText,
//               "lastMessageTime": FieldValue.serverTimestamp(),
//               "lastMessageSenderId": currentUser.uid,
//             });

//         _controller.clear();

//         // Auto scroll to bottom after sending message
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           if (_scrollController.hasClients) {
//             _scrollController.animateTo(
//               0,
//               duration: const Duration(milliseconds: 300),
//               curve: Curves.easeOut,
//             );
//           }
//         });

//         // Check if other user is currently in this chat and mark as delivered
//         _checkOtherUserPresenceAndUpdateStatus();
//       } catch (e) {
//         // Show error snackbar
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text("Failed to send message. Please try again."),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//       }
//     }
//   }

//   // Check if other user is online and in this chat, then update message status
//   Future<void> _checkOtherUserPresenceAndUpdateStatus() async {
//     try {
//       final currentUser = FirebaseAuth.instance.currentUser;
//       if (currentUser == null) return;

//       final otherUserDoc = await FirebaseFirestore.instance
//           .collection("users")
//           .doc(widget.otherUser.id)
//           .get();

//       if (!otherUserDoc.exists) return;

//       final userData = otherUserDoc.data() as Map<String, dynamic>;
//       final isOnline = userData['isOnline'] ?? false;
//       final currentChatId = userData['currentChatId'];

//       // Get the latest message sent by current user
//       final latestMessages = await FirebaseFirestore.instance
//           .collection("chats")
//           .doc(widget.chatId)
//           .collection("messages")
//           .where("senderId", isEqualTo: currentUser.uid)
//           .orderBy("createdAt", descending: true)
//           .limit(1)
//           .get();

//       if (latestMessages.docs.isEmpty) return;

//       final latestMessageDoc = latestMessages.docs.first;
//       final messageData = latestMessageDoc.data();

//       // If other user is online and in this chat
//       if (isOnline && currentChatId == widget.chatId) {
//         final now = FieldValue.serverTimestamp();

//         // Mark as delivered immediately if not already
//         if (messageData['status'] == 'sent') {
//           await Future.delayed(const Duration(milliseconds: 500));
//           await latestMessageDoc.reference.update({
//             "deliveredAt": now,
//             "status": "delivered",
//           });

//           // Then mark as seen after a delay
//           await Future.delayed(const Duration(milliseconds: 1500));
//           await latestMessageDoc.reference.update({
//             "seenAt": now,
//             "status": "seen",
//           });
//         } else if (messageData['status'] == 'delivered') {
//           // Just mark as seen
//           await Future.delayed(const Duration(milliseconds: 1000));
//           await latestMessageDoc.reference.update({
//             "seenAt": now,
//             "status": "seen",
//           });
//         }
//       }
//     } catch (e) {}
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentUser = FirebaseAuth.instance.currentUser!;
//     final theme = Theme.of(context);

//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.white,
//         surfaceTintColor: Colors.transparent,
//         leading: IconButton(
//           icon: Icon(
//             Icons.arrow_back_ios,
//             color: AppColors.textPrimary,
//             size: 20,
//           ),
//           onPressed: () {
//             _updateUserPresence(false);
//             _stopTyping(); // Clear typing when leaving
//             Navigator.pop(context);
//           },
//         ),
//         title: Row(
//           children: [
//             Container(
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 border: Border.all(
//                   color: AppColors.primary.withOpacity(0.2),
//                   width: 2,
//                 ),
//               ),
//               child: CircleAvatar(
//                 radius: 20,
//                 backgroundImage: NetworkImage(widget.otherUser["photoUrl"]),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     widget.otherUser["name"],
//                     style: theme.textTheme.headlineMedium?.copyWith(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   StreamBuilder<DocumentSnapshot>(
//                     stream: FirebaseFirestore.instance
//                         .collection("users")
//                         .doc(widget.otherUser.id)
//                         .snapshots(),
//                     builder: (context, snapshot) {
//                       if (!snapshot.hasData) {
//                         return Text(
//                           "Loading...",
//                           style: theme.textTheme.bodyMedium?.copyWith(
//                             color: AppColors.textSecondary,
//                             fontSize: 12,
//                           ),
//                         );
//                       }

//                       final userData =
//                           snapshot.data!.data() as Map<String, dynamic>?;
//                       final isOnline = userData?['isOnline'] ?? false;
//                       final lastSeen = userData?['lastSeen'] as Timestamp?;

//                       // Show typing if other user is typing, otherwise show online status
//                       String statusText;
//                       Color statusColor;

//                       if (_otherUserTyping) {
//                         statusText = "typing...";
//                         statusColor = AppColors.primary;
//                       } else if (isOnline) {
//                         statusText = "Online";
//                         statusColor = AppColors.success;
//                       } else if (lastSeen != null) {
//                         statusText =
//                             "Last seen ${_formatLastSeen(lastSeen.toDate())}";
//                         statusColor = AppColors.textSecondary;
//                       } else {
//                         statusText = "Offline";
//                         statusColor = AppColors.textSecondary;
//                       }

//                       return Text(
//                         statusText,
//                         style: theme.textTheme.bodyMedium?.copyWith(
//                           color: statusColor,
//                           fontSize: 12,
//                           fontStyle: _otherUserTyping
//                               ? FontStyle.italic
//                               : FontStyle.normal,
//                         ),
//                       );
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.videocam_outlined, color: AppColors.textSecondary),
//             onPressed: () {},
//           ),
//           IconButton(
//             icon: Icon(Icons.call_outlined, color: AppColors.textSecondary),
//             onPressed: () {},
//           ),
//           const SizedBox(width: 8),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Messages List
//           Expanded(
//             child: StreamBuilder(
//               stream: FirebaseFirestore.instance
//                   .collection("chats")
//                   .doc(widget.chatId)
//                   .collection("messages")
//                   .orderBy("createdAt", descending: true)
//                   .limit(_messagesLimit)
//                   .snapshots(),
//               builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
//                 if (!snapshot.hasData) {
//                   return Center(
//                     child: CircularProgressIndicator(
//                       color: AppColors.primary,
//                       strokeWidth: 2,
//                     ),
//                   );
//                 }

//                 if (snapshot.data!.docs.isEmpty) {
//                   return Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(
//                           Icons.chat_bubble_outline,
//                           size: 64,
//                           color: AppColors.textSecondary.withOpacity(0.5),
//                         ),
//                         const SizedBox(height: 16),
//                         Text(
//                           "Start your conversation",
//                           style: theme.textTheme.bodyLarge?.copyWith(
//                             color: AppColors.textSecondary,
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 }

//                 // Mark messages as seen when new messages arrive
//                 WidgetsBinding.instance.addPostFrameCallback((_) {
//                   if (_isChatVisible) {
//                     _markMessagesAsSeen();
//                   }
//                 });

//                 return Column(
//                   children: [
//                     Expanded(
//                       child: ListView.builder(
//                         controller: _scrollController,
//                         reverse: true,
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 16,
//                           vertical: 8,
//                         ),
//                         itemCount: snapshot.data!.docs.length,
//                         itemBuilder: (context, index) {
//                           final doc = snapshot.data!.docs[index];
//                           final isMe = doc["senderId"] == currentUser.uid;
//                           final timestamp = doc["createdAt"] as Timestamp?;

//                           return MessageBubble(
//                             doc: doc,
//                             isMe: isMe,
//                             timestamp: timestamp,
//                           );
//                         },
//                       ),
//                     ),
//                     // Typing indicator
//                     if (_otherUserTyping) TypingIndicatorWidget(),
//                   ],
//                 );
//               },
//             ),
//           ),

//           MessageInputWidget(
//             controller: _controller,
//             sendMessage: sendMessage,
//             handleAttachment: () {},
//           ),
//         ],
//       ),
//     );
//   }

//   String _formatLastSeen(DateTime dateTime) {
//     final now = DateTime.now();
//     final difference = now.difference(dateTime);

//     if (difference.inMinutes < 1) {
//       return "just now";
//     } else if (difference.inMinutes < 60) {
//       return "${difference.inMinutes}m ago";
//     } else if (difference.inHours < 24) {
//       return "${difference.inHours}h ago";
//     } else if (difference.inDays == 1) {
//       return "yesterday";
//     } else if (difference.inDays < 7) {
//       return "${difference.inDays}d ago";
//     } else {
//       return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
//     }
//   }
// }

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/theme.dart';
import 'dart:async';
import 'package:myapp/widget/message_bubble.dart';
import 'package:myapp/widget/message_input.dart';
import 'package:myapp/widget/typing_indicator_widget.dart';

enum MessageStatus { sent, delivered, seen }

class ChatPage extends StatefulWidget {
  final String chatId;
  final DocumentSnapshot otherUser;

  const ChatPage({super.key, required this.chatId, required this.otherUser});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  static const int _messagesLimit = 50;
  bool _isChatVisible = true;

  // Typing indicator variables
  Timer? _typingTimer;
  bool _isTyping = false;
  bool _otherUserTyping = false;
  StreamSubscription? _typingSubscription;
  static const Duration _typingTimeout = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateUserPresence(true);
    Future.delayed(const Duration(milliseconds: 500), () {
      _markMessagesAsDelivered();
      _markMessagesAsSeen();
    });
    _listenForStatusUpdates();
    _setupTypingListener();
    _setupTextControllerListener();
  }

  @override
  void dispose() {
    _updateUserPresence(false);
    _stopTyping(); // Clear typing status when leaving
    _typingTimer?.cancel();
    _typingSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Setup text controller listener for typing detection
  void _setupTextControllerListener() {
    _controller.addListener(() {
      final text = _controller.text;

      if (text.isNotEmpty && !_isTyping) {
        _startTyping();
      } else if (text.isEmpty && _isTyping) {
        _stopTyping();
      } else if (text.isNotEmpty && _isTyping) {
        _resetTypingTimer();
      }
    });
  }

  // Setup listener for other user's typing status
  void _setupTypingListener() {
    _typingSubscription = FirebaseFirestore.instance
        .collection("chats")
        .doc(widget.chatId)
        .collection("typing")
        .doc(widget.otherUser.id)
        .snapshots()
        .listen((snapshot) {
          if (mounted && snapshot.exists) {
            final data = snapshot.data() as Map<String, dynamic>;
            final isTyping = data['isTyping'] ?? false;
            final lastTypingTime = data['lastTypingTime'] as Timestamp?;

            // Check if typing status is recent (within last 4 seconds to match timeout)
            bool isRecentTyping = false;
            if (lastTypingTime != null) {
              final timeDiff = DateTime.now().difference(
                lastTypingTime.toDate(),
              );
              isRecentTyping = timeDiff.inSeconds < 4;
            }

            final shouldShowTyping = isTyping && isRecentTyping;

            if (_otherUserTyping != shouldShowTyping) {
              setState(() {
                _otherUserTyping = shouldShowTyping;
              });
            }
          } else if (mounted) {
            if (_otherUserTyping) {
              setState(() {
                _otherUserTyping = false;
              });
            }
          }
        }, onError: (error) {});
  }

  // Start typing indicator
  void _startTyping() {
    if (_isTyping) return;

    setState(() {
      _isTyping = true;
    });

    _updateTypingStatus(true);
    _resetTypingTimer();
  }

  // Stop typing indicator
  void _stopTyping() {
    if (!_isTyping) return;

    setState(() {
      _isTyping = false;
    });

    _updateTypingStatus(false);
    _typingTimer?.cancel();
  }

  // Reset typing timer
  void _resetTypingTimer() {
    _typingTimer?.cancel();
    _typingTimer = Timer(_typingTimeout, () {
      if (_isTyping) {
        _stopTyping();
      }
    });
  }

  // Update typing status in Firestore
  Future<void> _updateTypingStatus(bool isTyping) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return;
      }

      await FirebaseFirestore.instance
          .collection("chats")
          .doc(widget.chatId)
          .collection("typing")
          .doc(currentUser.uid)
          .set({
            'isTyping': isTyping,
            'lastTypingTime': FieldValue.serverTimestamp(),
            'userId': currentUser.uid,
          });
    } catch (e) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _isChatVisible = true;
        _updateUserPresence(true);
        _markMessagesAsDelivered();
        _markMessagesAsSeen();
        break;
      case AppLifecycleState.paused:
        _isChatVisible = false;
        _updateUserPresence(false);
        _stopTyping(); // Stop typing when app is paused
        break;
      default:
        break;
    }
  }

  void _listenForStatusUpdates() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Listen for changes in other user's presence
    FirebaseFirestore.instance
        .collection("users")
        .doc(widget.otherUser.id)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            final userData = snapshot.data() as Map<String, dynamic>;
            final isOnline = userData['isOnline'] ?? false;
            final currentChatId = userData['currentChatId'];

            // If other user comes online and enters this chat, mark messages as delivered/seen
            if (isOnline && currentChatId == widget.chatId) {
              _markMyUndeliveredMessages();
            }
          }
        });
  }

  Future<void> _markMyUndeliveredMessages() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final undeliveredMessages = await FirebaseFirestore.instance
          .collection("chats")
          .doc(widget.chatId)
          .collection("messages")
          .where("senderId", isEqualTo: currentUser.uid)
          .where("status", isEqualTo: "sent")
          .get();

      if (undeliveredMessages.docs.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();
      final now = FieldValue.serverTimestamp();

      for (var doc in undeliveredMessages.docs) {
        batch.update(doc.reference, {
          "deliveredAt": now,
          "status": "delivered",
        });
      }

      await batch.commit();

      // Mark as seen after a delay
      await Future.delayed(const Duration(milliseconds: 2000));

      final deliveredMessages = await FirebaseFirestore.instance
          .collection("chats")
          .doc(widget.chatId)
          .collection("messages")
          .where("senderId", isEqualTo: currentUser.uid)
          .where("status", isEqualTo: "delivered")
          .get();

      if (deliveredMessages.docs.isNotEmpty) {
        final seenBatch = FirebaseFirestore.instance.batch();

        for (var doc in deliveredMessages.docs) {
          seenBatch.update(doc.reference, {"seenAt": now, "status": "seen"});
        }

        await seenBatch.commit();
      }
    } catch (e) {}
  }

  // Update user's online presence
  void _updateUserPresence(bool isOnline) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .update({
            "isOnline": isOnline,
            "lastSeen": FieldValue.serverTimestamp(),
            "currentChatId": isOnline ? widget.chatId : null,
          })
          .catchError((error) {});
    }
  }

  // Mark messages as delivered when user opens chat
  Future<void> _markMessagesAsDelivered() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // First, get undelivered messages
      final undeliveredMessages = await FirebaseFirestore.instance
          .collection("chats")
          .doc(widget.chatId)
          .collection("messages")
          .where("senderId", isNotEqualTo: currentUser.uid)
          .where("status", isEqualTo: "sent")
          .get();

      if (undeliveredMessages.docs.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();
      final now = FieldValue.serverTimestamp();

      for (var doc in undeliveredMessages.docs) {
        batch.update(doc.reference, {
          "deliveredAt": now,
          "status": "delivered",
        });
      }

      await batch.commit();
    } catch (e) {}
  }

  // Mark messages as seen when chat is visible
  Future<void> _markMessagesAsSeen() async {
    if (!_isChatVisible) return;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Get messages that are sent or delivered but not seen, and not deleted for current user
      final unseenMessages = await FirebaseFirestore.instance
          .collection("chats")
          .doc(widget.chatId)
          .collection("messages")
          .where("senderId", isNotEqualTo: currentUser.uid)
          .where("status", whereIn: ["sent", "delivered"])
          .get();

      if (unseenMessages.docs.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();
      final now = FieldValue.serverTimestamp();

      for (var doc in unseenMessages.docs) {
        final data = doc.data();

        // Check if message is deleted for current user
        final deletedFor = data['deletedFor'] != null
            ? List<String>.from(data['deletedFor'])
            : <String>[];

        if (deletedFor.contains(currentUser.uid)) {
          continue; // Skip if deleted for current user
        }

        // Update to seen and add seenAt timestamp
        batch.update(doc.reference, {
          "seenAt": now,
          "status": "seen",
          // Also set deliveredAt if it doesn't exist
          if (data['deliveredAt'] == null) "deliveredAt": now,
        });
      }

      await batch.commit();
    } catch (e) {}
  }

  Future<void> sendMessage() async {
    final currentUser = FirebaseAuth.instance.currentUser!;
    final messageText = _controller.text.trim();

    if (messageText.isNotEmpty) {
      // Stop typing indicator before sending
      _stopTyping();

      try {
        // Add the message to messages collection with status tracking
        await FirebaseFirestore.instance
            .collection("chats")
            .doc(widget.chatId)
            .collection("messages")
            .add({
              "text": messageText,
              "senderId": currentUser.uid,
              "createdAt": FieldValue.serverTimestamp(),
              "sentAt": FieldValue.serverTimestamp(),
              "deliveredAt": null,
              "seenAt": null,
              "status": "sent",
              "isDeleted": false,
              "deletedFor": [],
            });

        // Update chat document with last message info
        await FirebaseFirestore.instance
            .collection("chats")
            .doc(widget.chatId)
            .update({
              "lastMessage": messageText,
              "lastMessageTime": FieldValue.serverTimestamp(),
              "lastMessageSenderId": currentUser.uid,
            });

        _controller.clear();

        // Auto scroll to bottom after sending message
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });

        // Check if other user is currently in this chat and mark as delivered
        _checkOtherUserPresenceAndUpdateStatus();
      } catch (e) {
        // Show error snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to send message. Please try again."),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Check if other user is online and in this chat, then update message status
  Future<void> _checkOtherUserPresenceAndUpdateStatus() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final otherUserDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.otherUser.id)
          .get();

      if (!otherUserDoc.exists) return;

      final userData = otherUserDoc.data() as Map<String, dynamic>;
      final isOnline = userData['isOnline'] ?? false;
      final currentChatId = userData['currentChatId'];

      // Get the latest message sent by current user
      final latestMessages = await FirebaseFirestore.instance
          .collection("chats")
          .doc(widget.chatId)
          .collection("messages")
          .where("senderId", isEqualTo: currentUser.uid)
          .orderBy("createdAt", descending: true)
          .limit(1)
          .get();

      if (latestMessages.docs.isEmpty) return;

      final latestMessageDoc = latestMessages.docs.first;
      final messageData = latestMessageDoc.data();

      // If other user is online and in this chat
      if (isOnline && currentChatId == widget.chatId) {
        final now = FieldValue.serverTimestamp();

        // Mark as delivered immediately if not already
        if (messageData['status'] == 'sent') {
          await Future.delayed(const Duration(milliseconds: 500));
          await latestMessageDoc.reference.update({
            "deliveredAt": now,
            "status": "delivered",
          });

          // Then mark as seen after a delay
          await Future.delayed(const Duration(milliseconds: 1500));
          await latestMessageDoc.reference.update({
            "seenAt": now,
            "status": "seen",
          });
        } else if (messageData['status'] == 'delivered') {
          // Just mark as seen
          await Future.delayed(const Duration(milliseconds: 1000));
          await latestMessageDoc.reference.update({
            "seenAt": now,
            "status": "seen",
          });
        }
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () {
            _updateUserPresence(false);
            _stopTyping(); // Clear typing when leaving
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(widget.otherUser["photoUrl"]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser["name"],
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("users")
                        .doc(widget.otherUser.id)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Text(
                          "Loading...",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        );
                      }

                      final userData =
                          snapshot.data!.data() as Map<String, dynamic>?;
                      final isOnline = userData?['isOnline'] ?? false;
                      final lastSeen = userData?['lastSeen'] as Timestamp?;

                      // Show typing if other user is typing, otherwise show online status
                      String statusText;
                      Color statusColor;

                      if (_otherUserTyping) {
                        statusText = "typing...";
                        statusColor = AppColors.primary;
                      } else if (isOnline) {
                        statusText = "Online";
                        statusColor = AppColors.success;
                      } else if (lastSeen != null) {
                        statusText =
                            "Last seen ${_formatLastSeen(lastSeen.toDate())}";
                        statusColor = AppColors.textSecondary;
                      } else {
                        statusText = "Offline";
                        statusColor = AppColors.textSecondary;
                      }

                      return Text(
                        statusText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: statusColor,
                          fontSize: 12,
                          fontStyle: _otherUserTyping
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.videocam_outlined, color: AppColors.textSecondary),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.call_outlined, color: AppColors.textSecondary),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("chats")
                  .doc(widget.chatId)
                  .collection("messages")
                  .orderBy("createdAt", descending: true)
                  .limit(_messagesLimit)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  );
                }

                if (snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: AppColors.textSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Start your conversation",
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Mark messages as seen when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_isChatVisible) {
                    _markMessagesAsSeen();
                  }
                });

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final doc = snapshot.data!.docs[index];
                          final isMe = doc["senderId"] == currentUser.uid;
                          final timestamp = doc["createdAt"] as Timestamp?;

                          return MessageBubble(
                            doc: doc,
                            isMe: isMe,
                            timestamp: timestamp,
                            chatId: widget.chatId,
                            onMessageDeleted: () {
                              // Refresh the view if needed
                              setState(() {});
                            },
                          );
                        },
                      ),
                    ),
                    // Typing indicator
                    if (_otherUserTyping) TypingIndicatorWidget(),
                  ],
                );
              },
            ),
          ),

          MessageInputWidget(
            controller: _controller,
            sendMessage: sendMessage,
            handleAttachment: () {},
          ),
        ],
      ),
    );
  }

  String _formatLastSeen(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return "just now";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes}m ago";
    } else if (difference.inHours < 24) {
      return "${difference.inHours}h ago";
    } else if (difference.inDays == 1) {
      return "yesterday";
    } else if (difference.inDays < 7) {
      return "${difference.inDays}d ago";
    } else {
      return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
    }
  }
}
