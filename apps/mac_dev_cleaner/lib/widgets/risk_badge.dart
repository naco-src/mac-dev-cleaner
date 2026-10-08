import 'package:flutter/material.dart';
import 'package:mac_dev_cleaner_core/mac_dev_cleaner_core.dart';

class RiskBadge extends StatelessWidget {
  const RiskBadge({super.key, required this.risk});

  final RiskLevel risk;

  @override
  Widget build(BuildContext context) {
    final (color, bg) = switch (risk) {
      RiskLevel.safe => (Colors.green.shade800, Colors.green.shade50),
      RiskLevel.conditional => (Colors.orange.shade900, Colors.orange.shade50),
      RiskLevel.protected => (
        Colors.blueGrey.shade800,
        Colors.blueGrey.shade100,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        risk.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
