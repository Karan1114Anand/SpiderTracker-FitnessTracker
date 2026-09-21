/// A number over its label. Rows of these replace boxed stat tiles.
library;

import 'package:flutter/material.dart';

class Figure extends StatelessWidget {
  const Figure({
    super.key,
    required this.value,
    required this.label,
    this.onTap,
    this.color,
  });

  final String value;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: text.displayMedium?.copyWith(color: color)),
            const SizedBox(height: 4),
            Text(label, style: text.bodySmall),
          ],
        ),
      ),
    );
  }
}
