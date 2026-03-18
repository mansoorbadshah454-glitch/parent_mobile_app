import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/parent_data_provider.dart';

class AlertModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool read;
  final DateTime? createdAt;

  AlertModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.read,
    this.createdAt,
  });

  factory AlertModel.fromMap(Map<String, dynamic> map, String id) {
    return AlertModel(
      id: id,
      title: map['title'] ?? 'Notification',
      message: map['message'] ?? '',
      type: map['type'] ?? 'info',
      read: map['read'] ?? false,
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate() 
          : null,
    );
  }
}

final alertsProvider = StreamProvider<List<AlertModel>>((ref) async* {
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

  final notificationsStream = FirebaseFirestore.instance
      .collection('schools')
      .doc(schoolId)
      .collection('notifications')
      .where('parentId', isEqualTo: parentId)
      .snapshots();

  await for (final snapshot in notificationsStream) {
    var alerts = snapshot.docs.map((doc) => AlertModel.fromMap(doc.data(), doc.id)).toList();
    alerts.sort((a, b) {
      if (a.createdAt == null && b.createdAt == null) return 0;
      if (a.createdAt == null) return 1;
      if (b.createdAt == null) return -1;
      return b.createdAt!.compareTo(a.createdAt!);
    });
    yield alerts;
  }
});
