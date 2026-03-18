import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';

class ParentData {
  final String uid;
  final String schoolId;
  final String name;
  final String email;
  final String? schoolName;

  ParentData({
    required this.uid,
    required this.schoolId,
    required this.name,
    required this.email,
    this.schoolName,
  });

  factory ParentData.fromMap(Map<String, dynamic> map, String uid, String email, {String? schoolName}) {
    return ParentData(
      uid: uid,
      schoolId: map['schoolId'] ?? '',
      name: map['name'] ?? 'Parent',
      email: email,
      schoolName: schoolName,
    );
  }
}

final parentDataProvider = FutureProvider<ParentData?>((ref) async {
  final user = ref.watch(userProvider);
  if (user == null) return null;

  try {
    final doc = await FirebaseFirestore.instance
        .collection('global_users')
        .doc(user.uid)
        .get();

    if (doc.exists && doc.data()?['role'] == 'parent') {
      final schoolId = doc.data()!['schoolId'] ?? '';
      String? schoolName;
      if (schoolId.isNotEmpty) {
        try {
          final schoolDoc = await FirebaseFirestore.instance
              .collection('schools')
              .doc(schoolId)
              .collection('settings')
              .doc('profile')
              .get();
          if (schoolDoc.exists) {
            schoolName = schoolDoc.data()?['name'];
          }
        } catch (e) {
          print('Error fetching school profile: $e');
        }
      }
      return ParentData.fromMap(doc.data()!, user.uid, user.email ?? '', schoolName: schoolName);
    }
  } catch (e) {
    print('Error fetching parent data: $e');
  }
  return null;
});
