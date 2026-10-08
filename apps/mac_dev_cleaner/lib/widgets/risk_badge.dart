import 'package:flutter/material.dart';
import 'package:mac_dev_cleaner_core/mac_dev_cleaner_core.dart';

import '../theme/mdc_theme.dart';

class RiskBadge extends StatelessWidget {
  const RiskBadge({super.key, required this.risk});

  final RiskLevel risk;

  @override
  Widget build(BuildContext context) {
    final semantic = MdcSemanticColors.of(context);
    final (color, bg) = switch (risk) {
      RiskLevel.safe => (semantic.riskSafeFg, semantic.riskSafeBg),
      RiskLevel.conditional => (
        semantic.riskConditionalFg,
        semantic.riskConditionalBg,
      ),
      RiskLevel.protected => (
        semantic.riskProtectedFg,
        semantic.riskProtectedBg,
      ),
    };
    return Semantics(
      label: '${risk.label} risk',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(
          risk.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}
