import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../kids/providers/kids_provider.dart';
import '../../../core/providers/parent_data_provider.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            return _buildReportCard(context, ref, report);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: ThemeColors.primaryPurple)),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildReportCard(BuildContext context, WidgetRef ref, Map<String, dynamic> report) {
    final subject = report['subject'] ?? 'Unknown Subject';
    final testType = report['testType'] ?? 'Written';
    final chapter = report['chapter'] ?? 'N/A';
    final topic = report['paragraphs'] ?? 'N/A';
    final dateStr = report['date'] ?? 'TBD';
    final score = report['score'] ?? 0;
    final maxMarks = report['maxMarks'] ?? 10;
    final reportId = report['id'];
    
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
                  _buildDetailRow(Icons.menu_book_rounded, 'Chapter', chapter),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.subject_rounded, 'Topic', topic),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.calendar_today_rounded, 'Date', displayDate),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.scoreboard_rounded, 'Score', '$score / $maxMarks'),
                  
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

                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _confirmDeleteReport(context, ref, reportId),
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      label: Text(
                        TranslationHelper.translate('Delete Report', lang),
                        style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        backgroundColor: Colors.redAccent.withOpacity(0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
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

  void _confirmDeleteReport(BuildContext context, WidgetRef ref, String? reportId) {
    if (reportId == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          TranslationHelper.translate('Delete Report', lang),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
        ),
        content: Text(
          TranslationHelper.translate('Are you sure you want to delete this test report? This action cannot be undone.', lang),
          style: const TextStyle(fontSize: 15),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              TranslationHelper.translate('Cancel', lang),
              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteReport(context, ref, reportId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              TranslationHelper.translate('Delete', lang),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReport(BuildContext context, WidgetRef ref, String reportId) async {
    try {
      final parentDataAsync = ref.read(parentDataProvider);
      final schoolId = parentDataAsync.value?.schoolId;
      if (schoolId == null || schoolId.isEmpty) return;

      await FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('classes')
          .doc(kid.classId)
          .collection('students')
          .doc(kid.id)
          .collection('testScores')
          .doc(reportId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationHelper.translate('Test report deleted successfully', lang)),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationHelper.translate('Failed to delete report', lang)),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
