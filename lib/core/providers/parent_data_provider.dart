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
  final String? phone;
  final String? address;
  final String? occupation;
  final String? cnic;
  final String? photoUrl;
  final String? schoolName;
  final String? schoolLogo;
  final bool isTransportEnabled;
  final String package;

  ParentData({
    required this.uid,
    required this.schoolId,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.occupation,
    this.cnic,
    this.photoUrl,
    this.schoolName,
    this.schoolLogo,
    this.isTransportEnabled = false,
    this.package = 'standard',
  });

  factory ParentData.fromMap(
    Map<String, dynamic> map,
    String uid,
    String email, {
    String? schoolName,
    String? schoolLogo,
    bool isTransportEnabled = false,
    String package = 'standard',
  }) {
    return ParentData(
      uid: uid,
      schoolId: map['schoolId'] ?? '',
      name: map['name'] ?? 'Parent',
      email: (map['email']?.toString().isNotEmpty == true) ? map['email'].toString() : email,
      phone: map['phone']?.toString() ?? map['contact']?.toString() ?? map['phoneNumber']?.toString(),
      address: map['address']?.toString() ?? map['residentialAddress']?.toString(),
      occupation: map['occupation']?.toString(),
      cnic: map['cnic']?.toString(),
      photoUrl: map['photoUrl']?.toString() ?? map['profileImage']?.toString(),
      schoolName: schoolName,
      schoolLogo: schoolLogo,
      isTransportEnabled: isTransportEnabled,
      package: package,
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
      bool isTransportEnabled = false;
      String schoolPkg = 'standard';

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

          // Fetch school root document for SaaS package and modules
          final schoolRootDoc = await FirebaseFirestore.instance
              .collection('schools')
              .doc(schoolId)
              .get();
          if (schoolRootDoc.exists) {
            final sData = schoolRootDoc.data() ?? {};
            schoolPkg = sData['package']?.toString() ?? 'standard';
            Map<String, dynamic> modules = {};
            if (sData['modules'] is Map) {
              modules = Map<String, dynamic>.from(sData['modules'] as Map);
            }
            isTransportEnabled = (schoolPkg == 'premium') || (modules['transport'] == true);
          }
        } catch (e) {
          debugPrint('Error fetching school profile or package: $e');
        }
      }
      // Adding schoolId to the map manually since it might not be in the parent doc itself
      final mapData = doc.data() ?? {};
      mapData['schoolId'] = schoolId;
      return ParentData.fromMap(
        mapData,
        user.uid,
        user.email ?? '',
        schoolName: schoolName,
        schoolLogo: schoolLogo,
        isTransportEnabled: isTransportEnabled,
        package: schoolPkg,
      );
    }
  } catch (e) {
    debugPrint('Error fetching parent data: $e');
  }
  return null;
});
