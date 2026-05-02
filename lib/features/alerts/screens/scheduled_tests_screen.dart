import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../kids/providers/kids_provider.dart';
import '../../../core/providers/parent_data_provider.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/utils/translation_helper.dart';
import '../widgets/scheduled_tests_list.dart';
import '../widgets/test_reports_list.dart';

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
            ScheduledTestsList(
              testsAsyncValue: testsAsyncValue,
              kid: widget.kid,
              isUrdu: isUrdu,
              lang: lang,
            ),
            TestReportsList(
              reportsAsyncValue: reportsAsyncValue,
              kid: widget.kid,
              isUrdu: isUrdu,
              lang: lang,
            ),
          ],
        ),
      ),
    );
  }

}
