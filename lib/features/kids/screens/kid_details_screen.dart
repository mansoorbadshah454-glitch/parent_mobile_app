import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/kids_provider.dart';
import '../widgets/shining_profile_avatar.dart';
import '../widgets/academic_tab_content.dart';
import '../widgets/personality_tab_content.dart';
import '../widgets/attendance_tab_content.dart';
import '../widgets/syllabus_tab_content.dart';
import '../widgets/result_tab_content.dart';
import '../widgets/tests_reports_tab_content.dart';
import '../widgets/chat_tab_content.dart';
import '../../../core/providers/parent_data_provider.dart';
import '../../../core/theme/theme_colors.dart';

class KidDetailsScreen extends ConsumerWidget {
  final KidData kid;
  final int initialTabIndex;

  const KidDetailsScreen({Key? key, required this.kid, this.initialTabIndex = 0}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentDataAsync = ref.watch(parentDataProvider);
    final kidsAsyncValue = ref.watch(kidsProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    final currentKid = kidsAsyncValue.value?.firstWhere((k) => k.id == kid.id, orElse: () => kid) ?? kid;

    return DefaultTabController(
      key: const ValueKey('kid_details_tabs_7'),
      length: 7,
      initialIndex: initialTabIndex,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // Combined School Header and Profile Section
            Container(
              padding: EdgeInsets.only(top: topPadding, bottom: 24),
              decoration: const BoxDecoration(
                color: ThemeColors.primaryPurple,
                image: DecorationImage(
                  image: AssetImage('assets/images/school_pattern.png'),
                  fit: BoxFit.cover,
                  opacity: 0.2, // Subtle overlay like whatsapp background
                ),
                boxShadow: [
                  BoxShadow(
                    color: ThemeColors.deepPurple,
                    offset: Offset(0, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // School Name Header Segment (with Back button instead of Drawer)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, right: 20, bottom: 12),
                    child: Row(
                      children: [
                        const SizedBox(width: 4),
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.school, size: 20, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        parentDataAsync.when(
                          data: (parentData) => Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  parentData?.schoolName ?? 'School App',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
                          ),
                          loading: () => const Expanded(child: SizedBox.shrink()),
                          error: (_, __) => const Expanded(child: SizedBox.shrink()),
                        ),
                      ],
                    ),
                  ),

                  // Student Profile Segment
                  const SizedBox(height: 12),
                  ShiningProfileAvatar(
                    imageUrl: currentKid.imageUrl,
                    radius: 50,
                    strokeWidth: 4,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currentKid.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, 
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Class: ${currentKid.className} | Roll No: ${currentKid.rollNo}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            
            // Menu Buttons (TabBar) with grey background
            Container(
              color: Colors.grey[200], 
              child: TabBar(
                isScrollable: true,
                labelColor: ThemeColors.primaryPurple,
                unselectedLabelColor: Colors.grey,
                indicatorColor: ThemeColors.primaryPurple,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'Academic'),
                  Tab(text: 'Personality'),
                  Tab(text: 'Attendance'),
                  Tab(text: 'Syllabus'),
                  Tab(text: 'Tests & Reports'),
                  Tab(text: 'Result'),
                  Tab(text: 'Chat'),
                ],
              ),
            ),
            
            // Empty Tabs Below
            Expanded(
              child: TabBarView(
                children: [
                  AcademicTabContent(kid: currentKid),
                  PersonalityTabContent(kid: currentKid),
                  AttendanceTabContent(kid: currentKid),
                  SyllabusTabContent(kid: currentKid),
                  TestsReportsTabContent(kid: currentKid),
                  ResultTabContent(kid: currentKid),
                  ChatTabContent(kid: currentKid),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
