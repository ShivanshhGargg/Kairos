import 'package:flutter/material.dart';

import '../../app/theme.dart';

class MetadataRow extends StatelessWidget {
  const MetadataRow({
    required this.label,
    required this.value,
    this.labelWidth = 124,
    super.key,
  });

  final String label;
  final String value;
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelSmall;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: labelStyle),
              const SizedBox(height: KairosSpacing.xs),
              Text(value),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: labelWidth,
              child: Text(label, style: labelStyle),
            ),
            const SizedBox(width: KairosSpacing.sm),
            Expanded(child: Text(value)),
          ],
        );
      },
    );
  }
}
