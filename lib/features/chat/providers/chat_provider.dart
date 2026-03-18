import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/parent_data_provider.dart';

class MessageModel {
  final String id;
  final String teacherId;
  final String teacherName;
  final String parentId;
  final String studentId;
  final String studentName;
  final String message;
  final String? attachmentUrl;
  final String? attachmentType;
  final DateTime? timestamp;

  MessageModel({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.parentId,
    required this.studentId,
    required this.studentName,
    required this.message,
    this.attachmentUrl,
    this.attachmentType,
    this.timestamp,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      teacherId: map['teacherId'] ?? '',
      teacherName: map['teacherName'] ?? 'Teacher',
      parentId: map['parentId'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? 'Student',
      message: map['message'] ?? '',
      attachmentUrl: map['attachmentUrl'],
      attachmentType: map['attachmentType'],
      timestamp: map['timestamp'] != null 
          ? (map['timestamp'] as Timestamp).toDate() 
          : null,
    );
  }
}

final chatProvider = StreamProvider<List<MessageModel>>((ref) async* {
  final parentDataAsync = ref.watch(parentDataProvider);

  if (parentDataAsync.value == null) {
    yield [];
    return;
  }

  final schoolId = parentDataAsync.value!.schoolId;
  final parentId = parentDataAsync.value!.uid;

  if (schoolId.isEmpty || parentId.isEmpty) {
    yield [];
    return;
  }

  final messagesStream = FirebaseFirestore.instance
      .collection('schools')
      .doc(schoolId)
      .collection('messages')
      .where('parentId', isEqualTo: parentId)
      .snapshots();

  await for (final snapshot in messagesStream) {
    var messages = snapshot.docs.map((doc) => MessageModel.fromMap(doc.data(), doc.id)).toList();
    messages.sort((a, b) {
      if (a.timestamp == null && b.timestamp == null) return 0;
      if (a.timestamp == null) return 1;
      if (b.timestamp == null) return -1;
      return b.timestamp!.compareTo(a.timestamp!);
    });
    yield messages;
  }
});
