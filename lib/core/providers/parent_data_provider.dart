import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'package:flutter/foundation.dart';

class ParentData {
  final String uid;
  final String schoolId;
  final String name;
  final String email;
  final String? schoolName;
  final String? schoolLogo;

  ParentData({
    required this.uid,
    required this.schoolId,
    required this.name,
    required this.email,
    this.schoolName,
    this.schoolLogo,
  });

  factory ParentData.fromMap(Map<String, dynamic> map, String uid, String email, {String? schoolName, String? schoolLogo}) {
    return ParentData(
      uid: uid,
      schoolId: map['schoolId'] ?? '',
      name: map['name'] ?? 'Parent',
      email: email,
      schoolName: schoolName,
      schoolLogo: schoolLogo,
    );
  }
}

final parentDataProvider = FutureProvider<ParentData?>((ref) async {
  final user = ref.watch(userProvider);
  if (user == null) return null;

  try {
    final prefs = await SharedPreferences.getInstance();
    String? schoolId = prefs.getString('current_school_id');

    // Fallback logic for backward compatibility if needed, but ideally it should use schoolId
    if (schoolId == null || schoolId.isEmpty) {
      final doc = await FirebaseFirestore.instance
          .collection('global_users')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data()?['role'] == 'parent') {
        schoolId = doc.data()?['schoolId'] ?? '';
      }
    }

    if (schoolId == null || schoolId.isEmpty) return null;

    final doc = await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('parents')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      String? schoolName;
      String? schoolLogo;
      if (schoolId.isNotEmpty) {
        try {
          final schoolDoc = await FirebaseFirestore.instance
              .collection('schools')
              .doc(schoolId)
              .collection('settings')
              .doc('profile')
              .get();
          if (schoolDoc.exists) {
            schoolName = schoolDoc.data()?['name'] ?? schoolDoc.data()?['schoolName'];
            schoolLogo = schoolDoc.data()?['profileImage'] ?? schoolDoc.data()?['logo'];
          }
        } catch (e) {
          debugPrint('Error fetching school profile: $e');
        }
      }
      // Adding schoolId to the map manually since it might not be in the parent doc itself
      final mapData = doc.data() ?? {};
      mapData['schoolId'] = schoolId;
      return ParentData.fromMap(mapData, user.uid, user.email ?? '', schoolName: schoolName, schoolLogo: schoolLogo);
    }
  } catch (e) {
    debugPrint('Error fetching parent data: $e');
  }
  return null;
});
