import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TimelineItem extends StatelessWidget {
  final String label;
  final Timestamp? timestamp;
  final Color color;
  final IconData icon;

  const TimelineItem({
    super.key,
    required this.label,
    this.timestamp,
    required this.color,
    required this.icon,
  });

  String _formatDetailedTime(DateTime dateTime) {
    // final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final displayHour = dateTime.hour == 0
        ? 12
        : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);

    return "${displayHour.toString().padLeft(2, '0')}:$minute $period";
  }

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = timestamp != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isCompleted ? color : Colors.grey.withOpacity(0.3),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isCompleted
                    ? Colors.black
                    : Colors.grey.withOpacity(0.7),
              ),
            ),
          ),
          Text(
            isCompleted ? _formatDetailedTime(timestamp!.toDate()) : "Pending",
            style: TextStyle(fontSize: 12, color: Colors.grey.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}
