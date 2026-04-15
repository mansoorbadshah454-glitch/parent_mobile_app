import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ShiningProfileAvatar extends StatefulWidget {
  final String imageUrl;
  final double radius;
  final double strokeWidth;

  const ShiningProfileAvatar({
    Key? key,
    required this.imageUrl,
    this.radius = 40.0,
    this.strokeWidth = 3.0,
  }) : super(key: key);

  @override
  State<ShiningProfileAvatar> createState() => _ShiningProfileAvatarState();
}

class _ShiningProfileAvatarState extends State<ShiningProfileAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.all(widget.strokeWidth),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: const [
                Colors.purple,
                Colors.blue,
                Colors.pink,
                Colors.purple,
              ],
              stops: const [0.0, 0.3, 0.6, 1.0],
              transform: GradientRotation(_controller.value * 2 * 3.1415927),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(2), // Gap between border and image
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: widget.radius,
                  backgroundImage: CachedNetworkImageProvider(widget.imageUrl),
                  backgroundColor: Colors.grey[200],
                ),
                // Animated white shimmer layer over the image
                ClipOval(
                  child: SizedBox(
                    width: widget.radius * 2,
                    height: widget.radius * 2,
                    child: FractionalTranslation(
                      translation: Offset(_controller.value * 2 - 1, _controller.value * 2 - 1),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(alpha: 0.6),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                            stops: const [0.3, 0.5, 0.7],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
