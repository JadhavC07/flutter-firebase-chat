import 'package:flutter/material.dart';
import 'package:myapp/theme.dart';

class StatusIndicator extends StatelessWidget {
  final String status;

  const StatusIndicator({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case "sent":
        return Icon(
          Icons.check,
          size: 14,
          color: AppColors.textSecondary.withOpacity(0.7),
        );
      case "delivered":
        return Icon(Icons.done_all, size: 14, color: AppColors.warning);
      case "seen":
        return Icon(Icons.done_all, size: 14, color: AppColors.success);
      default:
        return Icon(
          Icons.schedule,
          size: 14,
          color: AppColors.textSecondary.withOpacity(0.5),
        );
    }
  }
}
