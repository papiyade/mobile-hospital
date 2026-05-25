import 'package:flutter/material.dart';

class TimelineStepWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool done;

  const TimelineStepWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: done ? Colors.green.withOpacity(0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: done ? Colors.green : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: done ? Colors.green : Colors.grey),
          const SizedBox(width: 10),
          Text(title),
        ],
      ),
    );
  }
}