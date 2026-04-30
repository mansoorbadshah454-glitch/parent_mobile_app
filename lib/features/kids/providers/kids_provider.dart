import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/parent_data_provider.dart';

class KidData {
  final String id;
  final String name;
  final String imageUrl;
  final String className;
  final String classId;
  final String rollNo;
  final Map<String, int> wellness;
  final Map<String, String> attendanceHistory;
  final String monthlyFeeStatus;
  final String? monthlyFeeDate;
  final String? resultUrl;
  final String? resultFileName;
  final List<Map<String, dynamic>> feeStructure;
  final List<Map<String, dynamic>> individualActions;
  final Map<String, dynamic>? activeLeave;

  KidData({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.className,
    required this.classId,
    required this.rollNo,
    required this.wellness,
    required this.attendanceHistory,
    required this.monthlyFeeStatus,
    this.monthlyFeeDate,
    this.resultUrl,
    this.resultFileName,
    this.feeStructure = const [],
    this.individualActions = const [],
    this.activeLeave,
  });

  factory KidData.fromMap(Map<String, dynamic> map, String id, {String? overrideClassId, String? overrideClassName}) {
      final dynamic wellnessData = map['wellness'];
      final Map<String, dynamic> wellnessMap = wellnessData is Map ? Map<String, dynamic>.from(wellnessData) : <String, dynamic>{};

      List<Map<String, dynamic>> parsedFeeStructure = [];
      if (map['feeStructure'] is List) {
        for (var item in map['feeStructure']) {
          if (item is Map) parsedFeeStructure.add(Map<String, dynamic>.from(item));
        }
      }

      List<Map<String, dynamic>> parsedIndividualActions = [];
      if (map['individualActions'] is List) {
        for (var item in map['individualActions']) {
          if (item is Map) parsedIndividualActions.add(Map<String, dynamic>.from(item));
        }
      }

      Map<String, dynamic>? parsedActiveLeave;
      if (map['activeLeave'] is Map) {
        parsedActiveLeave = Map<String, dynamic>.from(map['activeLeave']);
      }

    return KidData(
      id: id,
      name: map['name'] ?? '${map['firstName'] ?? ''} ${map['lastName'] ?? ''}'.trim(),
      imageUrl: map['profilePic'] ?? map['avatar'] ?? 'https://api.dicebear.com/7.x/avataaars/png?seed=$id',
      className: overrideClassName ?? map['className'] ?? map['class'] ?? 'N/A',
      classId: overrideClassId ?? map['classId']?.toString() ?? '',
      rollNo: map['rollNo']?.toString() ?? map['rollNumber']?.toString() ?? 'N/A',
      wellness: {
        'behavior': int.tryParse(wellnessMap['behavior']?.toString() ?? '80') ?? 80,
        'health': int.tryParse(wellnessMap['health']?.toString() ?? '80') ?? 80,
        'hygiene': int.tryParse(wellnessMap['hygiene']?.toString() ?? '80') ?? 80,
      },
      attendanceHistory: _parseAttendanceSafe(map['attendanceHistory']),
      monthlyFeeStatus: map['monthlyFeeStatus']?.toString() ?? 'unpaid',
      monthlyFeeDate: map['monthlyFeeDate']?.toString(),
      resultUrl: map['resultCardUrl']?.toString() ?? map['uploadedResultUrl']?.toString(),
      resultFileName: map['resultCardName']?.toString() ?? (map['uploadedResultType'] != null ? 'result.${map['uploadedResultType']}' : 'result_card.pdf'),
      feeStructure: parsedFeeStructure,
      individualActions: parsedIndividualActions,
      activeLeave: parsedActiveLeave,
    );
  }

  static Map<String, String> _parseAttendanceSafe(dynamic data) {
    if (data == null) return {};
    if (data is Map) {
      final safeMap = <String, String>{};
      data.forEach((key, value) {
        safeMap[key.toString()] = value.toString();
      });
      return safeMap;
    }
    return {};
  }
}

final kidsProvider = StreamProvider<List<KidData>>((ref) async* {
  final parentDataAsync = ref.watch(parentDataProvider);
  if (parentDataAsync.value == null) {
    yield [];
    return;
  }

  final parentData = parentDataAsync.value!;
  final parentId = parentData.uid;

  if (parentId.isEmpty) {
    yield [];
    return;
  }

  // Fetch class names map to resolve accurate names natively
  Map<String, String> classesMap = {};
  if (parentData.schoolId.isNotEmpty) {
    try {
      final classesSnap = await FirebaseFirestore.instance
          .collection('schools')
          .doc(parentData.schoolId)
          .collection('classes')
          .get();
      for (final doc in classesSnap.docs) {
        classesMap[doc.id] = doc.data()['name']?.toString() ?? 'Class';
      }
    } catch (e) {
      // Ignore
    }
  }

  // Use Collection Group query to find all student records directly from class subcollections
  final studentsStream = FirebaseFirestore.instance
      .collectionGroup('students')
      .where('parentDetails.parentId', isEqualTo: parentId)
      .snapshots();

  await for (final snap in studentsStream) {
    List<KidData> kidsList = [];
    
    for (final doc in snap.docs) {
      // Ensure we only process documents inside a class sub-collection
      // (Ignores duplicated 'master' records at schools/{id}/students)
      if (!doc.reference.path.contains('/classes/')) {
        continue;
      }
      
      final studentData = doc.data();
      
      // Derive accurate classId from the document path
      // schools/{schoolId}/classes/{classId}/students/{studentId}
      final parentCollection = doc.reference.parent; // 'students'
      final classDoc = parentCollection.parent; // '{classId}'
      
      final realClassId = classDoc?.id;
      final realClassName = realClassId != null ? classesMap[realClassId] : null;
      
      kidsList.add(KidData.fromMap(studentData, doc.id, overrideClassId: realClassId, overrideClassName: realClassName));
    }
    
    yield kidsList;
  }
});
