import 'package:flutter/material.dart';
import 'package:myapp/theme.dart';
import 'package:myapp/typing_indicator.dart';

class TypingIndicatorWidget extends StatelessWidget {
  const TypingIndicatorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Container with margin
          Container(
            margin: const EdgeInsets.only(right: 48),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "typing",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const TypingIndicator(
                    color: Colors.blue,
                    dotSize: 6,
                    spacing: 3,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
