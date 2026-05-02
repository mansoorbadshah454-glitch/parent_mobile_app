import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  Widget build(BuildContext context) {
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
            return _buildTestCard(context, test);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: ThemeColors.primaryPurple)),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildTestCard(BuildContext context, Map<String, dynamic> test) {
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

    final personalizedMessage = "Consistent practice builds confidence. Support ${kid.name} by creating a distraction-free study space for this test!";

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
                  _buildDetailRow(Icons.bookmark_border_rounded, 'Chapter', chapter),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.subject_rounded, 'Topic', topic),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.calendar_today_rounded, 'Date', '$displayDate at $timeStr'),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.star_border_rounded, 'Max Marks', '$maxMarks'),
                  
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
                            style: TranslationHelper.getTextStyle(
                              lang,
                              fontSize: 14,
                              color: Colors.blue[800],
                              height: 1.4,
                            ).copyWith(fontStyle: isUrdu ? FontStyle.normal : FontStyle.italic),
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
}
