import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';

import '../providers/kids_provider.dart';
import '../providers/exam_results_provider.dart';
import '../screens/term_result_details_screen.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/providers/parent_data_provider.dart';
import '../../../core/utils/translation_helper.dart';

class ResultTabContent extends ConsumerStatefulWidget {
  final KidData kid;

  const ResultTabContent({super.key, required this.kid});

  @override
  ConsumerState<ResultTabContent> createState() => _ResultTabContentState();
}

class _ResultTabContentState extends ConsumerState<ResultTabContent> {
  // Pre-initialized standard academic terms in chronological order
  List<ExamTermItem> _terms = [
    ExamTermItem(
      id: 'monthly_test_2026',
      title: 'Monthly Class Test 2026',
      session: '2025-2026',
      description: 'Monthly class evaluation and assessment tests.',
      status: 'active',
      isPublished: false,
    ),
    ExamTermItem(
      id: 'first_term_2026',
      title: 'First Term Examination 2026',
      session: '2025-2026',
      description: 'First comprehensive academic term assessment.',
      status: 'active',
      isPublished: false,
    ),
    ExamTermItem(
      id: 'mid_term_2026',
      title: 'Mid Term Examination 2026',
      session: '2025-2026',
      description: 'Mid-session evaluation test.',
      status: 'active',
      isPublished: false,
    ),
    ExamTermItem(
      id: 'final_term_2026',
      title: 'Annual / Final Examination 2026',
      session: '2025-2026',
      description: 'Final annual comprehensive examination.',
      status: 'active',
      isPublished: false,
    ),
  ];

  StreamSubscription? _resultsSub;
  StreamSubscription? _rootResultsSub;
  StreamSubscription? _examsSub;
  Timer? _retryTimer;
  final Map<String, StudentExamResult> _resultsMap = {};
  List<Map<String, dynamic>> _customExams = [];
  bool _isListening = false;

  // Chronological Sorting:
  // 1st position: Any newly created custom exam / Monthly Class Test
  // Followed chronologically by: First Term -> Mid Term -> Third Term -> Final / Annual Examination
  int _getTermSortOrder(ExamTermItem exam) {
    final text = '${exam.id} ${exam.title}'.toLowerCase();
    if (text.contains('monthly') || text.contains('class test')) return 1;
    if (text.contains('first') || text.contains('1st') || text.contains('term 1') || text.contains('term1')) return 2;
    if (text.contains('mid') || text.contains('second') || text.contains('2nd') || text.contains('term 2') || text.contains('term2') || text.contains('half')) return 3;
    if (text.contains('third') || text.contains('3rd') || text.contains('term 3') || text.contains('term3')) return 4;
    if (text.contains('final') || text.contains('annual') || text.contains('end term')) return 5;
    return 0; // Any newly created custom exam created in the system appears at the top (1st position)
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startListeners();
    });
  }

  @override
  void didUpdateWidget(covariant ResultTabContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kid.id != widget.kid.id || oldWidget.kid.classId != widget.kid.classId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startListeners();
      });
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _resultsSub?.cancel();
    _rootResultsSub?.cancel();
    _examsSub?.cancel();
    super.dispose();
  }

  List<ExamTermItem> _buildInitialTerms() {
    return [
      ExamTermItem(
        id: 'monthly_test_2026',
        title: 'Monthly Class Test 2026',
        session: '2025-2026',
        description: 'Monthly class evaluation and assessment tests.',
        status: 'active',
        isPublished: false,
      ),
      ExamTermItem(
        id: 'first_term_2026',
        title: 'First Term Examination 2026',
        session: '2025-2026',
        description: 'First comprehensive academic term assessment.',
        status: 'active',
        isPublished: false,
      ),
      ExamTermItem(
        id: 'mid_term_2026',
        title: 'Mid Term Examination 2026',
        session: '2025-2026',
        description: 'Mid-session evaluation test.',
        status: 'active',
        isPublished: false,
      ),
      ExamTermItem(
        id: 'final_term_2026',
        title: 'Annual / Final Examination 2026',
        session: '2025-2026',
        description: 'Final annual comprehensive examination.',
        status: 'active',
        isPublished: false,
      ),
    ];
  }

  void _startListeners() {
    if (!mounted) return;
    _resultsSub?.cancel();
    _rootResultsSub?.cancel();
    _examsSub?.cancel();

    String schoolId = '';
    try {
      final parentData = ref.read(parentDataProvider).value;
      schoolId = parentData?.schoolId ?? '';
    } catch (_) {}

    if (schoolId.isEmpty) {
      _retryTimer?.cancel();
      _retryTimer = Timer(const Duration(milliseconds: 600), () {
        if (mounted && !_isListening) _startListeners();
      });
      return;
    }

    _isListening = true;
    final classId = widget.kid.classId;
    final studentId = widget.kid.id;

    // A. Listen to custom exams configured by principal
    try {
      _examsSub = FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('exams')
          .snapshots()
          .listen((snap) {
        if (!mounted) return;
        List<Map<String, dynamic>> exams = [];
        for (var doc in snap.docs) {
          final data = doc.data();
          exams.add({
            'id': doc.id,
            'title': data['title']?.toString() ?? doc.id,
            'session': data['session']?.toString() ?? '2025-2026',
            'description': data['description']?.toString() ?? '',
          });
        }
        _customExams = exams;
        _rebuildTerms();
      }, onError: (_) {});
    } catch (_) {}

    // B. Listen to Class Student Results subcollection (published results)
    if (classId.isNotEmpty) {
      try {
        _resultsSub = FirebaseFirestore.instance
            .collection('schools')
            .doc(schoolId)
            .collection('classes')
            .doc(classId)
            .collection('students')
            .doc(studentId)
            .collection('results')
            .snapshots()
            .listen((snap) {
          if (!mounted) return;
          for (var doc in snap.docs) {
            if (doc.exists && doc.data().isNotEmpty) {
              final res = StudentExamResult.fromMap(doc.data(), doc.id);
              _resultsMap[doc.id] = res;
              if (res.examId.isNotEmpty) _resultsMap[res.examId] = res;
            }
          }
          _rebuildTerms();
        }, onError: (_) {});
      } catch (_) {}
    }

    // C. Listen to Root Student Results subcollection
    try {
      _rootResultsSub = FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('students')
          .doc(studentId)
          .collection('results')
          .snapshots()
          .listen((snap) {
        if (!mounted) return;
        for (var doc in snap.docs) {
          if (doc.exists && doc.data().isNotEmpty) {
            final res = StudentExamResult.fromMap(doc.data(), doc.id);
            _resultsMap[doc.id] = res;
            if (res.examId.isNotEmpty) _resultsMap[res.examId] = res;
          }
        }
        _rebuildTerms();
      }, onError: (_) {});
    } catch (_) {}
  }

  void _rebuildTerms() {
    if (!mounted) return;

    final baseExams = _customExams.isNotEmpty
        ? _customExams
        : defaultExamPresets.map((p) => Map<String, dynamic>.from(p)).toList();

    List<ExamTermItem> updatedTerms = [];

    for (final exam in baseExams) {
      final examId = exam['id']?.toString() ?? '';
      
      // Resilient lookup across direct ID, clean slugs, and titles from Firestore
      StudentExamResult? result = _resultsMap[examId];
      if (result == null) {
        final cleanExamId = examId.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        final examTitleClean = (exam['title']?.toString() ?? '').toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

        for (final entry in _resultsMap.entries) {
          final entryKeyClean = entry.key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
          final resExamIdClean = entry.value.examId.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
          final resTitleClean = entry.value.examTitle.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

          if (entryKeyClean == cleanExamId ||
              resExamIdClean == cleanExamId ||
              (examTitleClean.isNotEmpty && resTitleClean == examTitleClean) ||
              (cleanExamId.isNotEmpty && resExamIdClean.contains(cleanExamId)) ||
              (cleanExamId.isNotEmpty && cleanExamId.contains(resExamIdClean))) {
            result = entry.value;
            break;
          }
        }
      }

      final isPublished = result != null;

      updatedTerms.add(ExamTermItem(
        id: examId,
        title: exam['title']?.toString() ?? 'Exam Term',
        session: exam['session']?.toString() ?? '2025-2026',
        description: exam['description']?.toString() ?? '',
        status: 'active',
        isPublished: isPublished,
        result: result,
      ));
    }

    for (final entry in _resultsMap.entries) {
      if (entry.key == 'annual_aggregate') continue;
      final alreadyAdded = updatedTerms.any(
        (it) => it.id == entry.key || (it.result != null && it.result!.examId == entry.key),
      );
      if (!alreadyAdded) {
        updatedTerms.add(ExamTermItem(
          id: entry.key,
          title: entry.value.examTitle,
          isPublished: true,
          result: entry.value,
        ));
      }
    }

    // Chronological sorting: newly created exams (top) -> Monthly Test -> 1st Term -> Mid Term -> Final
    updatedTerms.sort((a, b) => _getTermSortOrder(a).compareTo(_getTermSortOrder(b)));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _terms = updatedTerms;
        });
      }
    });
  }

  String _getEffectiveAttendance(StudentExamResult? res) {
    if (res != null && res.attendance.isNotEmpty && res.attendance != '-' && res.attendance != 'Regular') {
      return res.attendance;
    }
    final history = widget.kid.attendanceHistory;
    if (history.isEmpty) return '—';
    int presents = 0;
    int total = history.length;
    history.forEach((_, val) {
      final s = val.toLowerCase();
      if (s.contains('present') || s.contains('p')) presents++;
    });
    if (total == 0) return '—';
    final pct = (presents / total * 100).toStringAsFixed(1);
    return '$presents / $total ($pct%)';
  }

  Future<void> _downloadLegacyResultCard(BuildContext context, String urlStr, String? fileName) async {
    if (urlStr.isEmpty) return;

    try {
      final String originalName = fileName ?? 'result_card.pdf';
      final String ext = originalName.contains('.') ? originalName.split('.').last.toLowerCase() : 'pdf';
      final bool isImage = ['jpg', 'jpeg', 'png'].contains(ext);
      final uri = Uri.parse(urlStr);

      if (isImage) {
        final String baseName = originalName.contains('.') ? originalName.substring(0, originalName.lastIndexOf('.')) : originalName;
        final String uniqueName = '${baseName}_${DateTime.now().millisecondsSinceEpoch}.$ext';

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Downloading image to device storage...')),
          );
        }

        await FileDownloader.downloadFile(
          url: urlStr,
          name: uniqueName,
          onDownloadCompleted: (String path) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Image Saved successfully!\n$path'),
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          },
          onDownloadError: (String error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error downloading image: $error')),
              );
            }
          },
        ).timeout(const Duration(seconds: 45), onTimeout: () {
          throw Exception('Download timed out.');
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Opening document in browser...')),
          );
        }
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing file: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String schoolName = 'Smart School Portal';
    String lang = 'en';

    try {
      final parentData = ref.watch(parentDataProvider).value;
      if (parentData?.schoolName != null && parentData!.schoolName!.isNotEmpty) {
        schoolName = parentData.schoolName!;
      }
    } catch (_) {}

    try {
      lang = ref.watch(languageProvider);
    } catch (_) {}

    final displayTerms = _terms.isNotEmpty ? _terms : _buildInitialTerms();

    // Map display terms strictly using real published Firestore data (Zero Mock Data)
    final List<ExamTermItem> effectiveTerms = displayTerms.map((term) {
      final isAvailable = term.isPublished && term.result != null;
      return term.copyWith(isPublished: isAvailable, result: isAvailable ? term.result : null);
    }).toList();

    // Chronological sorting: newly created exams (top) -> Monthly Test -> 1st Term -> Mid Term -> Final
    effectiveTerms.sort((a, b) => _getTermSortOrder(a).compareTo(_getTermSortOrder(b)));

    // Build consolidated 3-in-1 object
    final consolidated = ConsolidatedExamResult.buildFromTerms(
      studentName: widget.kid.name.isNotEmpty ? widget.kid.name : 'Student',
      rollNumber: widget.kid.rollNo.isNotEmpty ? widget.kid.rollNo : 'N/A',
      className: widget.kid.className.isNotEmpty ? widget.kid.className : 'Class',
      session: effectiveTerms.isNotEmpty ? effectiveTerms.first.session : '2025-2026',
      attendance: _getEffectiveAttendance(null),
      terms: effectiveTerms,
      explicitAnnualResult: _resultsMap['annual_aggregate'],
    );

    final hasLegacyResult = widget.kid.resultUrl != null && widget.kid.resultUrl!.isNotEmpty;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      children: [
        // Clean Section Header
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
                  Icons.assignment_turned_in_rounded,
                  color: ThemeColors.primaryPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TranslationHelper.translate('Examination Result Cards', lang),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Session: ${effectiveTerms.isNotEmpty ? effectiveTerms.first.session : '2025-2026'} • Tap to view result',
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

        // List of Examination Terms Cards (with press-to-click effect)
        ...effectiveTerms.map((term) => _buildExamTermCard(
              context: context,
              term: term,
              allTerms: effectiveTerms,
              schoolName: schoolName,
              consolidated: consolidated,
              lang: lang,
            )),

        // Legacy Uploaded File (Backward-compatible attachment)
        if (hasLegacyResult) ...[
          const SizedBox(height: 16),
          _buildLegacyAttachmentCard(context, lang),
        ],

        const SizedBox(height: 24),
      ],
    );
  }

  // --- Examination Term Card with Press-to-Click Ripple Effect ---
  Widget _buildExamTermCard({
    required BuildContext context,
    required ExamTermItem term,
    required List<ExamTermItem> allTerms,
    required String schoolName,
    required ConsolidatedExamResult consolidated,
    required String lang,
  }) {
    final bool isAvailable = term.isPublished && term.result != null;
    final res = term.result;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isAvailable ? ThemeColors.primaryPurple.withOpacity(0.2) : Colors.grey.shade200,
          width: isAvailable ? 1.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isAvailable ? ThemeColors.primaryPurple.withOpacity(0.06) : Colors.black.withOpacity(0.02),
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
          splashColor: ThemeColors.primaryPurple.withOpacity(0.12),
          highlightColor: ThemeColors.primaryPurple.withOpacity(0.06),
          onTap: () {
            if (isAvailable && res != null) {
              // Open dedicated digital result card screen for this particular term
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => TermResultDetailsScreen(
                    kid: widget.kid,
                    term: term,
                    allTerms: allTerms,
                    schoolName: schoolName,
                    result: res,
                    consolidated: consolidated,
                  ),
                ),
              );
            } else {
              // Friendly SnackBar when results are awaiting declaration
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${term.title} results have not been declared yet by the school.',
                          style: GoogleFonts.inter(fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: ThemeColors.deepPurple,
                  duration: const Duration(seconds: 3),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                // Term Icon Bubble
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isAvailable ? ThemeColors.primaryPurple.withOpacity(0.1) : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isAvailable ? Icons.emoji_events_rounded : Icons.pending_actions_rounded,
                    color: isAvailable ? ThemeColors.primaryPurple : Colors.grey.shade500,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 14),

                // Title, Session & Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        TranslationHelper.translate(term.title, lang),
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: isAvailable ? Colors.black87 : Colors.grey.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            'Session: ${term.session}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: isAvailable ? Colors.green.shade50 : Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isAvailable ? Colors.green.shade200 : Colors.amber.shade200,
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isAvailable ? Colors.green.shade600 : Colors.amber.shade700,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isAvailable
                                      ? TranslationHelper.translate('Declared', lang)
                                      : TranslationHelper.translate('Awaiting Declaration', lang),
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isAvailable ? Colors.green.shade800 : Colors.amber.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (isAvailable && res != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          '${res.totalObtained} / ${res.totalMax} • ${res.percentage}% • Grade: ${res.grade}',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: ThemeColors.primaryPurple,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Arrow Action Indicator
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isAvailable ? ThemeColors.primaryPurple.withOpacity(0.08) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: isAvailable ? ThemeColors.primaryPurple : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Legacy Attachment File Card ---
  Widget _buildLegacyAttachmentCard(BuildContext context, String lang) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_file_rounded, color: ThemeColors.primaryPurple, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TranslationHelper.translate('School Uploaded Document', lang),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: ThemeColors.primaryPurple,
                  ),
                ),
                if (widget.kid.resultFileName != null)
                  Text(
                    widget.kid.resultFileName!,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _downloadLegacyResultCard(context, widget.kid.resultUrl!, widget.kid.resultFileName),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeColors.primaryPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: Text(
              TranslationHelper.translate('Download', lang),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
