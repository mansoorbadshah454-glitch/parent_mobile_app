import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/parent_data_provider.dart';

class KidData {
  final String id;
  final String name;
  final String imageUrl;
  final String className;
  final String rollNo;

  KidData({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.className,
    required this.rollNo,
  });

  factory KidData.fromMap(Map<String, dynamic> map, String id) {
    return KidData(
      id: id,
      name: map['name'] ?? '${map['firstName'] ?? ''} ${map['lastName'] ?? ''}'.trim(),
      imageUrl: map['profilePic'] ?? map['avatar'] ?? 'https://api.dicebear.com/7.x/avataaars/svg?seed=$id',
      className: map['className'] ?? map['class'] ?? 'N/A',
      rollNo: map['rollNo']?.toString() ?? map['rollNumber']?.toString() ?? 'N/A',
    );
  }
}

final kidsProvider = StreamProvider<List<KidData>>((ref) async* {
  final parentDataAsync = ref.watch(parentDataProvider);
  if (parentDataAsync.value == null) {
    yield [];
    return;
  }

  final parentData = parentDataAsync.value!;
  final schoolId = parentData.schoolId;
  final parentId = parentData.uid;

  if (schoolId.isEmpty || parentId.isEmpty) {
    yield [];
    return;
  }

  final parentDocStream = FirebaseFirestore.instance
      .collection('schools')
      .doc(schoolId)
      .collection('parents')
      .doc(parentId)
      .snapshots();

  await for (final parentSnap in parentDocStream) {
    if (!parentSnap.exists) {
      yield [];
      continue;
    }

    final data = parentSnap.data()!;
    final linkedStudents = data['linkedStudents'] ?? data['children'] ?? [];
    
    if (linkedStudents.isEmpty) {
      yield [];
      continue;
    }

    List<KidData> kidsList = [];
    for (final link in linkedStudents) {
      final studentId = link is String ? link : link['studentId'];
      if (studentId == null) continue;

      final studentDoc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('students')
          .doc(studentId)
          .get();

      if (studentDoc.exists) {
        kidsList.add(KidData.fromMap(studentDoc.data()!, studentId));
      }
    }
    yield kidsList;
  }
});
