import 'package:flutter/material.dart';

/// Section 2 of the product brief is explicit: "Never label generated material as official DBE
/// content." Any lesson, flashcard, or question with `isSeedDemoContent == true` (or, for real
/// content, `verificationStatus != verified`) must show this badge wherever it's displayed —
/// there is no code path that renders such content without it.
class DemoContentBadge extends StatelessWidget {
  final String label;

  const DemoContentBadge({
    super.key,
    this.label = 'Demo content — not yet curriculum-verified',
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 14,
            color: scheme.onTertiaryContainer,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: scheme.onTertiaryContainer),
              semanticsLabel: label,
            ),
          ),
        ],
      ),
    );
  }
}
