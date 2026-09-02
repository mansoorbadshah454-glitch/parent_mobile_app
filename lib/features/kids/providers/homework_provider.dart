import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/parent_data_provider.dart';

class HomeworkItem {
  final String id;
  final String subject;
  final String chapter;
  final String topic;
  final String description;
  final String assignedDate;
  final String dueDate;
  final DateTime? dueDateTime;
  final String teacherName;
  final String className;
  final String status;
  final DateTime? createdAt;

  HomeworkItem({
    required this.id,
    required this.subject,
    required this.chapter,
    required this.topic,
    required this.description,
    required this.assignedDate,
    required this.dueDate,
    this.dueDateTime,
    required this.teacherName,
    required this.className,
    required this.status,
    this.createdAt,
  });

  factory HomeworkItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    
    DateTime? dueDt;
    if (data['dueDateTime'] is Timestamp) {
      dueDt = (data['dueDateTime'] as Timestamp).toDate();
    } else if (data['dueDate'] != null) {
      dueDt = DateTime.tryParse(data['dueDate'].toString());
    }

    DateTime? created;
    if (data['createdAt'] is Timestamp) {
      created = (data['createdAt'] as Timestamp).toDate();
    } else if (data['updatedAt'] is Timestamp) {
      created = (data['updatedAt'] as Timestamp).toDate();
    }

    return HomeworkItem(
      id: doc.id,
      subject: data['subject']?.toString() ?? 'General',
      chapter: data['chapter']?.toString() ?? '',
      topic: data['topic']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      assignedDate: data['assignedDate']?.toString() ?? '',
      dueDate: data['dueDate']?.toString() ?? '',
      dueDateTime: dueDt,
      teacherName: data['teacherName']?.toString() ?? 'Teacher',
      className: data['className']?.toString() ?? '',
      status: data['status']?.toString() ?? 'active',
      createdAt: created,
    );
  }
}

typedef HomeworkArgs = ({String classId, String className});

final classHomeworkProvider = StreamProvider.family<List<HomeworkItem>, HomeworkArgs>((ref, args) async* {
  final parentData = ref.watch(parentDataProvider).value;
  if (parentData == null || parentData.schoolId.isEmpty) {
    yield [];
    return;
  }

  final schoolId = parentData.schoolId;
  String resolvedClassId = args.classId;

  if (resolvedClassId.isEmpty && args.className.isNotEmpty && args.className != 'N/A') {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('classes')
          .where('name', isEqualTo: args.className)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        resolvedClassId = snap.docs.first.id;
      }
    } catch (e) {
      print("Failed resolving classId for homework: $e");
    }
  }

  if (resolvedClassId.isEmpty) {
    yield [];
    return;
  }

  final homeworkStream = FirebaseFirestore.instance
      .collection('schools')
      .doc(schoolId)
      .collection('classes')
      .doc(resolvedClassId)
      .collection('homework')
      .snapshots();

  await for (final snapshot in homeworkStream) {
    final items = snapshot.docs.map((doc) => HomeworkItem.fromFirestore(doc)).toList();
    // Sort newest assignedDate or createdAt descending
    items.sort((a, b) {
      if (a.createdAt != null && b.createdAt != null) {
        return b.createdAt!.compareTo(a.createdAt!);
      }
      return b.assignedDate.compareTo(a.assignedDate);
    });
    yield items;
  }
});
