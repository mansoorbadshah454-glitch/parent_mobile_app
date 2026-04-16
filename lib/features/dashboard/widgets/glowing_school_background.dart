import 'package:flutter/material.dart';

class GlowingSchoolBackground extends StatefulWidget {
  final Widget child;

  const GlowingSchoolBackground({
    super.key,
    required this.child,
  });

  @override
  State<GlowingSchoolBackground> createState() => _GlowingSchoolBackgroundState();
}

class _GlowingSchoolBackgroundState extends State<GlowingSchoolBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Continuous loop for infinite flying animation from bottom to top
    // 30 seconds makes speed=1 feel very slow and graceful.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildFlyingIcon(
      IconData icon, double x, double startY, int speedMultiplier, double size, double opacity) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // By using integer speed multipliers, the distance traveled is an exact multiple of 300.
        // This guarantees that when _controller.value resets from 1.0 to 0.0, 
        // the modulo calculation results in the exact same mathematical position,
        // resulting in a flawless infinite loop with zero visual jumps.
        double distance = 300.0 * speedMultiplier;
        double currentY = (startY - (_controller.value * distance)) % 300.0;
        
        // Offset range to roughly [-50, 250] so they start below visually and fly past the top
        currentY = currentY - 50;

        return Positioned(
          left: x,
          top: currentY,
          child: Icon(
            icon,
            size: size,
            color: Colors.white.withOpacity(opacity),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Flat 2D Flying Background Elements (speed must be integer 1, 2, or 3)
          _buildFlyingIcon(Icons.school, 20, 200, 1, 18, 0.15),
          _buildFlyingIcon(Icons.menu_book, 220, 50, 1, 16, 0.12),
          _buildFlyingIcon(Icons.backpack, 10, 150, 2, 20, 0.10),
          _buildFlyingIcon(Icons.science, 250, 250, 1, 18, 0.15),
          _buildFlyingIcon(Icons.edit, 230, 120, 2, 15, 0.10),
          _buildFlyingIcon(Icons.calculate, -10, 80, 1, 16, 0.12),
          _buildFlyingIcon(Icons.brush, 120, 280, 2, 15, 0.08),
          _buildFlyingIcon(Icons.public, 140, 100, 1, 18, 0.15),
          _buildFlyingIcon(Icons.monitor, 60, 220, 2, 17, 0.10),
          _buildFlyingIcon(Icons.language, 180, 190, 1, 16, 0.12),
          _buildFlyingIcon(Icons.engineering, 40, 30, 2, 18, 0.10),
          _buildFlyingIcon(Icons.medical_services, 200, 280, 1, 15, 0.12),
          _buildFlyingIcon(Icons.architecture, 90, 160, 2, 17, 0.08),
          _buildFlyingIcon(Icons.biotech, 260, 70, 1, 16, 0.15),
          _buildFlyingIcon(Icons.plumbing, 100, 20, 2, 14, 0.10),
          _buildFlyingIcon(Icons.psychology, 160, 240, 1, 18, 0.15),
          
          // Main content
          Positioned.fill(
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

