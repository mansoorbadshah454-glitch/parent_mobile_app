import 'package:flutter/material.dart';
import '../../../core/theme/theme_colors.dart';

class AnimatedMenuButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final int? badgeCount;

  const AnimatedMenuButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.badgeCount,
  });

  @override
  State<AnimatedMenuButton> createState() => _AnimatedMenuButtonState();
}

class _AnimatedMenuButtonState extends State<AnimatedMenuButton> {
  @override
  Widget build(BuildContext context) {
    final activeColor = ThemeColors.primaryPurple;
    final inactiveColor = ThemeColors.secondaryText;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Badge(
              isLabelVisible: widget.badgeCount != null && widget.badgeCount! > 0,
              label: Text(widget.badgeCount?.toString() ?? ''),
              backgroundColor: Colors.redAccent,
              child: Icon(
                widget.icon,
                color: widget.isActive ? activeColor : inactiveColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: widget.isActive ? FontWeight.bold : FontWeight.w500,
                color: widget.isActive ? activeColor : inactiveColor,
              ),
            ),
            if (widget.isActive)
              Container(
                margin: const EdgeInsets.only(top: 4),
                height: 3,
                width: 20,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            else
              Container(
                margin: const EdgeInsets.only(top: 4),
                height: 3,
                width: 20,
              ),
          ],
        ),
      ),
    );
  }
}
