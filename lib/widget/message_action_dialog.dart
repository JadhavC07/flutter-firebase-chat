import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/theme.dart';
import 'time_line_item.dart';

class MessageActionDialog extends StatefulWidget {
  final String messageText;
  final bool canDeleteForEveryone;
  final bool isStarred;
  final Timestamp? sentAt;
  final Timestamp? deliveredAt;
  final Timestamp? seenAt;
  final bool showInfo;
  final String messageId;
  final String chatId;

  const MessageActionDialog({
    super.key,
    required this.messageText,
    required this.canDeleteForEveryone,
    this.isStarred = false,
    this.sentAt,
    this.deliveredAt,
    this.seenAt,
    this.showInfo = true,
    required this.messageId,
    required this.chatId,
  });

  @override
  State<MessageActionDialog> createState() => _MessageActionDialogState();
}

class _MessageActionDialogState extends State<MessageActionDialog>
    with TickerProviderStateMixin {
  bool _showDeleteOptions = false;
  bool _showMessageInfo = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToView(VoidCallback setState) {
    _animationController.reset();
    setState();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _showDeleteOptions
                  ? _buildDeleteOptions()
                  : _showMessageInfo
                  ? _buildMessageInfo()
                  : _buildMainActions(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            border: Border(
              bottom: BorderSide(
                color: AppColors.borderColor.withOpacity(0.5),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Message Actions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.borderColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  widget.messageText.length > 60
                      ? '${widget.messageText.substring(0, 60)}...'
                      : widget.messageText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              if (widget.showInfo)
                _buildActionItem(
                  context: context,
                  icon: Icons.info_outline,
                  title: 'Message info',
                  subtitle: 'View delivery status',
                  onTap: () => _navigateToView(() {
                    setState(() {
                      _showMessageInfo = true;
                    });
                  }),
                ),

              _buildActionItem(
                context: context,
                icon: Icons.reply_rounded,
                title: 'Reply',
                subtitle: 'Reply to this message',
                onTap: () => Navigator.of(context).pop('reply'),
              ),

              _buildActionItem(
                context: context,
                icon: Icons.copy_rounded,
                title: 'Copy',
                subtitle: 'Copy to clipboard',
                onTap: () async {
                  await Clipboard.setData(
                    ClipboardData(text: widget.messageText),
                  );
                  Navigator.of(context).pop('copy');
                },
              ),

              _buildActionItem(
                context: context,
                icon: widget.isStarred
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                title: widget.isStarred ? 'Unstar' : 'Star',
                subtitle: widget.isStarred
                    ? 'Remove from starred'
                    : 'Add to starred',
                onTap: () => Navigator.of(context).pop('star'),
                iconColor: widget.isStarred ? AppColors.warning : null,
              ),

              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                height: 1,
                color: AppColors.borderColor.withOpacity(0.3),
              ),

              _buildActionItem(
                context: context,
                icon: Icons.delete_outline_rounded,
                title: 'Delete',
                subtitle: 'Delete this message',
                onTap: () => _navigateToView(() {
                  setState(() {
                    _showDeleteOptions = true;
                  });
                }),
                textColor: AppColors.secondary,
                iconColor: AppColors.secondary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteOptions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 24, 16),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.05),
            border: Border(
              bottom: BorderSide(
                color: AppColors.borderColor.withOpacity(0.5),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _navigateToView(() {
                    setState(() {
                      _showDeleteOptions = false;
                    });
                  }),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Delete Message',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildDeleteOption(
                context: context,
                icon: Icons.delete_outline_rounded,
                title: 'Delete for me',
                subtitle: 'This message will be deleted from this device only',
                onTap: () => Navigator.of(context).pop('delete_me'),
              ),

              if (widget.canDeleteForEveryone) ...[
                const SizedBox(height: 8),
                _buildDeleteOption(
                  context: context,
                  icon: Icons.delete_forever_outlined,
                  title: 'Delete for everyone',
                  subtitle: 'This message will be deleted for all participants',
                  onTap: () => Navigator.of(context).pop('delete_everyone'),
                  isDestructive: true,
                ),
              ],

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => _navigateToView(() {
                    setState(() {
                      _showDeleteOptions = false;
                    });
                  }),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: AppColors.borderColor.withOpacity(0.5),
                      ),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageInfo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 24, 16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            border: Border(
              bottom: BorderSide(
                color: AppColors.borderColor.withOpacity(0.5),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _navigateToView(() {
                    setState(() {
                      _showMessageInfo = false;
                    });
                  }),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Message Info',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Message text with better styling
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.borderColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  widget.messageText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Timeline section with enhanced styling
              Text(
                'Delivery Status',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.borderColor.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    TimelineItem(
                      label: "Sent",
                      timestamp: widget.sentAt,
                      color: AppColors.textSecondary,
                      icon: Icons.check_rounded,
                    ),
                    TimelineItem(
                      label: "Delivered",
                      timestamp: widget.deliveredAt,
                      color: AppColors.warning,
                      icon: Icons.done_all_rounded,
                    ),
                    TimelineItem(
                      label: "Seen",
                      timestamp: widget.seenAt,
                      color: AppColors.success,
                      icon: Icons.done_all_rounded,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: textColor ?? AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary.withOpacity(0.5),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDestructive
              ? AppColors.secondary.withOpacity(0.2)
              : AppColors.borderColor.withOpacity(0.3),
        ),
        color: isDestructive
            ? AppColors.secondary.withOpacity(0.05)
            : Colors.white,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? AppColors.secondary.withOpacity(0.1)
                        : AppColors.textSecondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isDestructive
                        ? AppColors.secondary
                        : AppColors.textSecondary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isDestructive
                              ? AppColors.secondary
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.3,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
