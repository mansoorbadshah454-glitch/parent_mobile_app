import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/theme_colors.dart';
import '../widgets/animated_menu_button.dart';
import 'placeholder_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const PlaceholderScreen(title: 'News Feed'),
    const PlaceholderScreen(title: 'My Kids'),
    const PlaceholderScreen(title: 'Messages'),
    const PlaceholderScreen(title: 'Notifications'),
  ];

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: ThemeColors.backgroundColor,
      body: Column(
        children: [
          // 1. Top Navigation & Header Area (Flush to top)
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 2),
                )
              ],
            ),
            child: Column(
              children: [
                // 1. School Header (Flush to top, integrated with Status Bar)
                Container(
                  padding: EdgeInsets.only(
                    top: topPadding, // Status bar integration
                    left: 20,
                    right: 20,
                    bottom: 12,
                  ),
                  decoration: const BoxDecoration(
                    color: ThemeColors.primaryPurple,
                    boxShadow: [
                      BoxShadow(
                        color: ThemeColors.darkerPurple,
                        offset: Offset(0, 4),
                        blurRadius: 0, // Sharp shadow for 2D look
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white24,
                            child: Icon(Icons.school, size: 20, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'School V5',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white, size: 20),
                        onPressed: () {
                          ref.read(authControllerProvider.notifier).logout();
                        },
                      ),
                    ],
                  ),
                ),

                // 2. Top Menu Bar (Facebook Style, now below header)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      AnimatedMenuButton(
                        icon: Icons.article_rounded,
                        label: 'News',
                        isActive: _currentIndex == 0,
                        onTap: () => setState(() => _currentIndex = 0),
                      ),
                      AnimatedMenuButton(
                        icon: Icons.child_care_rounded,
                        label: 'Kids',
                        isActive: _currentIndex == 1,
                        onTap: () => setState(() => _currentIndex = 1),
                      ),
                      AnimatedMenuButton(
                        icon: Icons.message_rounded,
                        label: 'Chat',
                        isActive: _currentIndex == 2,
                        onTap: () => setState(() => _currentIndex = 2),
                      ),
                      AnimatedMenuButton(
                        icon: Icons.notifications_active_rounded,
                        label: 'Alerts',
                        isActive: _currentIndex == 3,
                        onTap: () => setState(() => _currentIndex = 3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Main Content switching area
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
    );
  }
}

