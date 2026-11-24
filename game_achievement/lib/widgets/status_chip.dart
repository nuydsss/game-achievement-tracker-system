import 'package:flutter/material.dart';

import '../core/constants/firestore_paths.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});
  final String status;

  Color _color() {
    switch (status) {
      case GameStatus.playing:
        return Colors.blue;
      case GameStatus.completed:
        return Colors.green;
      case GameStatus.onHold:
        return Colors.orange;
      case GameStatus.dropped:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        GameStatus.label(status),
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
