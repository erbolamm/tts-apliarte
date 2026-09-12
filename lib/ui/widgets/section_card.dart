import 'package:flutter/material.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.initiallyExpanded = false,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(title, style: Theme.of(context).textTheme.titleLarge),
        children: [
          if (trailing != null) ...[trailing!, const SizedBox(height: 12)],
          child,
        ],
      ),
    );
  }
}
