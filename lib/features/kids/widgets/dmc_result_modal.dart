import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/providers/parent_data_provider.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/utils/translation_helper.dart';
import '../providers/exam_results_provider.dart';
import '../utils/result_card_pdf_generator.dart';

class DmcResultModal extends ConsumerStatefulWidget {
  final StudentExamResult? result;
  final ConsolidatedExamResult? consolidated;
  final String schoolName;

  const DmcResultModal({
    Key? key,
    this.result,
    this.consolidated,
    required this.schoolName,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    StudentExamResult? result,
    ConsolidatedExamResult? consolidated,
    required String schoolName,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DmcResultModal(
        result: result,
        consolidated: consolidated,
        schoolName: schoolName,
      ),
    );
  }

  @override
  ConsumerState<DmcResultModal> createState() => _DmcResultModalState();
}

class _DmcResultModalState extends ConsumerState<DmcResultModal> {
  bool _isGeneratingPdf = false;

  Future<void> _downloadOrSharePdf() async {
    setState(() => _isGeneratingPdf = true);
    try {
      final parentData = ref.read(parentDataProvider).value;
      final schoolLogo = parentData?.schoolLogo;

      if (widget.consolidated != null) {
        final pdfFile = await ResultCardPdfGenerator.generateConsolidatedDmcPdf(
          consolidated: widget.consolidated!,
          schoolName: widget.schoolName,
          schoolLogoUrl: schoolLogo,
        );

        if (!mounted) return;
        final xFile = XFile(pdfFile.path);
        await Share.shareXFiles(
          [xFile],
          text: '${widget.consolidated!.studentName} - Annual Consolidated (3-in-1) Result Card',
        );
      } else if (widget.result != null) {
        final pdfFile = await ResultCardPdfGenerator.generateDmcPdf(
          result: widget.result!,
          schoolName: widget.schoolName,
          schoolLogoUrl: schoolLogo,
        );

        if (!mounted) return;
        final xFile = XFile(pdfFile.path);
        await Share.shareXFiles(
          [xFile],
          text: '${widget.result!.studentName} - ${widget.result!.examTitle} DMC Result Card',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final parentData = ref.watch(parentDataProvider).value;
    final schoolLogo = parentData?.schoolLogo;
    final isConsolidated = widget.consolidated != null;
    final res = widget.result;
    final cons = widget.consolidated;
    final isPassed = isConsolidated ? (cons?.isPassed ?? true) : (res?.isPassed ?? true);
    final examTitle = isConsolidated ? 'Annual Consolidated (3-in-1)' : (res?.examTitle ?? 'Exam Result');

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                if (schoolLogo != null && schoolLogo.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: schoolLogo,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: ThemeColors.primaryPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.school_rounded, color: ThemeColors.primaryPurple, size: 24),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ThemeColors.primaryPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.school_rounded, color: ThemeColors.primaryPurple, size: 28),
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        examTitle,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.schoolName,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.black54),
                ),
              ],
            ),
          ),

          const Divider(height: 24),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Student Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9FC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _studentMetaCol(
                              'Student Name',
                              isConsolidated ? (cons?.studentName ?? '') : (res?.studentName ?? ''),
                            ),
                            _studentMetaCol(
                              'Roll No',
                              isConsolidated ? (cons?.rollNumber ?? '') : (res?.rollNumber ?? ''),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _studentMetaCol(
                              'Class',
                              isConsolidated ? (cons?.className ?? '') : (res?.className ?? ''),
                            ),
                            _studentMetaCol(
                              'Position in Class',
                              isConsolidated
                                  ? (cons?.position.isNotEmpty == true && cons!.position != '-' ? cons.position : 'N/A')
                                  : (res?.position.isNotEmpty == true && res!.position != '-' ? res.position : 'N/A'),
                            ),
                          ],
                        ),
                        if ((isConsolidated ? cons?.attendance : res?.attendance)?.isNotEmpty == true &&
                            (isConsolidated ? cons?.attendance : res?.attendance) != '-') ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.event_available_rounded, size: 16, color: Colors.green.shade800),
                                const SizedBox(width: 8),
                                Text(
                                  TranslationHelper.translate('Attendance', lang) + ':',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    isConsolidated ? cons!.attendance : res!.attendance,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Big Performance Banner
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ThemeColors.primaryPurple,
                          ThemeColors.primaryPurple.withOpacity(0.85),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: ThemeColors.primaryPurple.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _statBox(
                              'Total Marks',
                              isConsolidated
                                  ? '${cons?.grandTotalObtained ?? 0} / ${cons?.grandTotalMax ?? 0}'
                                  : '${res?.totalObtained ?? 0} / ${res?.totalMax ?? 0}',
                            ),
                            Container(width: 1, height: 36, color: Colors.white24),
                            _statBox(
                              'Percentage',
                              isConsolidated
                                  ? '${cons?.overallPercentage.toStringAsFixed(1) ?? 0}%'
                                  : '${res?.percentage.toStringAsFixed(1) ?? 0}%',
                            ),
                            Container(width: 1, height: 36, color: Colors.white24),
                            _statBox(
                              'Grade',
                              isConsolidated ? (cons?.overallGrade ?? '-') : (res?.grade ?? '-'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: isPassed ? Colors.green.shade600 : Colors.red.shade600,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            (isConsolidated ? cons?.statusLabel : res?.statusLabel)?.toUpperCase() ?? 'PASSED',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Subject Breakdown Title
                  Row(
                    children: [
                      const Icon(Icons.menu_book_rounded, size: 20, color: ThemeColors.primaryPurple),
                      const SizedBox(width: 8),
                      Text(
                        isConsolidated
                            ? TranslationHelper.translate('3-Terms Consolidated Subjects', lang)
                            : TranslationHelper.translate('Subject Breakdown', lang),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Subject Marks List
                  if (isConsolidated)
                    if (cons == null || cons.subjects.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        child: Text(
                          'No multi-term subject marks recorded.',
                          style: GoogleFonts.inter(color: Colors.grey),
                        ),
                      )
                    else
                      ...cons.subjects.entries.map((entry) {
                        final subj = entry.value;
                        final isSubjPass = subj.percentage >= 33;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: isSubjPass ? Colors.green.shade50 : Colors.red.shade50,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      subj.grade,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isSubjPass ? Colors.green.shade800 : Colors.red.shade800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      entry.key,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${subj.totalObtained} / ${subj.totalMax}',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isSubjPass ? Colors.black87 : Colors.red.shade800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Term-wise breakdown pills
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: cons.activeTerms.map((term) {
                                  final termScore = subj.terms[term.id];
                                  final shortTerm = term.title
                                      .replaceAll(' Examination', '')
                                      .replaceAll(' 2026', '');
                                  final obtStr = termScore == null
                                      ? '—'
                                      : (termScore.isAbsent ? 'ABS' : '${termScore.obtained ?? '-'}');
                                  final gradeStr = termScore?.grade ?? '-';

                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.purple.shade100),
                                    ),
                                    child: Text(
                                      '$shortTerm: $obtStr ($gradeStr)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.purple.shade900,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        );
                      }).toList()
                  else if (res == null || res.subjectMarks.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      child: Text(
                        'No detailed subject marks recorded.',
                        style: GoogleFonts.inter(color: Colors.grey),
                      ),
                    )
                  else
                    ...res.subjectMarks.entries.map((entry) {
                      final s = entry.value;
                      final isSubjPass = !s.isAbsent && (s.obtained ?? 0) >= s.passingMarks;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: (s.isAbsent
                                    ? Colors.red.shade50
                                    : (isSubjPass ? Colors.green.shade50 : Colors.red.shade50)),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                s.grade,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: s.isAbsent ? Colors.red : (isSubjPass ? Colors.green.shade800 : Colors.red.shade800),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.key,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
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
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: s.isAbsent ? Colors.red : Colors.black87,
                                  ),
                                ),
                                Text(
                                  'Pass: ${s.passingMarks}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Action Button: Download / Share DMC PDF
          Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isGeneratingPdf ? null : _downloadOrSharePdf,
                icon: _isGeneratingPdf
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.picture_as_pdf_rounded, size: 20),
                label: Text(
                  _isGeneratingPdf
                      ? TranslationHelper.translate('Generating DMC PDF...', lang)
                      : TranslationHelper.translate('Download & Share DMC PDF', lang),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeColors.primaryPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _studentMetaCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Text(
          value.isNotEmpty ? value : '-',
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _statBox(String label, String val) {
    return Column(
      children: [
        Text(
          val,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
