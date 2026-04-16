import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/parent_data_provider.dart';


class AcademicPerformanceData {
  final Map<String, double> academicScores;
  final double homeworkAverage;

  AcademicPerformanceData({
    required this.academicScores,
    required this.homeworkAverage,
  });
}

typedef AcademicPerformanceArgs = ({String id, String classId, String className});

final academicPerformanceProvider = StreamProvider.family<AcademicPerformanceData?, AcademicPerformanceArgs>((ref, args) async* {
  final parentDataAsync = ref.watch(parentDataProvider);
  if (parentDataAsync.value == null) {
    yield null;
    return;
  }

  final schoolId = parentDataAsync.value!.schoolId;
  if (schoolId.isEmpty) {
    yield null;
    return;
  }

  String resolvedClassId = args.classId;

  // Fallback: If classId is missing (e.g. for legacy students), resolve it using className
  if (resolvedClassId.isEmpty && args.className != 'N/A') {
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
    } catch (e) {
      print("Failed resolving classId fallback: $e");
    }
  }

  if (resolvedClassId.isEmpty) {
    // Cannot resolve where performance data is located
    yield null;
    return;
  }

  final performanceStream = FirebaseFirestore.instance
      .collection('schools')
      .doc(schoolId)
      .collection('classes')
      .doc(resolvedClassId)
      .collection('students')
      .doc(args.id)
      .snapshots();

  await for (final snapshot in performanceStream) {
    if (!snapshot.exists) {
      yield null;
      continue;
    }

    final data = snapshot.data()!;
    
    // Parse academic scores
    final academicScoresRaw = List<dynamic>.from(data['academicScores'] ?? []);
    Map<String, double> subjectScores = {};
    for (var item in academicScoresRaw) {
      if (item is Map) {
        final subj = item['subject']?.toString() ?? 'Unknown';
        final score = double.tryParse(item['score']?.toString() ?? '0') ?? 0.0;
        subjectScores[subj] = score;
      }
    }

    // Parse homework scores to calculate average
    final homeworkScoresRaw = List<dynamic>.from(data['homeworkScores'] ?? []);
    double totalHw = 0;
    int hwCount = 0;
    for (var item in homeworkScoresRaw) {
      if (item is Map) {
        final score = double.tryParse(item['score']?.toString() ?? '0') ?? 0.0;
        totalHw += score;
        hwCount++;
      }
    }

    double homeworkAverage = hwCount > 0 ? (totalHw / hwCount) : 0.0;

    yield AcademicPerformanceData(
      academicScores: subjectScores,
      homeworkAverage: homeworkAverage,
    );
  }
});
