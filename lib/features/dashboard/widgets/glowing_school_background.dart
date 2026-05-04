import 'package:flutter/material.dart';
import 'dart:math' as math;

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

  Widget _buildFlyingParticle(
      double x, double startY, int speedMultiplier, double size, double baseOpacity) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double distance = 300.0 * speedMultiplier;
        double currentY = (startY - (_controller.value * distance)) % 300.0;
        
        currentY = currentY - 50;

        // Slow blink: complete 6 cycles per 30 seconds.
        // Use 'x' and 'startY' to offset the phase so particles blink independently.
        double blinkPhase = math.sin((_controller.value * math.pi * 2 * 6) + (x * 0.1) + (startY * 0.1));
        // Map from [-1, 1] to [0.2, 1.0] so it dims to 20% of its base opacity at minimum
        double blinkMultiplier = 0.2 + (0.8 * ((blinkPhase + 1) / 2));
        double currentOpacity = baseOpacity * blinkMultiplier;

        return Positioned(
          left: x,
          top: currentY,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(currentOpacity),
              shape: BoxShape.circle,
            ),
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
          // ShaderMask to fade out elements at the top (under device icons)
          Positioned.fill(
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.transparent, Colors.white],
                  stops: [0.0, 0.18, 0.45], // Completely transparent at top 18%, fades in by 45%
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
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
          
          // Small Floating Particles (mix of 30% and 50% opacity)
          _buildFlyingParticle(30, 100, 1, 4.0, 0.3),
          _buildFlyingParticle(70, 40, 2, 3.0, 0.5),
          _buildFlyingParticle(130, 200, 1, 5.0, 0.3),
          _buildFlyingParticle(190, 80, 2, 4.0, 0.5),
          _buildFlyingParticle(240, 160, 1, 3.0, 0.3),
          _buildFlyingParticle(280, 220, 2, 6.0, 0.5),
          _buildFlyingParticle(15, 260, 1, 3.5, 0.3),
          _buildFlyingParticle(55, 130, 2, 4.5, 0.5),
          _buildFlyingParticle(95, 290, 1, 5.0, 0.3),
          _buildFlyingParticle(145, 20, 2, 3.0, 0.5),
          _buildFlyingParticle(210, 270, 1, 4.0, 0.3),
          _buildFlyingParticle(265, 140, 2, 5.0, 0.5),
          _buildFlyingParticle(110, 110, 1, 4.0, 0.5),
          _buildFlyingParticle(170, 290, 2, 3.0, 0.3),
                ],
              ),
            ),
          ),
          
          // Main content
          Positioned.fill(
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

