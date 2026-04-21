import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/providers/parent_data_provider.dart';
import '../../../core/theme/theme_colors.dart';
import '../../kids/screens/kids_screen.dart';
import '../../news/screens/news_screen.dart';
import '../../chat/screens/chat_screen.dart';
import '../../alerts/screens/alerts_screen.dart';
import '../../fees/screens/fees_dashboard_screen.dart';
import '../widgets/animated_menu_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../../chat/providers/chat_provider.dart';
import '../../alerts/providers/alerts_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/glowing_school_background.dart';
import '../../../services/push_notification_service.dart';
import '../../menu/screens/school_timing_screen.dart';
import '../../menu/screens/bank_details_screen.dart';
import '../../menu/screens/help_support_screen.dart';
import '../../menu/screens/about_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../kids/providers/kids_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

final dashboardTabProvider = StateProvider<int>((ref) => 0);

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _showMenuBar = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PageController _pageController = PageController();
  bool _hasCheckedOverdueFees = false;

  void _checkOverdueFees(List<KidData> kids) async {
    if (_hasCheckedOverdueFees) return;
    _hasCheckedOverdueFees = true;

    final today = DateTime.now();
    bool hasUnpaid = kids.any((k) => k.monthlyFeeStatus.toLowerCase() == 'unpaid');
    
    // Push the local notification initializer early so we can schedule
    await PushNotificationService().initLocalNotifications();

    if (hasUnpaid) {
      final prefs = await SharedPreferences.getInstance();
      final dateKey = '${today.year}-${today.month}-${today.day}';
      final lastCheckedDate = prefs.getString('last_fee_date') ?? '';
      int currentCount = 0;
      
      if (lastCheckedDate == dateKey) {
        currentCount = prefs.getInt('fee_reminder_count') ?? 0;
      } else {
        prefs.setString('last_fee_date', dateKey);
        currentCount = 0;
      }
      
      for (final kid in kids.where((k) => k.monthlyFeeStatus.toLowerCase() == 'unpaid')) {
        PushNotificationService().scheduleFeeReminders(kid);

        if (currentCount < 2) {
          Future.delayed(const Duration(milliseconds: 1500), () {
            PushNotificationService.showGlobalAlert(
              'Fee Reminder',
              'Please clear the pending fee for ${kid.name}.',
              'fee',
              isEmergency: true,
            );
          });
        }
      }
      // only increment count if we actually showed it to unpaid folks
      if (currentCount < 2) prefs.setInt('fee_reminder_count', currentCount + 1);
    } else {
      for (final kid in kids) {
        PushNotificationService().cancelFeeReminders(kid);
      }
    }
  }

  final List<Widget> _screens = [
    const NewsScreen(),
    const KidsScreen(),
    const ChatScreen(),
    const AlertsScreen(),
    const FeesDashboardScreen(),
  ];

  void _onMenuTap(int targetIndex) {
    final currentIndex = ref.read(dashboardTabProvider);
    if (currentIndex == targetIndex) return;

    if (targetIndex == 2) {
      final parentDataAsync = ref.read(parentDataProvider);
      final schoolId = parentDataAsync.value?.schoolId;
      final parentId = parentDataAsync.value?.uid;
      if (schoolId != null && parentId != null) {
         ChatService.markAllParentChatsAsRead(schoolId, parentId);
      }
    } else if (targetIndex == 3) {
      ref.read(alertsActionProvider).markAllAsReadGlobally();
    }

    if ((currentIndex - targetIndex).abs() > 1) {
      _pageController.jumpToPage(targetIndex > currentIndex ? targetIndex - 1 : targetIndex + 1);
    }
    _pageController.animateToPage(
      targetIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(dashboardTabProvider, (previous, next) {
      if (_pageController.hasClients && _pageController.page?.round() != next) {
        _pageController.jumpToPage(next);
      }
    });

    ref.listen<AsyncValue<List<KidData>>>(kidsProvider, (previous, next) {
      if (next.value == null) return;
      final kids = next.value!;
      
      if (!_hasCheckedOverdueFees && kids.isNotEmpty) {
        _checkOverdueFees(kids);
      } else if (previous != null && previous.value != null) {
        for (final newKid in kids) {
          final oldKid = previous.value!.firstWhere((k) => k.id == newKid.id, orElse: () => newKid);
          if (oldKid.monthlyFeeStatus.toLowerCase() == 'unpaid' && newKid.monthlyFeeStatus.toLowerCase() == 'paid') {
            PushNotificationService.showGlobalAlert(
              'Fee Processed Successfully',
              'Thank you! The monthly fee for ${newKid.name} is now cleared.',
              'fee',
            );
            PushNotificationService().cancelFeeReminders(newKid);
          } else if (oldKid.monthlyFeeStatus.toLowerCase() == 'paid' && newKid.monthlyFeeStatus.toLowerCase() == 'unpaid') {
            PushNotificationService().scheduleFeeReminders(newKid);
          }
        }
      }
    });

    final currentIndex = ref.watch(dashboardTabProvider);
    final parentDataAsync = ref.watch(parentDataProvider);
    final chatAsync = ref.watch(chatProvider);
    final alertsAsync = ref.watch(alertsProvider);

    final unreadChats = chatAsync.value?.where((m) => !m.read).length ?? 0;
    final unreadAlerts = alertsAsync.value?.where((a) => !a.read).length ?? 0;
    
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

        // Initialize push notifications
        PushNotificationService().init(parentData.schoolId, parentData.uid);

        final topPadding = MediaQuery.of(context).padding.top;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: ThemeColors.backgroundColor,
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              height: 220 + MediaQuery.of(context).padding.top,
              decoration: const BoxDecoration(
                color: ThemeColors.primaryPurple,
              ),
              child: GlowingSchoolBackground(
                child: Padding(
                  padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 53,
                          backgroundColor: Colors.white24,
                          backgroundImage: (parentData.schoolLogo != null && parentData.schoolLogo!.trim().isNotEmpty)
                              ? CachedNetworkImageProvider(parentData.schoolLogo!)
                              : null,
                          child: (parentData.schoolLogo == null || parentData.schoolLogo!.trim().isEmpty)
                              ? const Icon(Icons.school, size: 60, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(height: 12),
                      Column(
                        children: [
                          Text(
                            parentData.schoolName ?? 'School App',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
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
            ),
          ),
            ListTile(
              leading: const Icon(Icons.access_time_filled, color: ThemeColors.primaryPurple),
              title: const Text('School Timing', style: TextStyle(color: ThemeColors.primaryText, fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SchoolTimingScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance, color: ThemeColors.primaryPurple),
              title: const Text("Bank Details", style: TextStyle(color: ThemeColors.primaryText, fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BankDetailsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_center, color: ThemeColors.primaryPurple),
              title: const Text('Help & Support', style: TextStyle(color: ThemeColors.primaryText, fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.info, color: ThemeColors.primaryPurple),
              title: const Text('About US', style: TextStyle(color: ThemeColors.primaryText, fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Divider(),
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
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _scaffoldKey.currentState?.openDrawer(),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                              return Stack(
                                alignment: Alignment.centerLeft,
                                children: <Widget>[
                                  ...previousChildren,
                                  if (currentChild != null) currentChild,
                                ],
                              );
                            },
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              final isSchoolBook = child.key == const ValueKey('header_school_book');
                              final slideAnimation = Tween<Offset>(
                                begin: isSchoolBook ? const Offset(0.0, 0.5) : const Offset(0.0, -0.5),
                                end: Offset.zero,
                              ).animate(animation);

                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: slideAnimation,
                                  child: child,
                                ),
                              );
                            },
                            child: (!_showMenuBar && currentIndex == 0)
                                ? Container(
                                    key: const ValueKey('header_school_book'),
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.shield, color: Colors.white, size: 28),
                                        const SizedBox(width: 8),
                                        Text(
                                          'SchoolBook',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Container(
                                    key: const ValueKey('header_school_name'),
                                    child: Row(
                                      children: [
                                        const CircleAvatar(
                                          radius: 18,
                                          backgroundColor: Colors.white24,
                                          child: Icon(Icons.school, size: 20, color: Colors.white),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              FittedBox(
                                                fit: BoxFit.scaleDown,
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  parentData.schoolName ?? 'School App',
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white,
                                                    fontSize: 19,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                "Track your kid's education",
                                                style: GoogleFonts.montserrat(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
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
                            isActive: currentIndex == 0,
                            onTap: () => _onMenuTap(0),
                          ),
                          AnimatedMenuButton(
                            icon: Icons.people_rounded,
                            label: 'Kids',
                            isActive: currentIndex == 1,
                            onTap: () => _onMenuTap(1),
                          ),
                          AnimatedMenuButton(
                            icon: Icons.message_rounded,
                            label: 'Chat',
                            isActive: currentIndex == 2,
                            badgeCount: unreadChats,
                            onTap: () => _onMenuTap(2),
                          ),
                          AnimatedMenuButton(
                            icon: Icons.notifications_active_rounded,
                            label: 'Alerts',
                            isActive: currentIndex == 3,
                            badgeCount: unreadAlerts,
                            onTap: () => _onMenuTap(3),
                          ),
                          AnimatedMenuButton(
                            icon: Icons.receipt_long_rounded,
                            label: 'Fees',
                            isActive: currentIndex == 4,
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
                  ref.read(dashboardTabProvider.notifier).state = index;
                  setState(() {
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


