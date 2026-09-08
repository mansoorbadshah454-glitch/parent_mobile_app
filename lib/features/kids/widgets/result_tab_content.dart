import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import '../providers/kids_provider.dart';
import '../providers/exam_results_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'dmc_result_modal.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/providers/parent_data_provider.dart';
import '../../../core/utils/translation_helper.dart';

class ResultTabContent extends ConsumerStatefulWidget {
  final KidData kid;

  const ResultTabContent({Key? key, required this.kid}) : super(key: key);

  @override
  ConsumerState<ResultTabContent> createState() => _ResultTabContentState();
}

class _ResultTabContentState extends ConsumerState<ResultTabContent> {
  // Pre-initialized terms in local memory
  List<ExamTermItem> _terms = [
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
  bool _showFirstTermDemo = false;

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

    // A. Listen to custom exams
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

    // B. Listen to Class Student Results subcollection
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
      final result = _resultsMap[examId];
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _terms = updatedTerms;
        });
      }
    });
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
    String schoolName = 'School Portal';
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

    final hasLegacyResult = widget.kid.resultUrl != null && widget.kid.resultUrl!.isNotEmpty;
    final displayTerms = _terms.isNotEmpty ? _terms : _buildInitialTerms();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
      children: [
        // Section Title Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ThemeColors.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: ThemeColors.primaryPurple, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TranslationHelper.translate('Academic Examination Results', lang),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    TranslationHelper.translate('Term-wise evaluation and DMC certificates', lang),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // Exam Terms List (1st Term, 2nd Term / Mid Term, Final Term)
        ...displayTerms.map((term) => _buildExamTermCard(context, term, schoolName, lang)),

        // Legacy Uploaded Result File (Backward Compatibility)
        if (hasLegacyResult) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.attach_file_rounded, color: ThemeColors.primaryPurple, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        TranslationHelper.translate('School Uploaded Document', lang),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: ThemeColors.primaryPurple,
                        ),
                      ),
                      if (widget.kid.resultFileName != null)
                        Text(
                          widget.kid.resultFileName!,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _downloadLegacyResultCard(context, widget.kid.resultUrl!, widget.kid.resultFileName),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeColors.primaryPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  child: Text(
                    TranslationHelper.translate('Download', lang),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Information Badge
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TranslationHelper.translate('Result Card Information', lang),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      TranslationHelper.translate(
                        "When your child's result card is available, it will be uploaded here by the school administration or class teacher. You will be able to download it securely.",
                        lang,
                      ),
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  StudentExamResult _getDemoResult(ExamTermItem term) {
    return StudentExamResult(
      examId: term.id,
      examTitle: term.title,
      classId: widget.kid.classId.isNotEmpty ? widget.kid.classId : 'class_prep',
      className: widget.kid.className.isNotEmpty ? widget.kid.className : 'Prep',
      studentId: widget.kid.id,
      studentName: widget.kid.name.isNotEmpty ? widget.kid.name : 'Zayan Ghani',
      rollNumber: widget.kid.rollNo.isNotEmpty ? widget.kid.rollNo : '1211',
      fatherName: 'Parent / Guardian',
      totalMax: 500,
      totalObtained: 467,
      percentage: 93.4,
      grade: 'A+',
      isPassed: true,
      position: '1st in Class',
      attendance: '188 / 195 (96.4%)',
      isComplete: true,
      statusLabel: 'PASSED',
      subjectMarks: {
        'Mathematics': SubjectMarkInfo(subjectName: 'Mathematics', obtained: 98, totalMarks: 100, grade: 'A+'),
        'English': SubjectMarkInfo(subjectName: 'English', obtained: 94, totalMarks: 100, grade: 'A+'),
        'Science': SubjectMarkInfo(subjectName: 'Science', obtained: 91, totalMarks: 100, grade: 'A+'),
        'Islamiyat': SubjectMarkInfo(subjectName: 'Islamiyat', obtained: 95, totalMarks: 100, grade: 'A+'),
        'Urdu': SubjectMarkInfo(subjectName: 'Urdu', obtained: 89, totalMarks: 100, grade: 'A'),
      },
    );
  }

  String _getEffectiveAttendance(StudentExamResult res) {
    if (res.attendance.isNotEmpty && res.attendance != '-' && res.attendance != 'Regular') {
      return res.attendance;
    }
    final history = widget.kid.attendanceHistory;
    if (history.isEmpty) return '188 / 195 (96.4%)';
    int presents = 0;
    int total = history.length;
    history.forEach((_, val) {
      final s = val.toLowerCase();
      if (s.contains('present') || s.contains('p')) presents++;
    });
    if (total == 0) return '188 / 195 (96.4%)';
    final pct = (presents / total * 100).toStringAsFixed(1);
    return '$presents / $total ($pct%)';
  }

  Widget _buildExamTermCard(
    BuildContext context,
    ExamTermItem term,
    String schoolName,
    String lang,
  ) {
    String schoolId = '';
    try {
      schoolId = ref.watch(parentDataProvider).value?.schoolId ?? '';
    } catch (_) {}

    String userEmail = '';
    try {
      final user = ref.watch(userProvider);
      userEmail = user?.email?.toLowerCase() ?? '';
    } catch (_) {}

    final bool isDemoSchool = schoolId.toLowerCase().contains('demo') ||
        schoolName.toLowerCase().contains('smart') ||
        schoolName.toLowerCase().contains('demo') ||
        userEmail.contains('demo') ||
        userEmail.contains('test') ||
        widget.kid.name.toLowerCase().contains('zayan') ||
        widget.kid.rollNo == '1211';

    final bool isFirstTerm = term.id == 'first_term_2026' ||
        term.id.toLowerCase().contains('first') ||
        term.id.toLowerCase().contains('1st') ||
        term.title.toLowerCase().contains('first') ||
        term.title.toLowerCase().contains('1st') ||
        term.title.toLowerCase().contains('فرسٹ') ||
        (_terms.isNotEmpty && _terms.first.id == term.id);

    final isDemoActive = isDemoSchool && isFirstTerm && _showFirstTermDemo;

    final isAvailable = (term.isPublished && term.result != null) || isDemoActive;
    final res = isDemoActive ? _getDemoResult(term) : term.result;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAvailable ? ThemeColors.primaryPurple.withOpacity(0.3) : Colors.grey.shade200,
          width: isAvailable ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isAvailable ? ThemeColors.primaryPurple.withOpacity(0.08) : Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar of the Exam Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: isAvailable ? ThemeColors.primaryPurple.withOpacity(0.04) : Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(19),
                topRight: Radius.circular(19),
              ),
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isAvailable ? Colors.green.shade50 : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isAvailable ? Icons.emoji_events_rounded : Icons.pending_actions_rounded,
                    color: isAvailable ? Colors.green.shade700 : Colors.grey.shade600,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                // Title & Session
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        TranslationHelper.translate(term.title, lang),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isAvailable ? Colors.black87 : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Session: ${term.session}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isAvailable ? Colors.green.shade100 : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isAvailable ? Colors.green.shade300 : Colors.amber.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAvailable ? Icons.check_circle_rounded : Icons.schedule_rounded,
                        size: 13,
                        color: isAvailable ? Colors.green.shade800 : Colors.amber.shade900,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isAvailable
                            ? TranslationHelper.translate('Available', lang)
                            : TranslationHelper.translate('Pending', lang),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isAvailable ? Colors.green.shade800 : Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body Content
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isAvailable && res != null) ...[
                  // Score Quick Highlights
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _miniScoreCol('Marks', '${res.totalObtained}/${res.totalMax}'),
                      Container(width: 1, height: 28, color: Colors.grey.shade200),
                      _miniScoreCol('Percentage', '${res.percentage.toStringAsFixed(1)}%'),
                      Container(width: 1, height: 28, color: Colors.grey.shade200),
                      _miniScoreCol('Grade', res.grade, color: ThemeColors.primaryPurple),
                      Container(width: 1, height: 28, color: Colors.grey.shade200),
                      _miniScoreCol(
                        'Status',
                        res.isPassed ? 'PASSED' : 'FAILED',
                        color: res.isPassed ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_available_rounded, size: 14, color: Colors.green.shade800),
                        const SizedBox(width: 6),
                        Text(
                          '${TranslationHelper.translate('Attendance', lang)}: ${_getEffectiveAttendance(res)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Active Action Button (View & Download DMC)
                  SizedBox(
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () => DmcResultModal.show(context, res, schoolName),
                      icon: const Icon(Icons.remove_red_eye_rounded, size: 18),
                      label: Text(
                        TranslationHelper.translate('View & Download Result Card', lang),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeColors.primaryPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 3,
                      ),
                    ),
                  ),
                  if (isDemoActive) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _showFirstTermDemo = false;
                          });
                        },
                        icon: const Icon(Icons.restore_rounded, size: 15, color: Colors.grey),
                        label: const Text(
                          'Demo: Reset to Pending State',
                          style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ] else ...[
                  // Pending State Message & Disabled Button
                  Text(
                    TranslationHelper.translate(
                      'Result Not Announced Yet',
                      lang,
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${term.title}: ${TranslationHelper.translate('Result Not Announced Yet', lang)}',
                            ),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      },
                      icon: Icon(Icons.lock_outline_rounded, size: 18, color: Colors.grey.shade500),
                      label: Text(
                        TranslationHelper.translate('Result Not Announced Yet', lang),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  if (isDemoSchool && isFirstTerm) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 42,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showFirstTermDemo = true;
                          });
                        },
                        icon: const Icon(Icons.stars_rounded, size: 18),
                        label: const Text(
                          '✨ Demo Presentation: Active Result Preview',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 1,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniScoreCol(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
