import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LikersDialog extends StatelessWidget {
  final List<String> uids;
  final String schoolId;

  const LikersDialog({super.key, required this.uids, required this.schoolId});

  Future<List<Map<String, dynamic>>> _fetchNames() async {
    List<Map<String, dynamic>> likerDetails = [];
    for (String uid in uids) {
      try {
        String finalName = 'Unknown User';
        String role = '';
        String? studentContext;
        bool isParent = false;
        bool found = false;

        // 1. Check Principal / School Admin
        if (!found) {
          try {
            var doc = await FirebaseFirestore.instance.collection('schools').doc(schoolId).collection('users').doc(uid).get();
            if (doc.exists && doc.data() != null) {
              var data = doc.data()!;
              finalName = data['displayName'] ?? data['name'] ?? 'Principal';
              String rawRole = data['role']?.toString().toUpperCase() ?? '';
              role = (rawRole == 'SCHOOL ADMIN' || rawRole == 'ADMIN') ? 'Admin' : 'Principal';
              found = true;
            }
          } catch (e) {}
        }

        // 2. Check Teacher
        if (!found) {
          try {
            var doc = await FirebaseFirestore.instance.collection('schools').doc(schoolId).collection('teachers').doc(uid).get();
            if (doc.exists && doc.data() != null) {
              var data = doc.data()!;
              finalName = data['name'] ?? data['displayName'] ?? 'Teacher';
              role = 'Teacher';
              found = true;
            }
          } catch (e) {}
        }

        // 3. Check Parent
        if (!found) {
          try {
            var doc = await FirebaseFirestore.instance.collection('schools').doc(schoolId).collection('parents').doc(uid).get();
            if (doc.exists && doc.data() != null) {
              var data = doc.data()!;
              finalName = data['parentName'] ?? data['name'] ?? 'Parent';
              role = 'Parent';
              isParent = true;
              found = true;

              try {
                final kidsSnap = await FirebaseFirestore.instance.collectionGroup('students').where('parentDetails.parentId', isEqualTo: uid).limit(1).get();
                if (kidsSnap.docs.isNotEmpty) {
                  var classMap = <String, String>{};
                  try {
                    var classesSnap = await FirebaseFirestore.instance.collection('schools').doc(schoolId).collection('classes').get();
                    for (var c in classesSnap.docs) {
                      classMap[c.id] = c.data()['name'] ?? 'Class';
                    }
                  } catch (e) {}

                  var kidDoc = kidsSnap.docs.first;
                  var kidData = kidDoc.data();
                  String kidName = kidData['name'] ?? '${kidData['firstName'] ?? ''} ${kidData['lastName'] ?? ''}'.trim();
                  var classId = kidDoc.reference.parent.parent?.id;
                  String kidClass = classId != null && classMap.containsKey(classId) ? classMap[classId]! : 'Parent';

                  studentContext = "$kidName's Parent";
                  role = kidClass;
                }
              } catch (e) {}
            }
          } catch (e) {}
        }

        // 4. Fallback to global_users
        if (!found) {
          try {
            var doc = await FirebaseFirestore.instance.collection('global_users').doc(uid).get();
            if (doc.exists && doc.data() != null) {
              var data = doc.data()!;
              finalName = data['name'] ?? data['displayName'] ?? 'Unknown User';
              String roleRaw = data['role']?.toString().toLowerCase() ?? '';
              
              if (roleRaw == 'parent') {
                role = 'Parent';
                isParent = true;
              } else {
                role = roleRaw.isNotEmpty ? '${roleRaw[0].toUpperCase()}${roleRaw.substring(1)}' : 'Teacher';
              }
              found = true;
            }
          } catch (e) {}
        }

        likerDetails.add({
          'name': finalName,
          'studentContext': studentContext,
          'role': role,
          'isParent': isParent,
        });
      } catch (e) {
        likerDetails.add({'name': 'Unknown User', 'role': '', 'isParent': false});
      }
    }
    return likerDetails;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Reaction Details", style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: double.maxFinite,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchNames(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text("Could not load likers.");
            }
            
            final details = snapshot.data!;
            return ListView.separated(
              shrinkWrap: true,
              itemCount: details.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                 final detail = details[index];
                 return Padding(
                   padding: const EdgeInsets.symmetric(vertical: 4),
                   child: Row(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       CircleAvatar(
                         radius: 16,
                         backgroundColor: Theme.of(context).primaryColor,
                         child: const Icon(Icons.person, color: Colors.white, size: 20),
                       ),
                       const SizedBox(width: 8),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(detail['name'] ?? 'Unknown', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                             if (detail['studentContext'] != null || (detail['role'] != null && detail['role'].toString().isNotEmpty)) ...[
                               const SizedBox(height: 2),
                               Row(
                                 children: [
                                   if (detail['studentContext'] != null) ...[
                                     Flexible(
                                       child: Text(detail['studentContext'], style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[700], fontSize: 11), overflow: TextOverflow.ellipsis),
                                     ),
                                     const SizedBox(width: 6),
                                   ],
                                   if (detail['role'] != null && detail['role'].toString().isNotEmpty)
                                     Flexible(
                                       child: Container(
                                         padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                         decoration: BoxDecoration(
                                           color: Theme.of(context).primaryColor.withOpacity(0.1),
                                           borderRadius: BorderRadius.circular(4),
                                         ),
                                         child: Text(
                                           detail['role'],
                                           style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 10) ?? TextStyle(fontSize: 10, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                                           overflow: TextOverflow.ellipsis,
                                         ),
                                       ),
                                     ),
                                 ],
                               ),
                             ],
                           ],
                         ),
                       ),
                     ],
                   ),
                 );
              }
            );
          }
        )
      ),
      actions: [
        TextButton(
           onPressed: () => Navigator.pop(context),
           child: const Text("Close"),
        )
      ],
    );
  }
}
