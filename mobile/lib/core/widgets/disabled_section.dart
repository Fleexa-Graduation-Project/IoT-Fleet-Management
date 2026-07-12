import 'package:flutter/material.dart';

class DisabledSection extends StatelessWidget {
  const DisabledSection({
    super.key,
    required this.child,
    required this.isEnabled,
  });

  final bool isEnabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.4,
      child: AbsorbPointer(
        absorbing: !isEnabled,
        child: child,
      ),
    );
  }
}
