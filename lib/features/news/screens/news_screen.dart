import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/news_provider.dart';
import '../widgets/parent_news_post_card.dart';

class _AnimatedSchoolCap extends StatefulWidget {
  final bool isRefreshing;
  final double pullValue;
  const _AnimatedSchoolCap({required this.isRefreshing, required this.pullValue});

  @override
  State<_AnimatedSchoolCap> createState() => _AnimatedSchoolCapState();
}

class _AnimatedSchoolCapState extends State<_AnimatedSchoolCap> with SingleTickerProviderStateMixin {
  late AnimationController _spinnerController;

  @override
  void initState() {
    super.initState();
    _spinnerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    if (widget.isRefreshing) _spinnerController.repeat();
  }

  @override
  void didUpdateWidget(_AnimatedSchoolCap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRefreshing && !_spinnerController.isAnimating) {
      _spinnerController.repeat();
    } else if (!widget.isRefreshing && _spinnerController.isAnimating) {
      _spinnerController.stop();
    }
  }

  @override
  void dispose() {
    _spinnerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _spinnerController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Faint un-filled outline serving as the background track
            const Icon(
              Icons.school_outlined,
              size: 34,
              color: Colors.black12,
            ),
            // The vividly drawn outline overlay
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) {
                if (widget.isRefreshing) {
                  // Comet-tail spinning animation when loading
                  return SweepGradient(
                    transform: GradientRotation(_spinnerController.value * 2 * 3.14159 - 3.14159 / 2),
                    colors: const [Colors.transparent, Colors.blue],
                    stops: const [0.0, 1.0],
                  ).createShader(bounds);
                } else {
                  // Sharp radial reveal when pulling
                  final reveal = widget.pullValue.clamp(0.0, 1.0);
                  return SweepGradient(
                    transform: const GradientRotation(-3.14159 / 2),
                    colors: const [Colors.blue, Colors.transparent],
                    stops: [reveal, reveal],
                  ).createShader(bounds);
                }
              },
              child: const Icon(
                Icons.school_outlined,
                size: 34,
                color: Colors.white, // Color is overridden by ShaderMask
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CustomPullToRefresh extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  
  const _CustomPullToRefresh({required this.child, required this.onRefresh});

  @override
  State<_CustomPullToRefresh> createState() => _CustomPullToRefreshState();
}

class _CustomPullToRefreshState extends State<_CustomPullToRefresh> with SingleTickerProviderStateMixin {
  double _pullExtent = 0.0;
  bool _isRefreshing = false;
  late AnimationController _snapController;
  late Animation<double> _snapAnimation;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _snapController.addListener(() {
      setState(() {
        _pullExtent = _snapAnimation.value;
      });
    });
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _triggerRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    
    // Snap to a holding position while refreshing
    _snapAnimation = Tween<double>(begin: _pullExtent, end: 50.0).animate(CurvedAnimation(parent: _snapController, curve: Curves.easeOut));
    _snapController.forward(from: 0.0);
    
    await widget.onRefresh();
    
    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
      // Animate away
      _snapAnimation = Tween<double>(begin: _pullExtent, end: 0.0).animate(CurvedAnimation(parent: _snapController, curve: Curves.easeIn));
      _snapController.forward(from: 0.0);
    }
  }

  void _animateBackToZero() {
    _snapAnimation = Tween<double>(begin: _pullExtent, end: 0.0).animate(CurvedAnimation(parent: _snapController, curve: Curves.easeIn));
    _snapController.forward(from: 0.0);
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (_isRefreshing) return false;

    if (notification is ScrollUpdateNotification) {
      if (notification.metrics.pixels < 0) {
        // iOS bouncing physics
        _snapController.stop();
        setState(() {
          _pullExtent = -notification.metrics.pixels;
        });
      } else if (_pullExtent > 0 && notification.scrollDelta != null && notification.scrollDelta! > 0) {
        // Reversing the pull
        setState(() {
          _pullExtent -= notification.scrollDelta!;
          if (_pullExtent < 0) _pullExtent = 0;
        });
      }
    } else if (notification is OverscrollNotification && notification.overscroll < 0) {
      // Android clamping physics
      _snapController.stop();
      setState(() {
        _pullExtent += -notification.overscroll * 0.4;
      });
    } else if (notification is ScrollEndNotification) {
      if (_pullExtent > 0) {
        if (_pullExtent > 70.0) {
          _triggerRefresh();
        } else {
          _animateBackToZero();
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final double pullProgress = (_pullExtent / 70.0).clamp(0.0, 1.0);

    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: widget.child,
        ),
        if (_pullExtent > 0)
          Positioned(
            top: 15.0 + (_pullExtent * 0.6).clamp(0.0, 45.0), // Floats gracefully over the post content
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9), // Extremely subtle backing for contrast if needed, but transparent shape
                  shape: BoxShape.circle,
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: _AnimatedSchoolCap(
                  isRefreshing: _isRefreshing,
                  pullValue: pullProgress,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class NewsScreen extends ConsumerWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsyncValue = ref.watch(newsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: newsAsyncValue.when(
        data: (posts) {
          if (posts.isEmpty) {
            return const Center(child: Text('No announcements yet.'));
          }
          return _CustomPullToRefresh(
            onRefresh: () async {
              return ref.refresh(newsProvider.future);
            },
            child: ListView.separated(
              // Using standard AlwaysScrollableScrollPhysics to avoid iOS bounce gaps on Android
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8, bottom: 100),
              itemCount: posts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final post = posts[index];
                return ParentNewsPostCard(post: post);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error loading feed: $error')),
      ),
    );
  }
}
