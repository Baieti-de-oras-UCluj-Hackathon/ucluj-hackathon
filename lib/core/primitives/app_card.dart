import 'package:flutter/material.dart';

import '../theme/color_tokens.dart';
import '../theme/spacing_tokens.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(SpacingTokens.md),
    this.backgroundColor = ColorTokens.surfaceHigh,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.zero,
      ),
      child: child,
    );
  }
}
