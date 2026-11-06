import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../kids/providers/kids_provider.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/utils/translation_helper.dart';

class ScheduledTestsList extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> testsAsyncValue;
  final KidData kid;
  final bool isUrdu;
  final String lang;

  const ScheduledTestsList({
    Key? key,
    required this.testsAsyncValue,
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
    return Icons.assignment_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return testsAsyncValue.when(
      data: (tests) {
        if (tests.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: ThemeColors.primaryPurple.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.event_available_rounded,
                      size: 54,
                      color: ThemeColors.primaryPurple,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    TranslationHelper.translate('No Upcoming Tests', lang),
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      color: const Color(0xFF1E293B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    TranslationHelper.translate(
                      'All clear! When a teacher schedules a class test, it will appear here with syllabus & timing.',
                      lang,
                    ),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          physics: const BouncingScrollPhysics(),
          itemCount: tests.length,
          itemBuilder: (context, index) {
            final test = tests[index];
            return _buildSmartTestCard(context, test);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: ThemeColors.primaryPurple),
      ),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error loading scheduled tests: $err',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }

  Widget _buildSmartTestCard(BuildContext context, Map<String, dynamic> test) {
    final subject = test['subject'] ?? 'Subject';
    final testType = test['testType'] ?? 'Written';
    final chapter = test['chapter'] ?? 'Chapter Assessment';
    final topic = test['paragraphs'] ?? '';
    final dateStr = test['dateStr'] ?? 'TBD';
    final timeStr = test['timeStr'] ?? '';
    final maxMarks = test['maxMarks'] ?? 10;
    final themeColor = _getSubjectColor(subject);
    final subjectIcon = _getSubjectIcon(subject);

    // Date Parsing & Countdown
    String dayNumber = '--';
    String monthShort = 'TBD';
    String relativePill = 'Upcoming';
    Color relativePillBg = themeColor.withOpacity(0.1);
    Color relativePillText = themeColor;

    try {
      if (dateStr != 'TBD' && dateStr.isNotEmpty) {
        final dt = DateTime.parse(dateStr);
        dayNumber = DateFormat('dd').format(dt);
        monthShort = DateFormat('MMM').format(dt).toUpperCase();

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final testDay = DateTime(dt.year, dt.month, dt.day);
        final diffDays = testDay.difference(today).inDays;

        if (diffDays == 0) {
          relativePill = 'TODAY';
          relativePillBg = const Color(0xFFFEF2F2);
          relativePillText = const Color(0xFFDC2626);
        } else if (diffDays == 1) {
          relativePill = 'TOMORROW';
          relativePillBg = const Color(0xFFFFFBEB);
          relativePillText = const Color(0xFFD97706);
        } else if (diffDays > 1 && diffDays <= 7) {
          relativePill = 'In $diffDays Days';
          relativePillBg = const Color(0xFFEFF6FF);
          relativePillText = const Color(0xFF2563EB);
        } else if (diffDays > 7) {
          relativePill = 'Next Week';
          relativePillBg = const Color(0xFFF3E8FF);
          relativePillText = const Color(0xFF7E22CE);
        } else if (diffDays < 0) {
          relativePill = 'Past Due';
          relativePillBg = Colors.grey.shade100;
          relativePillText = Colors.grey.shade600;
        }
      }
    } catch (_) {}

    final personalizedMessage =
        "Help ${kid.name} prepare by revising the syllabus topics and practicing key concepts!";

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            // Top Main Info Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Date Block
                  Container(
                    width: 58,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        Text(
                          monthShort,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: themeColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dayNumber,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        if (timeStr.isNotEmpty && timeStr != 'TBD') ...[
                          const SizedBox(height: 2),
                          Text(
                            timeStr,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Middle Subject & Type Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(subjectIcon, size: 18, color: themeColor),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      TranslationHelper.translate(subject, lang),
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0F172A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Urgency Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: relativePillBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: relativePillText.withOpacity(0.3)),
                              ),
                              child: Text(
                                TranslationHelper.translate(relativePill, lang),
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: relativePillText,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Badges: Test Type + Max Marks
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: themeColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                TranslationHelper.translate("$testType Test", lang),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: themeColor,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "Max: $maxMarks M",
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Syllabus Scope (Chapter & Topic)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bookmark_border_rounded, size: 16, color: themeColor),
                      const SizedBox(width: 6),
                      Text(
                        TranslationHelper.translate("Chapter:", lang),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          chapter,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (topic.isNotEmpty && topic != 'N/A') ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.format_list_bulleted_rounded,
                            size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Text(
                          TranslationHelper.translate("Topics:", lang),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            topic,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: const Color(0xFF334155),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Bottom Parent Tip Box
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.tips_and_updates_outlined, size: 16, color: Colors.amber.shade900),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        TranslationHelper.translate(personalizedMessage, lang),
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
