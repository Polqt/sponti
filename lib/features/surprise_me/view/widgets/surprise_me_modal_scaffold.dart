import 'package:flutter/material.dart';

class SurpriseMeModalScaffold extends StatelessWidget {
  const SurpriseMeModalScaffold({
    super.key,
    required this.child,
  });

  static const Color backgroundColor = Color(0xFF111113);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: child,
          ),
        ),
      ),
    );
  }
}

class SurpriseMeCloseRow extends StatelessWidget {
  const SurpriseMeCloseRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(
              Icons.close,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }
}

class SurpriseMeDragHandle extends StatelessWidget {
  const SurpriseMeDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
