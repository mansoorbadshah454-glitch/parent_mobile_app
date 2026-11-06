import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/kids_provider.dart';
import '../utils/subject_test_pdf_generator.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/providers/parent_data_provider.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/utils/translation_helper.dart';

class SubjectTestReportScreen extends ConsumerStatefulWidget {
  final KidData kid;
  final String subject;
  final List<Map<String, dynamic>> testReports;

  const SubjectTestReportScreen({
    super.key,
    required this.kid,
    required this.subject,
    required this.testReports,
  });

  @override
  ConsumerState<SubjectTestReportScreen> createState() => _SubjectTestReportScreenState();
}

class _SubjectTestReportScreenState extends ConsumerState<SubjectTestReportScreen> {
  bool _isDownloadingPdf = false;

  Color _getSubjectThemeColor(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('math')) return const Color(0xFF2563EB); // Royal Blue
    if (s.contains('sci')) return const Color(0xFF059669); // Emerald
    if (s.contains('eng')) return const Color(0xFF7C3AED); // Violet
    if (s.contains('urdu')) return const Color(0xFFD97706); // Amber
    if (s.contains('isl') || s.contains('deen')) return const Color(0xFF0D9488); // Teal
    if (s.contains('comp')) return const Color(0xFF0284C7); // Cyan
    if (s.contains('art') || s.contains('draw')) return const Color(0xFFDB2777); // Pink
    return ThemeColors.primaryPurple;
  }

  Future<void> _sharePdfReport() async {
    if (_isDownloadingPdf) return;
    if (widget.testReports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No test records available to generate PDF yet.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _isDownloadingPdf = true);

    try {
      final parentData = ref.read(parentDataProvider).value;
      final schoolName = parentData?.schoolName ?? 'Smart School';
      final schoolLogo = parentData?.schoolLogo;

      final File pdfFile = await SubjectTestPdfGenerator.generateSubjectReportPdf(
        kid: widget.kid,
        subject: widget.subject,
        testReports: widget.testReports,
        schoolName: schoolName,
        schoolLogoUrl: schoolLogo,
      );

      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: '${widget.kid.name} - ${widget.subject} Academic Test Report',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate report PDF: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloadingPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final themeColor = _getSubjectThemeColor(widget.subject);

    // Compute stats
    int totalTests = widget.testReports.length;
    int presentTests = 0;
    int absentTests = 0;
    num totalPossible = 0;
    num totalObtained = 0;
    num highestScore = 0;

    for (var test in widget.testReports) {
      final isAbsent = test['isAbsent'] == true;
      final maxM = num.tryParse(test['maxMarks']?.toString() ?? '10') ?? 10;
      totalPossible += maxM;

      if (isAbsent) {
        absentTests++;
      } else {
        presentTests++;
        final obt = num.tryParse(test['score']?.toString() ?? '0') ?? 0;
        totalObtained += obt;
        if (obt > highestScore) highestScore = obt;
      }
    }

    double avgPercentage = totalPossible > 0 ? (totalObtained / totalPossible) * 100 : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: themeColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              TranslationHelper.translate(widget.subject, lang),
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              '${widget.kid.name} • ${widget.kid.className}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white.withOpacity(0.85),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: _isDownloadingPdf
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    tooltip: 'Download PDF Report',
                    icon: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20),
                    ),
                    onPressed: _sharePdfReport,
                  ),
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          // 1. Overall Subject Performance Analytics Hero Card
          _buildSubjectHeroBanner(
            themeColor: themeColor,
            totalTests: totalTests,
            presentTests: presentTests,
            absentTests: absentTests,
            avgPercentage: avgPercentage,
            highestScore: highestScore,
            lang: lang,
          ),

          const SizedBox(height: 20),

          // 2. Section Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.history_rounded, color: themeColor, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    TranslationHelper.translate("Assessment History", lang),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  "$totalTests ${totalTests == 1 ? 'Test' : 'Tests'}",
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 3. Chronological Test History Cards
          if (widget.testReports.isEmpty)
            _buildEmptyState(lang)
          else
            ...widget.testReports.map((report) => _buildTestHistoryCard(
                  report: report,
                  themeColor: themeColor,
                  lang: lang,
                )),
        ],
      ),
    );
  }

  Widget _buildSubjectHeroBanner({
    required Color themeColor,
    required int totalTests,
    required int presentTests,
    required int absentTests,
    required double avgPercentage,
    required num highestScore,
    required String lang,
  }) {
    String performanceBadge = "Good Effort";
    Color badgeBg = Colors.blue.shade50;
    Color badgeTextColor = Colors.blue.shade700;

    if (avgPercentage >= 90) {
      performanceBadge = "Outstanding";
      badgeBg = const Color(0xFFECFDF5);
      badgeTextColor = const Color(0xFF059669);
    } else if (avgPercentage >= 75) {
      performanceBadge = "Very Good";
      badgeBg = const Color(0xFFEFF6FF);
      badgeTextColor = const Color(0xFF2563EB);
    } else if (avgPercentage >= 50) {
      performanceBadge = "Consistent";
      badgeBg = const Color(0xFFFFFBEB);
      badgeTextColor = const Color(0xFFD97706);
    } else {
      performanceBadge = "Needs Attention";
      badgeBg = const Color(0xFFFEF2F2);
      badgeTextColor = const Color(0xFFDC2626);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Banner with percentage and badge
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [themeColor, themeColor.withOpacity(0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TranslationHelper.translate("Overall Average", lang),
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          "${avgPercentage.toStringAsFixed(1)}%",
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            TranslationHelper.translate(performanceBadge, lang),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: badgeTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.insights_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),

          // Bottom Metric Pills
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                _buildStatColumn(
                  title: TranslationHelper.translate("Tests Held", lang),
                  value: "$totalTests",
                  icon: Icons.checklist_rtl_rounded,
                  color: const Color(0xFF475569),
                ),
                _buildVerticalDivider(),
                _buildStatColumn(
                  title: TranslationHelper.translate("Present", lang),
                  value: "$presentTests",
                  icon: Icons.check_circle_outline_rounded,
                  color: const Color(0xFF10B981),
                ),
                _buildVerticalDivider(),
                _buildStatColumn(
                  title: TranslationHelper.translate("Absent", lang),
                  value: "$absentTests",
                  icon: Icons.cancel_outlined,
                  color: absentTests > 0 ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
                ),
                _buildVerticalDivider(),
                _buildStatColumn(
                  title: TranslationHelper.translate("Best Score", lang),
                  value: "$highestScore M",
                  icon: Icons.emoji_events_outlined,
                  color: const Color(0xFFD97706),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 36,
      color: Colors.grey.shade200,
    );
  }

  Widget _buildTestHistoryCard({
    required Map<String, dynamic> report,
    required Color themeColor,
    required String lang,
  }) {
    final isAbsent = report['isAbsent'] == true;
    final maxMarks = num.tryParse(report['maxMarks']?.toString() ?? '10') ?? 10;
    final score = isAbsent ? null : num.tryParse(report['score']?.toString() ?? '0');
    final dateStr = report['date'] ?? report['dateStr'] ?? 'TBD';
    final chapter = report['chapter'] ?? 'Chapter Assessment';
    final topic = report['paragraphs'] ?? '';
    final testType = report['testType'] ?? 'Written';

    String formattedDate = dateStr;
    try {
      if (dateStr != 'TBD' && dateStr.isNotEmpty) {
        final dt = DateTime.parse(dateStr);
        formattedDate = DateFormat('MMM dd, yyyy').format(dt);
      }
    } catch (_) {}

    double percentage = 0.0;
    if (!isAbsent && score != null && maxMarks > 0) {
      percentage = (score / maxMarks) * 100;
    }

    String statusMsg = "Passed";
    Color statusColor = const Color(0xFF10B981);
    IconData statusIcon = Icons.stars_rounded;

    // Check if teacher entered custom remarks in Firestore
    final customTeacherRemark = report['remarks']?.toString().trim() ?? '';

    if (isAbsent) {
      statusMsg = "Marked ABSENT for this assessment.";
      statusColor = const Color(0xFFEF4444);
      statusIcon = Icons.person_off_rounded;
    } else if (customTeacherRemark.isNotEmpty) {
      statusMsg = customTeacherRemark;
      if (percentage >= 80) {
        statusColor = const Color(0xFF059669);
        statusIcon = Icons.star_rounded;
      } else if (percentage >= 50) {
        statusColor = const Color(0xFF2563EB);
        statusIcon = Icons.thumb_up_rounded;
      } else {
        statusColor = const Color(0xFFDC2626);
        statusIcon = Icons.priority_high_rounded;
      }
    } else if (percentage >= 100) {
      statusMsg = "Perfect Score! Exemplary mastery of this chapter.";
      statusColor = const Color(0xFF059669);
      statusIcon = Icons.emoji_events_rounded;
    } else if (percentage >= 90) {
      statusMsg = "Outstanding Performance! Excellent conceptual clarity.";
      statusColor = const Color(0xFF059669);
      statusIcon = Icons.star_rounded;
    } else if (percentage >= 75) {
      statusMsg = "Good Job! Solid effort, keep practicing.";
      statusColor = const Color(0xFF2563EB);
      statusIcon = Icons.thumb_up_rounded;
    } else if (percentage >= 60) {
      statusMsg = "Fair Performance. Revision needed on weak areas.";
      statusColor = const Color(0xFFD97706);
      statusIcon = Icons.trending_up_rounded;
    } else if (percentage >= 40) {
      statusMsg = "Passing Score. Consistent revision strongly advised.";
      statusColor = const Color(0xFFEA580C);
      statusIcon = Icons.help_outline_rounded;
    } else {
      statusMsg = "Needs Serious Attention & Extra Support.";
      statusColor = const Color(0xFFDC2626);
      statusIcon = Icons.priority_high_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAbsent ? Colors.red.shade100 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Type Pill, Date, and Score
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: themeColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        TranslationHelper.translate("$testType Test", lang),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: themeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formattedDate,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                // Score Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isAbsent ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isAbsent ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0),
                    ),
                  ),
                  child: isAbsent
                      ? Text(
                          TranslationHelper.translate("ABSENT", lang),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFDC2626),
                          ),
                        )
                      : Row(
                          children: [
                            Text(
                              "$score",
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF15803D),
                              ),
                            ),
                            Text(
                              " / $maxMarks",
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Chapter / Topic
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.menu_book_rounded, size: 18, color: themeColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chapter,
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      if (topic.isNotEmpty && topic != 'N/A') ...[
                        const SizedBox(height: 2),
                        Text(
                          topic,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Remarks / Percentage Footer
            Row(
              children: [
                Icon(statusIcon, size: 16, color: statusColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    TranslationHelper.translate(statusMsg, lang),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
                if (!isAbsent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "${percentage.toStringAsFixed(0)}%",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String lang) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.assignment_outlined, size: 52, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            TranslationHelper.translate("No Test Records Yet", lang),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            TranslationHelper.translate("Completed class test marks will appear here.", lang),
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
