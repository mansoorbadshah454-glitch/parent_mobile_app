import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/kids_provider.dart';
import '../providers/exam_results_provider.dart';
import '../utils/result_card_pdf_generator.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/providers/parent_data_provider.dart';
import '../../../core/utils/translation_helper.dart';

class TermResultDetailsScreen extends ConsumerStatefulWidget {
  final KidData kid;
  final ExamTermItem term;
  final List<ExamTermItem> allTerms;
  final String schoolName;
  final StudentExamResult result;
  final ConsolidatedExamResult consolidated;

  const TermResultDetailsScreen({
    super.key,
    required this.kid,
    required this.term,
    required this.allTerms,
    required this.schoolName,
    required this.result,
    required this.consolidated,
  });

  @override
  ConsumerState<TermResultDetailsScreen> createState() => _TermResultDetailsScreenState();
}

class _TermResultDetailsScreenState extends ConsumerState<TermResultDetailsScreen> {
  bool _isDownloadingPdf = false;

  Future<void> _downloadOrSharePdf({required bool isAllInOne}) async {
    setState(() => _isDownloadingPdf = true);
    try {
      final parentData = ref.read(parentDataProvider).value;
      final schoolLogo = parentData?.schoolLogo;
      File pdfFile;

      if (isAllInOne) {
        // Generate the 3-in-1 consolidated DMC matching Principal WebApp
        pdfFile = await ResultCardPdfGenerator.generateConsolidatedDmcPdf(
          consolidated: widget.consolidated,
          schoolName: widget.schoolName,
          schoolLogoUrl: schoolLogo,
          studentPhotoUrl: widget.kid.imageUrl,
        );
      } else {
        pdfFile = await ResultCardPdfGenerator.generateDmcPdf(
          result: widget.result,
          schoolName: widget.schoolName,
          schoolLogoUrl: schoolLogo,
          studentPhotoUrl: widget.kid.imageUrl,
        );
      }

      if (!mounted) return;
      final xFile = XFile(pdfFile.path);

      await Share.shareXFiles(
        [xFile],
        text: isAllInOne
            ? '${widget.kid.name} - Annual Consolidated (All-in-One) Result Card'
            : '${widget.kid.name} - ${widget.result.examTitle} DMC Result Card',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate result PDF: $e'),
            backgroundColor: Colors.red.shade700,
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
    String lang = 'en';
    try {
      lang = ref.watch(languageProvider);
    } catch (_) {}

    final res = widget.result;
    final isPassed = res.isPassed;
    final bool isFinalAnnual = widget.term.id.toLowerCase().contains('final') ||
        widget.term.id.toLowerCase().contains('annual') ||
        widget.term.title.toLowerCase().contains('final') ||
        widget.term.title.toLowerCase().contains('annual');

    return Scaffold(
      backgroundColor: ThemeColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: ThemeColors.primaryPurple,
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
              TranslationHelper.translate(widget.term.title, lang),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${widget.kid.name} • Class: ${widget.kid.className} • Roll #${widget.kid.rollNo}',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        children: [
          // 1. Digital Result Summary Box
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isPassed ? Colors.green.shade50 : Colors.red.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isPassed ? Icons.verified_rounded : Icons.info_outline_rounded,
                            size: 20,
                            color: isPassed ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              TranslationHelper.translate('Digital Result Card', lang),
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'Academic Session: ${widget.term.session}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPassed ? Colors.green.shade600 : Colors.red.shade600,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        res.statusLabel.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Metrics Grid
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9FC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _metricCol('Total Marks', '${res.totalObtained} / ${res.totalMax}'),
                      Container(width: 1, height: 30, color: Colors.grey.shade300),
                      _metricCol('Percentage', '${res.percentage.toStringAsFixed(1)}%'),
                      Container(width: 1, height: 30, color: Colors.grey.shade300),
                      _metricCol('Grade', res.grade, isGrade: true),
                      Container(width: 1, height: 30, color: Colors.grey.shade300),
                      _metricCol('Position', res.position.isNotEmpty && res.position != '-' ? res.position : 'N/A'),
                    ],
                  ),
                ),

                if (res.attendance.isNotEmpty && res.attendance != '-') ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_available_rounded, size: 16, color: Colors.green.shade800),
                        const SizedBox(width: 8),
                        Text(
                          '${TranslationHelper.translate('Term Attendance', lang)}: ${res.attendance}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 2. Subject-wise Breakdown Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.menu_book_rounded, color: ThemeColors.primaryPurple, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      TranslationHelper.translate('Subject Breakdown', lang),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${res.subjectMarks.length} ${TranslationHelper.translate('Subjects', lang)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 3. Subject Performance Cards
          if (res.subjectMarks.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  TranslationHelper.translate('No subject marks recorded for this term.', lang),
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
                ),
              ),
            )
          else
            ...res.subjectMarks.entries.map((entry) {
              final s = entry.value;
              final isSubjPass = !s.isAbsent && (s.obtained ?? 0) >= s.passingMarks;
              final pct = s.totalMarks > 0 ? ((s.obtained ?? 0) / s.totalMarks) : 0.0;

              Color gradeColor;
              if (s.isAbsent) {
                gradeColor = Colors.red.shade700;
              } else if (pct >= 0.8) {
                gradeColor = Colors.green.shade700;
              } else if (pct >= 0.6) {
                gradeColor = Colors.blue.shade700;
              } else if (pct >= 0.4) {
                gradeColor = Colors.amber.shade800;
              } else {
                gradeColor = Colors.red.shade700;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: gradeColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            s.grade,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: gradeColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              if (s.remarks.isNotEmpty)
                                Text(
                                  s.remarks,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              s.isAbsent ? 'ABSENT' : '${s.obtained ?? '-'} / ${s.totalMarks}',
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: s.isAbsent ? Colors.red : (isSubjPass ? Colors.black87 : Colors.red.shade800),
                              ),
                            ),
                            Text(
                              'Pass: ${s.passingMarks}',
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct.clamp(0.0, 1.0).toDouble(),
                        minHeight: 5,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(gradeColor),
                      ),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 20),

          // 4. Download Official PDF DMC Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.purple.shade100),
              boxShadow: [
                BoxShadow(
                  color: ThemeColors.primaryPurple.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      isFinalAnnual ? Icons.workspace_premium_rounded : Icons.picture_as_pdf_rounded,
                      color: ThemeColors.primaryPurple,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isFinalAnnual
                            ? TranslationHelper.translate('Annual Consolidated Result Card (All-in-One DMC)', lang)
                            : '${widget.term.title} ${TranslationHelper.translate('Official DMC', lang)}',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: ThemeColors.primaryPurple,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isFinalAnnual
                      ? TranslationHelper.translate(
                          'Downloads the complete official report card containing 1st Term, Mid Term, and Final Term performance in a single consolidated document.',
                          lang,
                        )
                      : TranslationHelper.translate(
                          'Downloads the official Detailed Marks Certificate (DMC) for this term with authorized signatures.',
                          lang,
                        ),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),

                // Primary Download Button
                ElevatedButton.icon(
                  onPressed: _isDownloadingPdf
                      ? null
                      : () => _downloadOrSharePdf(isAllInOne: isFinalAnnual),
                  icon: _isDownloadingPdf
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(isFinalAnnual ? Icons.workspace_premium_rounded : Icons.download_rounded, size: 18),
                  label: Text(
                    _isDownloadingPdf
                        ? TranslationHelper.translate('Generating PDF...', lang)
                        : isFinalAnnual
                            ? TranslationHelper.translate('Download Annual Consolidated PDF', lang)
                            : TranslationHelper.translate('Download Term DMC PDF', lang),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeColors.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                ),

                const SizedBox(height: 8),

                // Secondary Alternative Download Option
                OutlinedButton.icon(
                  onPressed: _isDownloadingPdf
                      ? null
                      : () => _downloadOrSharePdf(isAllInOne: !isFinalAnnual),
                  icon: Icon(
                    isFinalAnnual ? Icons.description_outlined : Icons.all_inclusive_rounded,
                    size: 16,
                    color: ThemeColors.primaryPurple,
                  ),
                  label: Text(
                    isFinalAnnual
                        ? TranslationHelper.translate('Download Final Term Only DMC', lang)
                        : TranslationHelper.translate('Download Consolidated (All-in-One) DMC', lang),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ThemeColors.primaryPurple,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ThemeColors.primaryPurple,
                    side: BorderSide(color: ThemeColors.primaryPurple.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _metricCol(String label, String value, {bool isGrade = false}) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isGrade ? ThemeColors.primaryPurple : Colors.black87,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
