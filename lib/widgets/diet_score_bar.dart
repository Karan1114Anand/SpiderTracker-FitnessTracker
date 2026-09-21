/// Today's diet score as eight segments, one per possible point.
library;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/spider_copy.dart';

class DietScoreBar extends StatelessWidget {
  const DietScoreBar({super.key, required this.score, this.showLabel = true});

  /// 0 to 8. Values outside are clamped.
  final int score;
  final bool showLabel;

  static const int max = 8;

  @override
  Widget build(BuildContext context) {
    final s = score.clamp(0, max);
    final text = Theme.of(context).textTheme;

    return Semantics(
      label: 'Diet score $s of $max',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < max; i++) ...[
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: i < s ? SpiderColors.info : SpiderColors.outline,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                if (i < max - 1) const SizedBox(width: 4),
              ],
            ],
          ),
          if (showLabel) ...[
            const SizedBox(height: SpiderSpace.sm),
            Row(
              children: [
                Text('$s of $max', style: text.bodySmall),
                const Spacer(),
                Text(SpiderCopy.webStrengthLabel(s), style: text.bodySmall),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
