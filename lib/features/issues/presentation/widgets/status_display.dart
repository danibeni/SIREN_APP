import 'package:flutter/material.dart';

class StatusDisplay extends StatelessWidget {
  final String statusName;
  final String? statusColorHex;

  const StatusDisplay({
    super.key,
    required this.statusName,
    this.statusColorHex,
  });

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(statusColorHex);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            statusName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) {
      return Colors.grey;
    }
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse(hex, radix: 16) + 0xFF000000);
    } catch (e) {
      return Colors.grey;
    }
  }
}
