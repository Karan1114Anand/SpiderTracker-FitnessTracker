/// A block of content set off by hairlines above and below instead of a
/// box around it. Keeps sections distinct without a card for every group.
library;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.color});

  final Widget child;

  /// Optional tint, for the one block on a screen that should stand out.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        border: const Border.symmetric(
          horizontal: BorderSide(color: SpiderColors.outline),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: SpiderSpace.md),
        child: child,
      ),
    );
  }
}
