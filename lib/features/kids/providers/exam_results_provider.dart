import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/parent_data_provider.dart';

class SubjectMarkInfo {
  final String subjectName;
  final num? obtained;
  final num totalMarks;
  final num passingMarks;
  final String grade;
  final String remarks;
  final bool isAbsent;

  SubjectMarkInfo({
    required this.subjectName,
    this.obtained,
    this.totalMarks = 100,
    this.passingMarks = 33,
    this.grade = '-',
    this.remarks = '',
    this.isAbsent = false,
  });

  factory SubjectMarkInfo.fromMap(String subject, Map<String, dynamic> map) {
    num? obtainedNum;
    final rawObt = map['obtained'];
    if (rawObt != null && rawObt.toString().isNotEmpty && rawObt.toString() != 'null') {
      obtainedNum = num.tryParse(rawObt.toString());
    }

    return SubjectMarkInfo(
      subjectName: subject,
      obtained: obtainedNum,
      totalMarks: num.tryParse(map['totalMarks']?.toString() ?? '100') ?? 100,
      passingMarks: num.tryParse(map['passingMarks']?.toString() ?? '33') ?? 33,
      grade: map['grade']?.toString() ?? '-',
      remarks: map['remarks']?.toString() ?? '',
      isAbsent: map['isAbsent'] == true,
    );
  }
}

class StudentExamResult {
  final String examId;
  final String examTitle;
  final String classId;
  final String className;
  final String studentId;
  final String studentName;
  final String rollNumber;
  final String fatherName;
  final num totalObtained;
  final num totalMax;
  final num percentage;
  final String grade;
  final String position;
  final String attendance;
  final bool isComplete;
  final bool isPassed;
  final String statusLabel;
  final Map<String, SubjectMarkInfo> subjectMarks;
  final DateTime? publishedAt;

  StudentExamResult({
    required this.examId,
    required this.examTitle,
    required this.classId,
    required this.className,
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
    required this.fatherName,
    required this.totalObtained,
    required this.totalMax,
    required this.percentage,
    required this.grade,
    required this.position,
    required this.attendance,
    required this.isComplete,
    required this.isPassed,
    required this.statusLabel,
    required this.subjectMarks,
    this.publishedAt,
  });

  factory StudentExamResult.fromMap(Map<String, dynamic> map, String id) {
    Map<String, SubjectMarkInfo> parsedSubjects = {};
    if (map['subjectMarks'] is Map) {
      final subMap = Map<String, dynamic>.from(map['subjectMarks'] as Map);
      subMap.forEach((key, val) {
        if (val is Map) {
          parsedSubjects[key] = SubjectMarkInfo.fromMap(key, Map<String, dynamic>.from(val));
        }
      });
    }

    DateTime? publishedDate;
    final pubAt = map['publishedAt'] ?? map['updatedAt'];
    if (pubAt is Timestamp) {
      publishedDate = pubAt.toDate();
    } else if (pubAt is String) {
      publishedDate = DateTime.tryParse(pubAt);
    }

    return StudentExamResult(
      examId: map['examId']?.toString() ?? id,
      examTitle: map['examTitle']?.toString() ?? 'Exam Result',
      classId: map['classId']?.toString() ?? '',
      className: map['className']?.toString() ?? '',
      studentId: map['studentId']?.toString() ?? '',
      studentName: map['studentName']?.toString() ?? '',
      rollNumber: map['rollNumber']?.toString() ?? '',
      fatherName: map['fatherName']?.toString() ?? '',
      totalObtained: num.tryParse(map['totalObtained']?.toString() ?? '0') ?? 0,
      totalMax: num.tryParse(map['totalMax']?.toString() ?? '0') ?? 0,
      percentage: num.tryParse(map['percentage']?.toString() ?? '0') ?? 0,
      grade: map['grade']?.toString() ?? '-',
      position: map['position']?.toString() ?? '-',
      attendance: (map['attendance'] != null && map['attendance'].toString().isNotEmpty)
          ? map['attendance'].toString()
          : (map['attendanceDays'] != null
              ? "${map['attendanceDays']} (${map['attendancePercentage'] ?? map['attendancePercent'] ?? ''})"
              : ''),
      isComplete: map['isComplete'] == true,
      isPassed: map['isPassed'] == true,
      statusLabel: map['statusLabel']?.toString() ?? (map['isPassed'] == true ? 'PASSED' : 'FAILED'),
      subjectMarks: parsedSubjects,
      publishedAt: publishedDate,
    );
  }
}

class ExamTermItem {
  final String id;
  final String title;
  final String session;
  final String description;
  final String status; // 'active', 'upcoming', 'completed'
  final bool isPublished;
  final StudentExamResult? result;

  ExamTermItem({
    required this.id,
    required this.title,
    this.session = '2025-2026',
    this.description = '',
    this.status = 'active',
    this.isPublished = false,
    this.result,
  });
}

// Fallback standard presets if no exams are configured in school DB
final List<Map<String, String>> defaultExamPresets = [
  {
    'id': 'first_term_2026',
    'title': 'First Term Examination 2026',
    'session': '2025-2026',
    'description': 'First comprehensive academic term assessment.',
  },
  {
    'id': 'mid_term_2026',
    'title': 'Mid Term Examination 2026',
    'session': '2025-2026',
    'description': 'Mid-session evaluation test.',
  },
  {
    'id': 'final_term_2026',
    'title': 'Annual / Final Examination 2026',
    'session': '2025-2026',
    'description': 'Final annual comprehensive examination.',
  },
];

typedef StudentExamArgs = ({String studentId, String classId, String className});

final studentExamTermsProvider = StreamProvider.family<List<ExamTermItem>, StudentExamArgs>((ref, args) async* {
  // Synchronously watch parentDataProvider AT TOP OF FUNCTION (Riverpod requirement)
  final parentDataAsync = ref.watch(parentDataProvider);

  final defaultItems = defaultExamPresets
      .map((p) => ExamTermItem(
            id: p['id']!,
            title: p['title']!,
            session: p['session'] ?? '2025-2026',
            description: p['description'] ?? '',
            status: 'active',
            isPublished: false,
          ))
      .toList();

  final parentData = parentDataAsync.value;
  if (parentData == null || parentData.schoolId.isEmpty) {
    yield defaultItems;
    return;
  }

  final schoolId = parentData.schoolId;
  String resolvedClassId = args.classId;

  // Resolve classId fallback if needed
  if (resolvedClassId.isEmpty && args.className.isNotEmpty && args.className != 'N/A') {
    try {
      final classesSnap = await FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('classes')
          .where('name', isEqualTo: args.className)
          .limit(1)
          .get();
      if (classesSnap.docs.isNotEmpty) {
        resolvedClassId = classesSnap.docs.first.id;
      }
    } catch (_) {}
  }

  // Fetch School Exams
  List<Map<String, dynamic>> schoolExams = [];
  try {
    final examsSnap = await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('exams')
        .get();
    for (final doc in examsSnap.docs) {
      final data = doc.data();
      schoolExams.add({
        'id': doc.id,
        'title': data['title']?.toString() ?? doc.id,
        'session': data['session']?.toString() ?? '2025-2026',
        'description': data['description']?.toString() ?? '',
        'status': data['status']?.toString() ?? 'active',
      });
    }
  } catch (_) {}

  if (schoolExams.isEmpty) {
    schoolExams = defaultExamPresets.map((p) => Map<String, dynamic>.from(p)).toList();
  }

  // Stream results subcollection
  Stream<QuerySnapshot<Map<String, dynamic>>> resultsStream;
  if (resolvedClassId.isNotEmpty) {
    resultsStream = FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .doc(resolvedClassId)
        .collection('students')
        .doc(args.studentId)
        .collection('results')
        .snapshots();
  } else {
    resultsStream = FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('students')
        .doc(args.studentId)
        .collection('results')
        .snapshots();
  }

  await for (final resultsSnap in resultsStream) {
    try {
      Map<String, StudentExamResult> studentResultsMap = {};
      for (final doc in resultsSnap.docs) {
        if (doc.exists && doc.data().isNotEmpty) {
          final res = StudentExamResult.fromMap(doc.data(), doc.id);
          studentResultsMap[doc.id] = res;
          if (res.examId.isNotEmpty) {
            studentResultsMap[res.examId] = res;
          }
        }
      }

      // Also check fallback root student subcollection if class query returned 0
      if (studentResultsMap.isEmpty && resolvedClassId.isNotEmpty) {
        try {
          final rootSnap = await FirebaseFirestore.instance
              .collection('schools')
              .doc(schoolId)
              .collection('students')
              .doc(args.studentId)
              .collection('results')
              .get();
          for (final doc in rootSnap.docs) {
            if (doc.exists && doc.data().isNotEmpty) {
              final res = StudentExamResult.fromMap(doc.data(), doc.id);
              studentResultsMap[doc.id] = res;
              if (res.examId.isNotEmpty) {
                studentResultsMap[res.examId] = res;
              }
            }
          }
        } catch (_) {}
      }

      // Build unified terms list
      List<ExamTermItem> items = [];
      for (final exam in schoolExams) {
        final examId = exam['id']?.toString() ?? '';
        final result = studentResultsMap[examId];
        final isPublished = result != null;

        items.add(ExamTermItem(
          id: examId,
          title: exam['title']?.toString() ?? 'Exam Term',
          session: exam['session']?.toString() ?? '2025-2026',
          description: exam['description']?.toString() ?? '',
          status: exam['status']?.toString() ?? 'active',
          isPublished: isPublished,
          result: result,
        ));
      }

      // Also append any published results that were uploaded under a custom ID not in schoolExams list
      for (final entry in studentResultsMap.entries) {
        final alreadyPresent = items.any((it) => it.id == entry.key || (it.result != null && it.result!.examId == entry.key));
        if (!alreadyPresent) {
          items.add(ExamTermItem(
            id: entry.key,
            title: entry.value.examTitle,
            isPublished: true,
            result: entry.value,
          ));
        }
      }

      yield items;
    } catch (err) {
      yield defaultItems;
    }
  }
});
