import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../kids/providers/kids_provider.dart';
import '../../kids/screens/subject_test_report_screen.dart';
import '../screens/scheduled_tests_screen.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/utils/translation_helper.dart';

class TestReportsList extends ConsumerWidget {
  final AsyncValue<List<Map<String, dynamic>>> reportsAsyncValue;
  final KidData kid;
  final bool isUrdu;
  final String lang;

  const TestReportsList({
    Key? key,
    required this.reportsAsyncValue,
    required this.kid,
    required this.isUrdu,
    required this.lang,
  }) : super(key: key);

  Color _getSubjectColor(String subject) {
    final s = subject.toLowerCase().trim();
    if (s.contains('math') || s.contains('hisab') || s.contains('algebra') || s.contains('geom')) {
      return const Color(0xFF2563EB); // Royal Blue
    }
    if (s.contains('bio') || s.contains('chem') || s.contains('phys') || s.contains('sci')) {
      return const Color(0xFF059669); // Emerald
    }
    if (s.contains('eng')) {
      return const Color(0xFF7C3AED); // Violet
    }
    if (s.contains('urdu')) {
      return const Color(0xFFD97706); // Amber
    }
    if (s.contains('isl') || s.contains('deen') || s.contains('quran') || s.contains('tarjuma') || s.contains('nazra')) {
      return const Color(0xFF0D9488); // Teal
    }
    if (s.contains('comp') || s.contains('it') || s.contains('robot') || s.contains('tech')) {
      return const Color(0xFF0284C7); // Cyan
    }
    if (s.contains('pak') || s.contains('pst') || s.contains('soc') || s.contains('mutalia') || s.contains('geog') || s.contains('hist')) {
      return const Color(0xFF4338CA); // Indigo
    }
    if (s.contains('art') || s.contains('draw')) {
      return const Color(0xFFDB2777); // Pink
    }
    if (s.contains('gk') || s.contains('general k') || s.contains('ethics') || s.contains('akhlaq')) {
      return const Color(0xFF9333EA); // Purple
    }

    // Deterministic color generation for any custom subject created by Principal
    final palette = [
      const Color(0xFF2563EB),
      const Color(0xFF059669),
      const Color(0xFF7C3AED),
      const Color(0xFFD97706),
      const Color(0xFF0D9488),
      const Color(0xFF0284C7),
      const Color(0xFFE11D48),
      const Color(0xFF4F46E5),
    ];
    final hash = s.codeUnits.fold(0, (prev, elem) => prev + elem);
    return palette[hash % palette.length];
  }

  IconData _getSubjectIcon(String subject) {
    final s = subject.toLowerCase().trim();
    if (s.contains('math') || s.contains('hisab') || s.contains('algebra') || s.contains('geom')) {
      return Icons.calculate_rounded;
    }
    if (s.contains('bio') || s.contains('chem') || s.contains('phys') || s.contains('sci')) {
      return Icons.biotech_rounded;
    }
    if (s.contains('eng')) {
      return Icons.menu_book_rounded;
    }
    if (s.contains('urdu')) {
      return Icons.history_edu_rounded;
    }
    if (s.contains('isl') || s.contains('deen') || s.contains('quran') || s.contains('tarjuma') || s.contains('nazra')) {
      return Icons.mosque_rounded;
    }
    if (s.contains('comp') || s.contains('it') || s.contains('robot') || s.contains('tech')) {
      return Icons.computer_rounded;
    }
    if (s.contains('pak') || s.contains('pst') || s.contains('soc') || s.contains('mutalia') || s.contains('geog') || s.contains('hist')) {
      return Icons.public_rounded;
    }
    if (s.contains('art') || s.contains('draw')) {
      return Icons.palette_rounded;
    }
    if (s.contains('gk') || s.contains('general k') || s.contains('ethics') || s.contains('akhlaq')) {
      return Icons.lightbulb_rounded;
    }
    return Icons.auto_stories_rounded;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Live class subjects directly from Principal WebApp configuration
    final classSubjectsAsync = ref.watch(classSubjectsProvider(kid.classId));
    final List<String> liveClassSubjects = classSubjectsAsync.valueOrNull ?? [];

    // 2. Live test scores reported from Firestore
    final liveReports = reportsAsyncValue.valueOrNull ?? [];

    // Group reports by Subject
    final Map<String, List<Map<String, dynamic>>> groupedBySubject = {};
    for (var report in liveReports) {
      final subject = (report['subject'] ?? 'General').toString().trim();
      if (subject.isEmpty) continue;
      groupedBySubject.putIfAbsent(subject, () => []).add(report);
    }

    // Determine all subjects to display (Principal WebApp curriculum subjects + any reported tests)
    final Set<String> allSubjects = {};
    if (liveClassSubjects.isNotEmpty) {
      allSubjects.addAll(liveClassSubjects);
    }
    allSubjects.addAll(groupedBySubject.keys);

    final sortedSubjects = allSubjects.toList()..sort();

    return reportsAsyncValue.when(
      data: (_) {
        if (sortedSubjects.isEmpty) {
          return Center(child: _buildEmptySubjectsView());
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          physics: const BouncingScrollPhysics(),
          children: [
            // Top Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: ThemeColors.primaryPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.assessment_rounded,
                      color: ThemeColors.primaryPurple,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          TranslationHelper.translate('Subject Test Performance', lang),
                          style: GoogleFonts.inter(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          TranslationHelper.translate(
                            'Select a subject to view assessment history & download report card.',
                            lang,
                          ),
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Subject Cards
            ...sortedSubjects.map((subject) {
              final subjectTests = groupedBySubject[subject] ?? [];
              return _buildSubjectCard(
                context: context,
                subject: subject,
                tests: subjectTests,
              );
            }),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: ThemeColors.primaryPurple),
      ),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error loading test reports: $err',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectCard({
    required BuildContext context,
    required String subject,
    required List<Map<String, dynamic>> tests,
  }) {
    final themeColor = _getSubjectColor(subject);
    final iconData = _getSubjectIcon(subject);

    final bool hasTests = tests.isNotEmpty;
    int totalTests = tests.length;
    num totalPossible = 0;
    num totalObtained = 0;

    for (var test in tests) {
      final isAbsent = test['isAbsent'] == true;
      final maxM = num.tryParse(test['maxMarks']?.toString() ?? '10') ?? 10;
      totalPossible += maxM;

      if (!isAbsent) {
        final obt = num.tryParse(test['score']?.toString() ?? '0') ?? 0;
        totalObtained += obt;
      }
    }

    double avgPct = totalPossible > 0 ? (totalObtained / totalPossible) * 100 : 0.0;

    // Latest test info
    final latestTest = hasTests ? tests.first : null;
    final bool latestAbsent = latestTest?['isAbsent'] == true;
    final latestScore = latestTest?['score'];
    final latestMax = latestTest?['maxMarks'] ?? 10;
    final latestChapter = latestTest?['chapter'] ?? 'Chapter Assessment';

    String performanceLabel = "Enrolled";
    Color badgeColor = const Color(0xFF475569);
    Color badgeBg = const Color(0xFFF1F5F9);

    if (hasTests) {
      if (avgPct >= 90) {
        performanceLabel = "Outstanding";
        badgeColor = const Color(0xFF059669);
        badgeBg = const Color(0xFFECFDF5);
      } else if (avgPct >= 75) {
        performanceLabel = "Very Good";
        badgeColor = const Color(0xFF2563EB);
        badgeBg = const Color(0xFFEFF6FF);
      } else if (avgPct >= 50) {
        performanceLabel = "Satisfactory";
        badgeColor = const Color(0xFFD97706);
        badgeBg = const Color(0xFFFFFBEB);
      } else {
        performanceLabel = "Needs Focus";
        badgeColor = const Color(0xFFDC2626);
        badgeBg = const Color(0xFFFEF2F2);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          splashColor: themeColor.withOpacity(0.12),
          highlightColor: themeColor.withOpacity(0.06),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => SubjectTestReportScreen(
                  kid: kid,
                  subject: subject,
                  testReports: tests,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Subject Icon + Title + Count Pill
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: themeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(iconData, color: themeColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject,
                            style: GoogleFonts.inter(
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hasTests
                                ? "$totalTests ${totalTests == 1 ? 'Test Recorded' : 'Tests Recorded'}"
                                : "Awaiting First Assessment",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: badgeColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        TranslationHelper.translate(performanceLabel, lang),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Latest Test Snippet & Average Score Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            hasTests ? Icons.star_outline_rounded : Icons.schedule_rounded,
                            size: 16,
                            color: hasTests ? Colors.amber.shade700 : Colors.grey.shade500,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              !hasTests
                                  ? "No tests conducted yet"
                                  : (latestAbsent
                                      ? "Latest: ABSENT ($latestChapter)"
                                      : "Latest: $latestScore/$latestMax • $latestChapter"),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF334155),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Row(
                      children: [
                        if (hasTests)
                          Text(
                            "${avgPct.toStringAsFixed(0)}% Avg",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: themeColor,
                            ),
                          ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: themeColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySubjectsView() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.menu_book_rounded, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            "No Subjects Configured",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Subjects assigned to this class in the Principal Portal will appear here automatically.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
