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
  final String? type;
  final String? senderRole;
  final bool read;

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
    this.type,
    this.senderRole,
    this.read = true,
  });

  bool get isAdminMessage {
    if (type == 'admin-message') return true;
    if (teacherName.toLowerCase() == 'principal' || teacherName.toLowerCase() == 'admin') return true;
    if (senderRole?.toLowerCase() == 'principal' || senderRole?.toLowerCase() == 'admin') return true;
    return false;
  }

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
      type: map['type'],
      senderRole: map['senderRole'],
      read: map['read'] ?? true,
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

final kidChatProvider = StreamProvider.family<List<MessageModel>, String>((ref, studentId) async* {
  final parentDataAsync = ref.watch(parentDataProvider);

  if (parentDataAsync.value == null) {
    yield [];
    return;
  }

  final schoolId = parentDataAsync.value!.schoolId;
  final parentId = parentDataAsync.value!.uid;

  if (schoolId.isEmpty || parentId.isEmpty || studentId.isEmpty) {
    yield [];
    return;
  }

  final messagesStream = FirebaseFirestore.instance
      .collection('schools')
      .doc(schoolId)
      .collection('messages')
      .where('parentId', isEqualTo: parentId)
      .where('studentId', isEqualTo: studentId)
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

class ChatService {
  static Future<void> markAsRead(String schoolId, String studentId, String parentId) async {
    if (schoolId.isEmpty || parentId.isEmpty || studentId.isEmpty) return;
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('messages')
          .where('parentId', isEqualTo: parentId)
          .where('studentId', isEqualTo: studentId)
          .where('read', isEqualTo: false)
          .get();

      if (querySnapshot.docs.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  static Future<void> deleteMessages(String schoolId, List<String> messageIds) async {
    if (schoolId.isEmpty || messageIds.isEmpty) return;
    
    final batch = FirebaseFirestore.instance.batch();
    for (final id in messageIds) {
      final docRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('messages')
          .doc(id);
      batch.delete(docRef);
    }
    
    try {
      await batch.commit();
    } catch (e) {
      print('Error deleting messages: $e');
    }
  }

  static Future<void> clearAllChats(String schoolId, String parentId) async {
    if (schoolId.isEmpty || parentId.isEmpty) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('messages')
          .where('parentId', isEqualTo: parentId)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error clearing all chats: $e');
    }
  }

  static Future<void> markAllParentChatsAsRead(String schoolId, String parentId) async {
    if (schoolId.isEmpty || parentId.isEmpty) return;
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('messages')
          .where('parentId', isEqualTo: parentId)
          .where('read', isEqualTo: false)
          .get();

      if (querySnapshot.docs.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking all parent chats as read: $e');
    }
  }
}

