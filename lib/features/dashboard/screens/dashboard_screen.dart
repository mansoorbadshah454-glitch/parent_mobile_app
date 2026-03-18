import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/providers/parent_data_provider.dart';
import '../../../core/theme/theme_colors.dart';
import '../../kids/screens/kids_screen.dart';
import '../../news/screens/news_screen.dart';
import '../../chat/screens/chat_screen.dart';
import '../../alerts/screens/alerts_screen.dart';
import '../widgets/animated_menu_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'placeholder_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;
  bool _showMenuBar = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PageController _pageController = PageController();

  final List<Widget> _screens = [
    const NewsScreen(),
    const KidsScreen(),
    const ChatScreen(),
    const AlertsScreen(),
    const PlaceholderScreen(title: 'Fees'),
  ];

  void _onMenuTap(int targetIndex) {
    if (_currentIndex == targetIndex) return;
    if ((_currentIndex - targetIndex).abs() > 1) {
      _pageController.jumpToPage(targetIndex > _currentIndex ? targetIndex - 1 : targetIndex + 1);
    }
    _pageController.animateToPage(
      targetIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final parentDataAsync = ref.watch(parentDataProvider);
    
    return parentDataAsync.when(
      loading: () => const Scaffold(
        backgroundColor: ThemeColors.backgroundColor,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading parent data: $error'),
              ElevatedButton(
                onPressed: () => ref.read(authControllerProvider.notifier).logout(),
                child: const Text('Logout'),
              )
            ],
          ),
        ),
      ),
      data: (parentData) {
        if (parentData == null) {
          // Edge case: user is logged in via FB Auth but has no valid parent doc.
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No valid parent account found.'),
                  TextButton(
                    onPressed: () => ref.read(authControllerProvider.notifier).logout(),
                    child: const Text('Logout'),
                  )
                ],
              ),
            ),
          );
        }

        final topPadding = MediaQuery.of(context).padding.top;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: ThemeColors.backgroundColor,
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: ThemeColors.primaryPurple,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.school, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        Text(
                          parentData.schoolName ?? 'School App',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Track your kid's education",
                          style: GoogleFonts.montserrat(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context); // Close drawer
                ref.read(authControllerProvider.notifier).logout();
              },
            ),
          ],
        ),
      ),
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
                        color: ThemeColors.deepPurple,
                        offset: Offset(0, 4),
                        blurRadius: 0, // Sharp shadow for 2D look
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => _scaffoldKey.currentState?.openDrawer(),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.white24,
                              child: Icon(Icons.school, size: 20, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  parentData.schoolName ?? 'School App',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "Track your kid's education",
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48), // Spacer to maintain layout balance
                    ],
                  ),
                ),

                // 2. Top Menu Bar (Facebook Style, now below header)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _showMenuBar ? 80.0 : 0.0,
                  curve: Curves.easeInOut,
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          AnimatedMenuButton(
                            icon: Icons.article_rounded,
                            label: 'News',
                            isActive: _currentIndex == 0,
                            onTap: () => _onMenuTap(0),
                          ),
                          AnimatedMenuButton(
                            icon: Icons.people_rounded,
                            label: 'Kids',
                            isActive: _currentIndex == 1,
                            onTap: () => _onMenuTap(1),
                          ),
                          AnimatedMenuButton(
                            icon: Icons.message_rounded,
                            label: 'Chat',
                            isActive: _currentIndex == 2,
                            onTap: () => _onMenuTap(2),
                          ),
                          AnimatedMenuButton(
                            icon: Icons.notifications_active_rounded,
                            label: 'Alerts',
                            isActive: _currentIndex == 3,
                            onTap: () => _onMenuTap(3),
                          ),
                          AnimatedMenuButton(
                            icon: Icons.receipt_long_rounded,
                            label: 'Fees',
                            isActive: _currentIndex == 4,
                            onTap: () => _onMenuTap(4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Main Content switching area
          Expanded(
            child: NotificationListener<ScrollUpdateNotification>(
              onNotification: (ScrollUpdateNotification notification) {
                if (notification.metrics.axis == Axis.vertical) {
                  if (notification.scrollDelta != null) {
                    if (notification.scrollDelta! > 2.0 && _showMenuBar) {
                      setState(() {
                        _showMenuBar = false;
                      });
                    } else if (notification.scrollDelta! < -2.0 && !_showMenuBar) {
                      setState(() {
                        _showMenuBar = true;
                      });
                    }
                  }
                }
                return false;
              },
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                    _showMenuBar = true; // reset to show menu horizontally
                  });
                },
                physics: const BouncingScrollPhysics(),
                children: _screens,
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


