import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/parent_data_provider.dart';

typedef SyllabusArgs = ({String classId, String className});

// Provider 1: Fetches the list of subjects for a given class once
final classSubjectsProvider = FutureProvider.family<List<String>, SyllabusArgs>((ref, args) async {
  final parentDataAsync = ref.watch(parentDataProvider);
  if (parentDataAsync.value == null) {
    return [];
  }

  final schoolId = parentDataAsync.value!.schoolId;
  if (schoolId.isEmpty) {
    return [];
  }

  // Fetch unique subjects for this class from the master timetable
  Set<String> classSubjects = {};
  try {
    final masterTimetableRef = FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('timetables')
        .doc('weeklyMaster');
    final masterSnap = await masterTimetableRef.get();

    if (masterSnap.exists) {
      final data = masterSnap.data()!;
      final rows = data['rows'] as List<dynamic>? ?? [];
      for (var row in rows) {
        final cells = row['cells'] as List<dynamic>? ?? [];
        for (var cell in cells) {
          final cellClass = cell['class']?.toString() ?? '';
          final cellSubject = cell['subject']?.toString() ?? '';
          if (cellClass == args.className && cellSubject.isNotEmpty) {
            classSubjects.add(cellSubject);
          }
        }
      }
    }
  } catch (e) {
    print("Failed fetching timetable subjects: $e");
  }

  // Fallback subjects if timetable is empty or not found for this class
  if (classSubjects.isEmpty) {
    classSubjects.addAll([
      'English', 'Urdu', 'Mathematics', 'Science', 
      'Islamiyat', 'Social Study', 'Computer'
    ]);
  }

  final sortedList = classSubjects.toList();
  sortedList.sort((a, b) => a.compareTo(b));
  
  return sortedList;
});

typedef SubjectChaptersArgs = ({String classId, String className, String subject});

// Provider 2: Gets the chapters for a specific subject
final subjectChaptersProvider = FutureProvider.family<List<Map<String, dynamic>>, SubjectChaptersArgs>((ref, args) async {
  final parentDataAsync = ref.watch(parentDataProvider);
  if (parentDataAsync.value == null) {
    return [];
  }

  final schoolId = parentDataAsync.value!.schoolId;
  if (schoolId.isEmpty) {
    return [];
  }

  String resolvedClassId = args.classId;

  // Resolve classId if missing
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
      print("Failed resolving classId: $e");
    }
  }

  if (resolvedClassId.isEmpty) {
    return [];
  }

  final snapshot = await FirebaseFirestore.instance
      .collection('schools')
      .doc(schoolId)
      .collection('classes')
      .doc(resolvedClassId)
      .collection('syllabus')
      .doc(args.subject)
      .collection('chapters')
      .where('status', isEqualTo: 'In Progress')
      .get();
      
  return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
});
