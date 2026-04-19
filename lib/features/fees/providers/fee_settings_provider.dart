import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/parent_data_provider.dart';

final feeSettingsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final parentDataAsync = ref.watch(parentDataProvider);
  if (parentDataAsync.value == null) return Stream.value({});
  final schoolId = parentDataAsync.value!.schoolId;
  if (schoolId.isEmpty) return Stream.value({});

  return FirebaseFirestore.instance
      .collection('schools')
      .doc(schoolId)
      .collection('settings')
      .doc('feeSettings')
      .snapshots()
      .map((snap) => snap.data() ?? {});
});
