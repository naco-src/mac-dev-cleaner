import 'package:flutter/material.dart';
import 'package:mac_dev_cleaner_core/mac_dev_cleaner_core.dart';

import '../treemap/group_colors.dart';

class TreemapTile extends StatelessWidget {
  const TreemapTile({
    super.key,
    required this.rect,
    required this.label,
    required this.sizeBytes,
    required this.fillColor,
    this.risk,
    required this.selected,
    required this.onTap,
    this.tooltipLines,
  });

  final Rect rect;
  final String label;
  final int sizeBytes;
  final Color fillColor;
  final RiskLevel? risk;
  final bool selected;
  final VoidCallback onTap;
  final List<String>? tooltipLines;

  @override
  Widget build(BuildContext context) {
    final showLabel = rect.width > 56 && rect.height > 36;
    final scheme = Theme.of(context).colorScheme;
    final borderColor = risk != null
        ? riskBorderColor(risk!, context)
        : scheme.outline.withValues(alpha: 0.5);
    final borderWidth = selected ? 3.0 : 1.0;

    final child = Material(
      color: fillColor.withValues(alpha: 0.85),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : borderColor,
              width: borderWidth,
            ),
          ),
          padding: const EdgeInsets.all(4),
          alignment: Alignment.topLeft,
          child: showLabel
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 2)],
                      ),
                    ),
                    Text(
                      formatBytes(sizeBytes),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 2)],
                      ),
                    ),
                  ],
                )
              : null,
        ),
      ),
    );

    final positioned = Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: child,
    );

    if (tooltipLines == null || tooltipLines!.isEmpty) {
      return positioned;
    }

    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: Tooltip(message: tooltipLines!.join('\n'), child: child),
    );
  }
}
