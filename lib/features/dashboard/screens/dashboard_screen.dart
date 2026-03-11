import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/theme_colors.dart';
import '../widgets/animated_menu_button.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get screen size for responsive design
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: ThemeColors.backgroundColor,
      body: Column(
        children: [
          // 1. Normal Size Gradient Header
          Container(
            padding: EdgeInsets.only(
              top: topPadding + 10,
              bottom: 15,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              gradient: ThemeColors.instagramGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.school, // Placeholder for School Logo
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'School V5',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Parent Portal',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () {
                    ref.read(authControllerProvider.notifier).logout();
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),

          // 2. Wide Full-Screen Menu Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                AnimatedMenuButton(
                  icon: Icons.article_rounded,
                  label: 'News',
                  onTap: () => context.go('/news'),
                ),
                AnimatedMenuButton(
                  icon: Icons.child_care_rounded,
                  label: 'Kids',
                  onTap: () => context.go('/kids'),
                ),
                AnimatedMenuButton(
                  icon: Icons.message_rounded,
                  label: 'Messages',
                  onTap: () => context.go('/messages'),
                ),
                AnimatedMenuButton(
                  icon: Icons.notifications_active_rounded,
                  label: 'Alerts',
                  onTap: () => context.go('/notifications'),
                ),
              ],
            ),
          ),

          // 3. Main Scrollable Content area (Empty for now)
          const Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(height: 20),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
