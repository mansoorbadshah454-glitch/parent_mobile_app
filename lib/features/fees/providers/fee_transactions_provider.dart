import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/parent_data_provider.dart';

final studentPaidMonthsProvider = StreamProvider.family<Set<int>, String>((ref, studentId) {
  final parentDataAsync = ref.watch(parentDataProvider);
  final schoolId = parentDataAsync.value?.schoolId ?? '';
  if (schoolId.isEmpty || studentId.isEmpty) {
    return Stream.value(<int>{});
  }

  final currentYear = DateTime.now().year;
  final controller = StreamController<Set<int>>.broadcast();

  final Set<int> txPaidMonths = <int>{};
  final Set<int> subPaidMonths = <int>{};

  void emitCombined() {
    if (!controller.isClosed) {
      controller.add({...txPaidMonths, ...subPaidMonths});
    }
  }

  StreamSubscription? txSub;
  StreamSubscription? subSub;

  try {
    // 1. Listen to fee transactions for student
    final txQuery = FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('feeTransactions')
        .where('studentId', isEqualTo: studentId);

    txSub = txQuery.snapshots().listen((snap) {
      txPaidMonths.clear();
      for (final doc in snap.docs) {
        final data = doc.data();
        final month = _extractMonth(data, currentYear);
        if (month != null) {
          txPaidMonths.add(month);
        }
      }
      emitCombined();
    }, onError: (_) {
      // Defensive fallback: proceed without breaking
      emitCombined();
    });

    // 2. Listen to approved payment submissions for student
    final subQuery = FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('paymentSubmissions')
        .where('studentId', isEqualTo: studentId)
        .where('status', isEqualTo: 'approved');

    subSub = subQuery.snapshots().listen((snap) {
      subPaidMonths.clear();
      for (final doc in snap.docs) {
        final data = doc.data();
        final month = _extractMonth(data, currentYear);
        if (month != null) {
          subPaidMonths.add(month);
        }
      }
      emitCombined();
    }, onError: (_) {
      // Defensive fallback
      emitCombined();
    });
  } catch (_) {
    emitCombined();
  }

  ref.onDispose(() {
    txSub?.cancel();
    subSub?.cancel();
    controller.close();
  });

  return controller.stream;
});

int? _extractMonth(Map<String, dynamic> data, int currentYear) {
  // 1. Explicit month string, e.g. "September 2026", "Sep 2026", "2026-09"
  final monthStr = data['month']?.toString() ?? '';
  if (monthStr.isNotEmpty) {
    final yearMatch = RegExp(r'\b(20\d\d)\b').firstMatch(monthStr);
    if (yearMatch != null) {
      final parsedYear = int.tryParse(yearMatch.group(1)!);
      if (parsedYear != null && parsedYear != currentYear) {
        return null; // For a different year
      }
    }
    final parsed = _parseMonthNameToNumber(monthStr);
    if (parsed != null) return parsed;
  }

  // 2. Check items array: e.g. "Online Fee Payment (September 2026)"
  if (data['items'] is List) {
    for (final item in data['items']) {
      if (item is Map) {
        final name = item['name']?.toString() ?? '';
        final parsed = _parseMonthNameToNumber(name);
        if (parsed != null) return parsed;
      }
    }
  }

  // 3. Fallback to timestamp / date
  final dynamic ts = data['timestamp'];
  if (ts is Timestamp) {
    final dt = ts.toDate();
    if (dt.year == currentYear) return dt.month;
  }

  final dynamic approvedAt = data['approvedAt'] ?? data['submittedAt'] ?? data['dateIso'];
  if (approvedAt != null) {
    final dt = DateTime.tryParse(approvedAt.toString())?.toLocal();
    if (dt != null && dt.year == currentYear) return dt.month;
  }

  return null;
}

int? _parseMonthNameToNumber(String str) {
  final s = str.toLowerCase();
  if (s.contains('jan')) return 1;
  if (s.contains('feb')) return 2;
  if (s.contains('mar')) return 3;
  if (s.contains('apr')) return 4;
  if (s.contains('may')) return 5;
  if (s.contains('jun')) return 6;
  if (s.contains('jul')) return 7;
  if (s.contains('aug')) return 8;
  if (s.contains('sep')) return 9;
  if (s.contains('oct')) return 10;
  if (s.contains('nov')) return 11;
  if (s.contains('dec')) return 12;

  // Pattern like 2026-09 or 2026-9
  final isoMatch = RegExp(r'20\d\d[-/](\d{1,2})').firstMatch(s);
  if (isoMatch != null) {
    final m = int.tryParse(isoMatch.group(1)!);
    if (m != null && m >= 1 && m <= 12) return m;
  }

  return null;
}
