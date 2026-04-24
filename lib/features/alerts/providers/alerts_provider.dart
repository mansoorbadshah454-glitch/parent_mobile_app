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
  final String? studentId;
  final String? status;

  AlertModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.read,
    this.createdAt,
    this.studentId,
    this.status,
  });

  factory AlertModel.fromMap(Map<String, dynamic> map, String id) {
    return AlertModel(
      id: id,
      title: map['title'] ?? 'Notification',
      message: map['message'] ?? '',
      type: map['type'] ?? 'info',
      read: map['read'] ?? false,
      studentId: map['studentId'],
      status: map['status'],
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate() 
          : (map['createdAt'] != null ? DateTime.tryParse(map['createdAt'].toString()) : null),
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
    final allowedTypes = ['attendance', 'academic', 'performance', 'health', 'behavior', 'hygiene', 'personality', 'celebration', 'alert', 'info', 'result', 'document'];
    
    var alerts = snapshot.docs
        .map((doc) => AlertModel.fromMap(doc.data(), doc.id))
        .where((alert) => allowedTypes.contains(alert.type.toLowerCase()))
        .toList();
        
    alerts.sort((a, b) {
      if (a.createdAt == null && b.createdAt == null) return 0;
      if (a.createdAt == null) return 1;
      if (b.createdAt == null) return -1;
      return b.createdAt!.compareTo(a.createdAt!);
    });
    yield alerts;
  }
});

// A provider to manage marking alerts as read or deleting them
final alertsActionProvider = Provider((ref) {
  return AlertsActionService(ref);
});

class AlertsActionService {
  final Ref ref;
  AlertsActionService(this.ref);

  Future<void> markAsRead(String alertId) async {
    final parentDataAsync = ref.read(parentDataProvider);
    final schoolId = parentDataAsync.value?.schoolId;
    if (schoolId == null || schoolId.isEmpty) return;
    
    try {
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('notifications')
          .doc(alertId)
          .update({'read': true});
    } catch (e) {
      print('Error marking alert read: $e');
    }
  }

  Future<void> deleteAlert(String alertId) async {
    final parentDataAsync = ref.read(parentDataProvider);
    final schoolId = parentDataAsync.value?.schoolId;
    if (schoolId == null || schoolId.isEmpty) return;
    
    try {
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('notifications')
          .doc(alertId)
          .delete();
    } catch (e) {
      print('Error deleting alert: $e');
    }
  }

  Future<void> clearAllAlerts(List<String> alertIds) async {
    final parentDataAsync = ref.read(parentDataProvider);
    final schoolId = parentDataAsync.value?.schoolId;
    if (schoolId == null || schoolId.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (String id in alertIds) {
      final docRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('notifications')
          .doc(id);
      batch.delete(docRef);
    }
    
    try {
      await batch.commit();
    } catch (e) {
      print('Error clearing alerts: $e');
    }
  }

  Future<void> markAllAsReadGlobally() async {
    final parentDataAsync = ref.read(parentDataProvider);
    final schoolId = parentDataAsync.value?.schoolId;
    final parentId = parentDataAsync.value?.uid;
    
    if (schoolId == null || schoolId.isEmpty || parentId == null || parentId.isEmpty) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('notifications')
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
      print('Error marking all alerts as read globally: $e');
    }
  }
}
