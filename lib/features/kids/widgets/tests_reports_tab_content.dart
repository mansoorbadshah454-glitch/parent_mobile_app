import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/kids_provider.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/utils/translation_helper.dart';
import '../../alerts/screens/scheduled_tests_screen.dart';
import '../../alerts/widgets/scheduled_tests_list.dart';
import '../../alerts/widgets/test_reports_list.dart';

class TestsReportsTabContent extends ConsumerWidget {
  final KidData kid;
  
  const TestsReportsTabContent({Key? key, required this.kid}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testsAsyncValue = ref.watch(scheduledTestsProvider(kid.classId));
    final reportsAsyncValue = ref.watch(testReportsProvider(TestReportArgs(classId: kid.classId, studentId: kid.id)));
    final lang = ref.watch(languageProvider);
    final isUrdu = lang == 'ur';

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(24.0),
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                indicator: BoxDecoration(
                  color: ThemeColors.primaryPurple,
                  borderRadius: BorderRadius.circular(24.0),
                  boxShadow: [
                    BoxShadow(
                      color: ThemeColors.primaryPurple.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                splashBorderRadius: BorderRadius.circular(24.0),
                tabs: [
                  Tab(text: TranslationHelper.translate("Scheduled", lang)),
                  Tab(text: TranslationHelper.translate("Reports", lang)),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                ScheduledTestsList(
                  testsAsyncValue: testsAsyncValue,
                  kid: kid,
                  isUrdu: isUrdu,
                  lang: lang,
                ),
                TestReportsList(
                  reportsAsyncValue: reportsAsyncValue,
                  kid: kid,
                  isUrdu: isUrdu,
                  lang: lang,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
