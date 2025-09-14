import 'package:flutter/material.dart';
import 'package:myapp/theme.dart';

class MessageInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback sendMessage;
  final VoidCallback handleAttachment;

  const MessageInputWidget({
    super.key,
    required this.controller,
    required this.sendMessage,
    required this.handleAttachment,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Attachment button
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.add, color: AppColors.textSecondary, size: 20),
                onPressed: handleAttachment,
              ),
            ),

            const SizedBox(width: 12),

            // Text input
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.textSecondary.withOpacity(0.2),
                  ),
                ),
                child: TextField(
                  controller: controller,
                  style: theme.textTheme.bodyLarge,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: "Type a message...",
                    hintStyle: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary.withOpacity(0.7),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => sendMessage(),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Send button
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
