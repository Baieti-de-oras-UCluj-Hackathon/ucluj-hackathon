import 'package:flutter/material.dart';

import '../theme/color_tokens.dart';
import '../theme/spacing_tokens.dart';
import '../theme/typography_tokens.dart';

class AppButton extends StatelessWidget {
  const AppButton.primary({
    required this.label,
    required this.onPressed,
    super.key,
  }) : isPrimary = true;

  const AppButton.secondary({
    required this.label,
    required this.onPressed,
    super.key,
  }) : isPrimary = false;

  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final fg = isPrimary ? ColorTokens.onAccent : ColorTokens.accent;
    final bg = isPrimary ? ColorTokens.accent : Colors.transparent;

    return SizedBox(
      height: 48,
      child: TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.lg),
          backgroundColor: bg,
          foregroundColor: fg,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          side: isPrimary
              ? BorderSide.none
              : const BorderSide(color: ColorTokens.divider),
        ),
        onPressed: onPressed,
        child: Text(
          label.toUpperCase(),
          style: TypographyTokens.sectionLabel.copyWith(color: fg),
        ),
      ),
    );
  }
}
