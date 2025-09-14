// import 'package:flutter/material.dart';
// import 'package:myapp/theme.dart';

// class MessageDeleteDialog extends StatelessWidget {
//   final bool canDeleteForEveryone;

//   const MessageDeleteDialog({super.key, required this.canDeleteForEveryone});

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return AlertDialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//       backgroundColor: theme.colorScheme.background,
//       titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
//       contentPadding: const EdgeInsets.only(bottom: 8),
//       title: Text(
//         "Delete Message?",
//         style: theme.textTheme.headlineMedium?.copyWith(
//           fontWeight: FontWeight.w600,
//           color: AppColors.textPrimary,
//         ),
//       ),
//       content: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           _buildDeleteOption(
//             context: context,
//             icon: Icons.delete_outline,
//             title: 'Delete for me',
//             subtitle: 'This message will be deleted from this device only',
//             onTap: () => Navigator.of(context).pop('me'),
//           ),

//           if (canDeleteForEveryone) ...[
//             const Divider(height: 1, color: AppColors.borderColor),
//             _buildDeleteOption(
//               context: context,
//               icon: Icons.delete_forever_outlined,
//               title: 'Delete for everyone',
//               subtitle: 'This message will be deleted for all participants',
//               onTap: () => Navigator.of(context).pop('everyone'),
//               isDestructive: true,
//             ),
//           ],

//           const Divider(height: 1, color: AppColors.borderColor),
//           _buildDeleteOption(
//             context: context,
//             icon: Icons.close,
//             title: 'Cancel',
//             onTap: () => Navigator.of(context).pop(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDeleteOption({
//     required BuildContext context,
//     required IconData icon,
//     required String title,
//     String? subtitle,
//     required VoidCallback onTap,
//     bool isDestructive = false,
//   }) {
//     final theme = Theme.of(context);

//     return InkWell(
//       borderRadius: BorderRadius.circular(12),
//       onTap: onTap,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
//         child: Row(
//           children: [
//             Icon(
//               icon,
//               color: isDestructive
//                   ? AppColors.secondary
//                   : AppColors.textSecondary,
//               size: 22,
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     style: theme.textTheme.bodyLarge?.copyWith(
//                       color: isDestructive
//                           ? AppColors.secondary
//                           : AppColors.textPrimary,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   if (subtitle != null) ...[
//                     const SizedBox(height: 4),
//                     Text(
//                       subtitle,
//                       style: theme.textTheme.bodyMedium?.copyWith(
//                         fontSize: 13,
//                         color: AppColors.textSecondary,
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
