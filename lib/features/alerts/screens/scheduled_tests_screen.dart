import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../kids/providers/kids_provider.dart';
import '../../../core/providers/parent_data_provider.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/utils/translation_helper.dart';

final scheduledTestsProvider = StreamProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, classId) async* {
  final parentDataAsync = ref.watch(parentDataProvider);
  if (parentDataAsync.value == null) {
    yield [];
    return;
  }
  
  final schoolId = parentDataAsync.value!.schoolId;
  if (schoolId.isEmpty || classId.isEmpty) {
    yield [];
    return;
  }
  
  final stream = FirebaseFirestore.instance
      .collection('schools')
      .doc(schoolId)
      .collection('classes')
      .doc(classId)
      .collection('scheduled_tests')
      .where('status', isEqualTo: 'scheduled')
      .snapshots();
      
  await for (final snap in stream) {
    List<Map<String, dynamic>> tests = [];
    for (var doc in snap.docs) {
      tests.add({
        'id': doc.id,
        ...doc.data(),
      });
    }
    tests.sort((a, b) {
       final aTime = a['createdAt'];
       final bTime = b['createdAt'];
       if (aTime is Timestamp && bTime is Timestamp) {
         return bTime.compareTo(aTime); // newest first
       }
       return 0;
    });
    yield tests;
  }
});

class TestReportArgs {
  final String classId;
  final String studentId;

  TestReportArgs({required this.classId, required this.studentId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestReportArgs &&
          runtimeType == other.runtimeType &&
          classId == other.classId &&
          studentId == other.studentId;

  @override
  int get hashCode => classId.hashCode ^ studentId.hashCode;
}

final testReportsProvider = StreamProvider.autoDispose.family<List<Map<String, dynamic>>, TestReportArgs>((ref, args) async* {
  final parentDataAsync = ref.watch(parentDataProvider);
  if (parentDataAsync.value == null) {
    yield [];
    return;
  }
  
  final schoolId = parentDataAsync.value!.schoolId;
  if (schoolId.isEmpty || args.classId.isEmpty || args.studentId.isEmpty) {
    yield [];
    return;
  }
  
  final stream = FirebaseFirestore.instance
      .collection('schools')
      .doc(schoolId)
      .collection('classes')
      .doc(args.classId)
      .collection('students')
      .doc(args.studentId)
      .collection('testScores')
      .snapshots();
      
  await for (final snap in stream) {
    List<Map<String, dynamic>> reports = [];
    for (var doc in snap.docs) {
      reports.add({
        'id': doc.id,
        ...doc.data(),
      });
    }
    reports.sort((a, b) {
       final aTime = a['createdAt'];
       final bTime = b['createdAt'];
       if (aTime is Timestamp && bTime is Timestamp) {
         return bTime.compareTo(aTime); // newest first
       }
       return 0;
    });
    yield reports;
  }
});

class ScheduledTestsScreen extends ConsumerStatefulWidget {
  final KidData kid;

  const ScheduledTestsScreen({super.key, required this.kid});

  @override
  ConsumerState<ScheduledTestsScreen> createState() => _ScheduledTestsScreenState();
}

class _ScheduledTestsScreenState extends ConsumerState<ScheduledTestsScreen> {
  @override
  Widget build(BuildContext context) {
    final testsAsyncValue = ref.watch(scheduledTestsProvider(widget.kid.classId));
    final reportsAsyncValue = ref.watch(testReportsProvider(TestReportArgs(classId: widget.kid.classId, studentId: widget.kid.id)));
    final lang = ref.watch(languageProvider);
    final isUrdu = lang == 'ur';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: ThemeColors.primaryPurple,
          elevation: 0,
          centerTitle: true,
          title: Text(
            TranslationHelper.translate('Tests', lang),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: TranslationHelper.translate('Scheduled', lang)),
              Tab(text: TranslationHelper.translate('Reports', lang)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildScheduledTestsTab(testsAsyncValue, isUrdu, lang),
            _buildTestReportsTab(reportsAsyncValue, isUrdu, lang),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduledTestsTab(AsyncValue<List<Map<String, dynamic>>> testsAsyncValue, bool isUrdu, String lang) {
    return testsAsyncValue.when(
      data: (tests) {
        if (tests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  TranslationHelper.translate('No tests scheduled currently.', lang),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: tests.length,
          itemBuilder: (context, index) {
            final test = tests[index];
            return _buildTestCard(test, isUrdu, lang);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: ThemeColors.primaryPurple)),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildTestCard(Map<String, dynamic> test, bool isUrdu, String lang) {
    final subject = test['subject'] ?? 'Unknown Subject';
    final testType = test['testType'] ?? 'Written';
    final chapter = test['chapter'] ?? 'N/A';
    final topic = test['paragraphs'] ?? 'N/A';
    final dateStr = test['dateStr'] ?? 'TBD';
    final timeStr = test['timeStr'] ?? 'TBD';
    final maxMarks = test['maxMarks'] ?? 10;
    
    // Parse date for better display if possible
    String displayDate = dateStr;
    try {
      if (dateStr != 'TBD') {
         final dt = DateTime.parse(dateStr);
         displayDate = DateFormat('MMM dd, yyyy').format(dt);
      }
    } catch (_) {}

    final personalizedMessage = "Consistent practice builds confidence. Support ${widget.kid.name} by creating a distraction-free study space for this test!";

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: ThemeColors.primaryPurple,
          collapsedIconColor: ThemeColors.primaryPurple,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ThemeColors.primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.menu_book_rounded, color: ThemeColors.primaryPurple),
          ),
          title: Text(
            TranslationHelper.translate(subject, lang),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          subtitle: Text(
            TranslationHelper.translate('$testType Test', lang),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(Icons.bookmark_border_rounded, 'Chapter', chapter, lang),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.subject_rounded, 'Topic', topic, lang),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.calendar_today_rounded, 'Date', '$displayDate at $timeStr', lang),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.star_border_rounded, 'Max Marks', '$maxMarks', lang),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1),
                  ),
                  
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline_rounded, color: Colors.blueAccent, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            TranslationHelper.translate(personalizedMessage, lang),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue[800],
                              height: 1.4,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, String lang) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                TranslationHelper.translate(label, lang),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                TranslationHelper.translate(value, lang),
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTestReportsTab(AsyncValue<List<Map<String, dynamic>>> reportsAsyncValue, bool isUrdu, String lang) {
    return reportsAsyncValue.when(
      data: (reports) {
        if (reports.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.insert_chart_outlined_rounded, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  TranslationHelper.translate('No test reports available.', lang),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            return _buildReportCard(report, isUrdu, lang);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: ThemeColors.primaryPurple)),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report, bool isUrdu, String lang) {
    final subject = report['subject'] ?? 'Unknown Subject';
    final testType = report['testType'] ?? 'Written';
    final dateStr = report['date'] ?? 'TBD';
    final score = report['score'] ?? 0;
    final maxMarks = report['maxMarks'] ?? 10;
    
    String displayDate = dateStr;
    try {
      if (dateStr != 'TBD') {
         final dt = DateTime.parse(dateStr);
         displayDate = DateFormat('MMM dd, yyyy').format(dt);
      }
    } catch (_) {}

    double percentage = 0.0;
    if (maxMarks > 0) {
      percentage = (score / maxMarks) * 100;
    }

    String message = "Keep learning and practicing!";
    Color messageColor = Colors.blueAccent;
    IconData messageIcon = Icons.info_outline_rounded;
    Color messageBg = Colors.blueAccent.withOpacity(0.05);
    Color messageBorder = Colors.blueAccent.withOpacity(0.2);

    if (percentage >= 90) {
      message = "Outstanding performance! You are excelling brilliantly in this subject.";
      messageColor = Colors.green;
      messageIcon = Icons.star_rounded;
      messageBg = Colors.green.withOpacity(0.05);
      messageBorder = Colors.green.withOpacity(0.2);
    } else if (percentage >= 75) {
      message = "Great job! Keep up the good work and stay focused.";
      messageColor = Colors.teal;
      messageIcon = Icons.thumb_up_rounded;
      messageBg = Colors.teal.withOpacity(0.05);
      messageBorder = Colors.teal.withOpacity(0.2);
    } else if (percentage >= 50) {
      message = "Good effort. Consistent revision will help achieve even better scores.";
      messageColor = Colors.orange;
      messageIcon = Icons.trending_up_rounded;
      messageBg = Colors.orange.withOpacity(0.05);
      messageBorder = Colors.orange.withOpacity(0.2);
    } else {
      message = "Needs improvement. Let's focus on understanding the core concepts more thoroughly.";
      messageColor = Colors.redAccent;
      messageIcon = Icons.warning_amber_rounded;
      messageBg = Colors.redAccent.withOpacity(0.05);
      messageBorder = Colors.redAccent.withOpacity(0.2);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: ThemeColors.primaryPurple,
          collapsedIconColor: ThemeColors.primaryPurple,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ThemeColors.primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.assessment_rounded, color: ThemeColors.primaryPurple),
          ),
          title: Text(
            TranslationHelper.translate(subject, lang),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          subtitle: Text(
            TranslationHelper.translate('$testType Test', lang),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(Icons.calendar_today_rounded, 'Date', displayDate, lang),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.scoreboard_rounded, 'Score', '$score / $maxMarks', lang),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1),
                  ),
                  
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: messageBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: messageBorder),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(messageIcon, color: messageColor, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            TranslationHelper.translate(message, lang),
                            style: TextStyle(
                              fontSize: 14,
                              color: messageColor,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
