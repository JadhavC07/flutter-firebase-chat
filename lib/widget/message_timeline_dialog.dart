// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:myapp/theme.dart';
// import 'package:myapp/widget/time_line_item.dart';

// class MessageTimelineDialog extends StatelessWidget {
//   final Timestamp? sentAt;
//   final Timestamp? deliveredAt;
//   final Timestamp? seenAt;

//   const MessageTimelineDialog({
//     super.key,
//     this.sentAt,
//     this.deliveredAt,
//     this.seenAt,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       title: const Text(
//         "Message Timeline",
//         style: TextStyle(fontWeight: FontWeight.w600),
//       ),
//       content: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           TimelineItem(
//             label: "Sent",
//             timestamp: sentAt,
//             color: AppColors.textSecondary,
//             icon: Icons.check,
//           ),
//           TimelineItem(
//             label: "Delivered",
//             timestamp: deliveredAt,
//             color: AppColors.warning,
//             icon: Icons.done_all,
//           ),
//           TimelineItem(
//             label: "Seen",
//             timestamp: seenAt,
//             color: AppColors.success,
//             icon: Icons.done_all,
//           ),
//         ],
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.of(context).pop(),
//           child: Text("Close", style: TextStyle(color: AppColors.primary)),
//         ),
//       ],
//     );
//   }
// }
