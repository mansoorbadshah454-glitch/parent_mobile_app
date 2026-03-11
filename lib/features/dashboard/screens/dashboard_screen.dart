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
    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: ThemeColors.backgroundColor,
      body: Stack(
        children: [
          // 1. Gradient Header Background
          Container(
            height: size.height * 0.35,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: ThemeColors.instagramGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),
          
          // 2. Main Scrollable Content
          CustomScrollView(
            slivers: [
              // Header Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: topPadding + 20,
                    left: 20,
                    right: 20,
                    bottom: 20,
                  ),
                  child: Column(
                    children: [
                      // Top Row (Profile & Logout)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.white24,
                            child: Icon(Icons.person, color: Colors.white, size: 30),
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout, color: Colors.white),
                            onPressed: () {
                              ref.read(authControllerProvider.notifier).logout();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      
                      // School Info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.school, // Placeholder for School Logo
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'School V5',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Text(
                        'Parent Portal',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. The Menu Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                ),
              ),

              // Placeholder for future content (e.g. Recent Activities)
              const SliverToBoxAdapter(
                child: SizedBox(height: 40),
              )
            ],
          ),
        ],
      ),
    );
  }
}
