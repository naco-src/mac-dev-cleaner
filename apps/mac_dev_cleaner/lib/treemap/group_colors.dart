import 'package:flutter/material.dart';
import 'package:mac_dev_cleaner_core/mac_dev_cleaner_core.dart';

import '../theme/mdc_theme.dart';

Color groupColor(RuleGroup group) {
  return switch (group) {
    RuleGroup.xcode => const Color(0xFF5C6BC0),
    RuleGroup.android => const Color(0xFF43A047),
    RuleGroup.flutter => const Color(0xFF29B6F6),
    RuleGroup.node => const Color(0xFF8D6E63),
    RuleGroup.homebrew => const Color(0xFFFFB300),
    RuleGroup.ide => const Color(0xFFAB47BC),
    RuleGroup.browser => const Color(0xFFEF5350),
    RuleGroup.projects => const Color(0xFF78909C),
    RuleGroup.macos => const Color(0xFF546E7A),
  };
}

Color riskBorderColor(RiskLevel risk, BuildContext context) {
  final semantic = MdcSemanticColors.of(context);
  return switch (risk) {
    RiskLevel.safe => semantic.riskSafeFg,
    RiskLevel.conditional => semantic.riskConditionalFg,
    RiskLevel.protected => semantic.riskProtectedFg,
  };
}
