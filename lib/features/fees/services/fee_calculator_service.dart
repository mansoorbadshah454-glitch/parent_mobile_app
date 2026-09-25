import 'package:flutter/material.dart';
import '../../kids/providers/kids_provider.dart';

class ItemizedFeeBreakdown {
  final bool is100PercentFree;
  final double baseTuition;
  final double discountAmount;
  final double tuitionPayable;
  final double transportFee;
  final double storeDues;
  final double actionFee;
  final double penaltyFine;
  final double totalPayable;
  final double paidAmount;
  final double remainingBalance;
  final bool isPaid;
  final bool isPending;
  final String? receiptNo;
  final String? paymentMode;
  final DateTime? paymentDate;
  final String targetMonthKey;
  final String targetMonthName;
  final List<Map<String, dynamic>> recurringItems;
  final List<Map<String, dynamic>> storeItems;
  final List<Map<String, dynamic>> customItems;

  const ItemizedFeeBreakdown({
    required this.is100PercentFree,
    required this.baseTuition,
    required this.discountAmount,
    required this.tuitionPayable,
    required this.transportFee,
    required this.storeDues,
    required this.actionFee,
    required this.penaltyFine,
    required this.totalPayable,
    required this.paidAmount,
    required this.remainingBalance,
    required this.isPaid,
    this.isPending = false,
    this.receiptNo,
    this.paymentMode,
    this.paymentDate,
    required this.targetMonthKey,
    required this.targetMonthName,
    this.recurringItems = const [],
    this.storeItems = const [],
    this.customItems = const [],
  });

  bool get isFullScholarship => is100PercentFree;
  String get status => isPaid ? 'paid' : (isPending ? 'pending' : 'unpaid');
  double get tuitionFee => baseTuition;
  double get grossBill => baseTuition + transportFee + storeDues + actionFee + penaltyFine;
  List<Map<String, dynamic>> get otherRecurringFees => recurringItems;
  List<Map<String, dynamic>> get actions => customItems;
  bool get fineWaived => penaltyFine == 0;
  String get concessionName => is100PercentFree ? '100% Scholarship' : (discountAmount > 0 ? 'Discount / Concession' : '');
  String get monthKey => targetMonthName;
}

class FeeCalculatorService {
  static const List<String> monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  static const List<String> monthShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  /// Safely parses dynamic or string values to double, preventing type cast runtime crashes
  static double parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString().trim()) ?? 0.0;
  }

  /// Check whether a student has 100% Free / Full Scholarship concession.
  static bool checkIs100PercentFree(KidData kid) {
    if (kid.isScholarship || kid.isFreeShip || (kid.concessionType?.toLowerCase() == 'free')) {
      return true;
    }
    final disc = parseDouble(kid.feeDiscount);
    if (disc == 100) return true;

    if (kid.feeStructure.isNotEmpty && kid.feeStructure.every((f) => parseDouble(f['amount']) == 0)) {
      return true;
    }
    return false;
  }

  /// Universal check if a specific month is settled/paid for a student
  static bool isMonthSettled(KidData kid, int monthIdx, int year) {
    if (checkIs100PercentFree(kid)) return true;

    final String monthKeyFormatted = '$year-${(monthIdx + 1).toString().padLeft(2, '0')}';
    final String targetMonthName = monthNames[monthIdx];
    final String targetMonthShort = monthShort[monthIdx];

    // 1. Check monthlyFeeHistory with both "YYYY-MM" and "Month YYYY" keys
    final hist = kid.monthlyFeeHistory[monthKeyFormatted] ?? 
                 kid.monthlyFeeHistory['$targetMonthName $year'] ?? 
                 kid.monthlyFeeHistory['$targetMonthShort $year'];
    if (hist != null && hist is Map) {
      final st = hist['status']?.toString().toLowerCase();
      if (st == 'paid' || st == 'cleared') return true;
      final paid = parseDouble(hist['paidAmount']);
      final remaining = hist['remainingBalance'] != null ? parseDouble(hist['remainingBalance']) : null;
      if (remaining != null && remaining == 0 && paid > 0) return true;
      final expected = parseDouble(hist['expectedAmount'] ?? hist['netPayable'] ?? hist['totalPayable']);
      if (paid > 0 && expected > 0 && paid >= expected) return true;
    }

    // 2. Check paidMonths string list
    for (final pm in kid.paidMonths) {
      final s = pm.toLowerCase().trim();
      if (s == monthKeyFormatted.toLowerCase() ||
          s == '$year-${monthIdx + 1}' ||
          s == '$year-${(monthIdx + 1).toString().padLeft(2, '0')}' ||
          s.contains(targetMonthShort.toLowerCase()) ||
          s.contains(targetMonthName.toLowerCase())) {
        return true;
      }
    }

    // 3. Check global monthlyFeeStatus for current month
    final now = DateTime.now();
    if (year == now.year && monthIdx == (now.month - 1) && (kid.monthlyFeeStatus.toLowerCase() == 'paid' || kid.monthlyFeeStatus.toLowerCase() == 'cleared')) {
      return true;
    }

    return false;
  }

  /// Helper to check if a monthKey string (e.g. "2026-09" or "Sep 2026") is settled
  static bool isMonthKeySettled(KidData kid, String monthKey, {int defaultYear = 2026}) {
    if (monthKey.isEmpty) return false;
    int yr = defaultYear;
    int mIdx = DateTime.now().month - 1;

    if (monthKey.contains('-')) {
      final parts = monthKey.split('-');
      if (parts.length >= 2) {
        yr = int.tryParse(parts[0]) ?? yr;
        mIdx = (int.tryParse(parts[1]) ?? 1) - 1;
      }
    } else {
      final lower = monthKey.toLowerCase();
      for (int i = 0; i < monthNames.length; i++) {
        if (lower.contains(monthNames[i].toLowerCase()) || lower.contains(monthShort[i].toLowerCase())) {
          mIdx = i;
          break;
        }
      }
      final yearMatch = RegExp(r'\b(20\d\d)\b').firstMatch(monthKey);
      if (yearMatch != null) {
        yr = int.tryParse(yearMatch.group(1)!) ?? yr;
      }
    }

    return isMonthSettled(kid, mIdx, yr);
  }

  /// Calculates the earliest unpaid / active billing month index (0-11) for a student.
  /// If current month is paid, looks forward to find the next open unpaid month.
  static int getEffectiveBillingMonthIdx(KidData kid, {int? targetYear}) {
    final now = DateTime.now();
    final yr = targetYear ?? now.year;

    for (int m = 0; m < 12; m++) {
      if (!isMonthSettled(kid, m, yr)) {
        return m; // Earliest unpaid month index (0-11)
      }
    }
    return now.month - 1;
  }

  /// Calculates exact itemized fee breakdown for any target month (0-11 index)
  /// Matches feePipeline.js on Principal WebApp Single Source of Truth!
  static ItemizedFeeBreakdown calculateItemizedFeeBreakdown(
    KidData kid, {
    int? targetMonthIdx,
    int? targetYear,
    String? targetMonthKey,
    Map<String, dynamic>? feeSettings,
  }) {
    final now = DateTime.now();
    int mIdx = targetMonthIdx ?? (now.month - 1);
    int yr = targetYear ?? now.year;

    if (targetMonthKey != null && targetMonthKey.isNotEmpty) {
      if (targetMonthKey.contains('-')) {
        final parts = targetMonthKey.split('-');
        if (parts.length >= 2) {
          yr = int.tryParse(parts[0]) ?? yr;
          mIdx = (int.tryParse(parts[1]) ?? 1) - 1;
        }
      } else {
        final lower = targetMonthKey.toLowerCase();
        for (int i = 0; i < monthNames.length; i++) {
          if (lower.contains(monthNames[i].toLowerCase()) || lower.contains(monthShort[i].toLowerCase())) {
            mIdx = i;
            break;
          }
        }
        final yearMatch = RegExp(r'\b(20\d\d)\b').firstMatch(targetMonthKey);
        if (yearMatch != null) {
          yr = int.tryParse(yearMatch.group(1)!) ?? yr;
        }
      }
    }

    final String monthKeyFormatted = '$yr-${(mIdx + 1).toString().padLeft(2, '0')}';
    final targetMonthName = monthNames[mIdx];
    final targetMonthShort = monthShort[mIdx];

    final is100PercentFree = checkIs100PercentFree(kid);
    final feeHistoryEntry = kid.monthlyFeeHistory[monthKeyFormatted];
    final bool isTargetMonthPaid = isMonthSettled(kid, mIdx, yr);

    // 1. Base Tuition & Recurring Items
    double baseTuition = parseDouble(kid.tuitionFee);
    final List<Map<String, dynamic>> recurringItems = [];

    if (baseTuition == 0 && kid.feeStructure.isNotEmpty) {
      final tuitionItem = kid.feeStructure.firstWhere(
        (f) => (f['name']?.toString() ?? '').toLowerCase().contains('tuition'),
        orElse: () => <String, dynamic>{},
      );
      if (tuitionItem.isNotEmpty) {
        baseTuition = parseDouble(tuitionItem['amount']);
      } else {
        baseTuition = kid.feeStructure.fold(0.0, (sum, f) => sum + parseDouble(f['amount']));
      }
    }

    // Standard default if not specified and not free
    if (baseTuition == 0 && !is100PercentFree) {
      baseTuition = 2000.0;
    }

    for (var f in kid.feeStructure) {
      final amt = parseDouble(f['amount']);
      if (amt > 0) {
        recurringItems.add({
          'name': f['name']?.toString() ?? 'Recurring Fee',
          'amount': amt,
        });
      }
    }

    // 2. Concessions / Discount
    double discountAmount = 0.0;
    double tuitionPayable = is100PercentFree ? 0.0 : baseTuition;

    if (!is100PercentFree && parseDouble(kid.feeDiscount) > 0) {
      final disc = parseDouble(kid.feeDiscount);
      if (disc <= 100) {
        // Percentage discount
        discountAmount = (baseTuition * (disc / 100)).roundToDouble();
        tuitionPayable = (baseTuition - discountAmount).clamp(0.0, double.infinity);
      } else {
        // Flat PKR discount
        discountAmount = disc.clamp(0.0, baseTuition);
        tuitionPayable = (baseTuition - discountAmount).clamp(0.0, double.infinity);
      }
    }

    // 3. Transport Fee
    double transportFee = parseDouble(kid.transportFee);
    if (transportFee == 0 && kid.feeStructure.isNotEmpty) {
      final transItem = kid.feeStructure.firstWhere(
        (f) => (f['name']?.toString() ?? '').toLowerCase().contains('transport'),
        orElse: () => <String, dynamic>{},
      );
      if (transItem.isNotEmpty) {
        transportFee = parseDouble(transItem['amount']);
      }
    }

    // 4. Month-Isolated Store Purchases & Unpaid Aggregation
    double storeDues = 0.0;
    final List<Map<String, dynamic>> storeItems = [];

    if (isTargetMonthPaid) {
      // Historical paid month - strictly preserve settled items
      if (feeHistoryEntry != null && feeHistoryEntry['storeItems'] is List) {
        for (var item in feeHistoryEntry['storeItems']) {
          if (item is Map) {
            final amt = parseDouble(item['amount'] ?? item['price']);
            if (amt > 0) {
              storeDues += amt;
              storeItems.add({
                'name': item['name']?.toString() ?? 'Store Item',
                'amount': amt,
                'status': 'paid',
                'receiptNo': feeHistoryEntry['receiptNo']?.toString(),
                'items': item['items'],
              });
            }
          }
        }
      } else if (feeHistoryEntry != null && parseDouble(feeHistoryEntry['storeDues']) > 0) {
        storeDues = parseDouble(feeHistoryEntry['storeDues']);
      }
    } else {
      // Target month is OPEN / UNPAID - capture assigned items and all unpaid store charges
      for (var sc in kid.storeCharges) {
        final isItemPaid = sc['status']?.toString() == 'paid';
        if (isItemPaid) {
          final itemMonthKey = sc['monthKey']?.toString() ?? '';
          if (itemMonthKey != monthKeyFormatted) continue;
        }

        final itemMonthKey = sc['monthKey']?.toString() ?? 
            (sc['date'] != null && sc['date'].toString().length >= 7 ? sc['date'].toString().substring(0, 7) : '');
        
        final bool isEligibleForUnpaidMonth = (!isItemPaid) && 
            (itemMonthKey.isEmpty || itemMonthKey.compareTo(monthKeyFormatted) <= 0);

        if (isEligibleForUnpaidMonth) {
          final amt = parseDouble(sc['amount'] ?? sc['price']);
          if (amt > 0) {
            storeDues += amt;
            storeItems.add({
              'name': sc['name']?.toString() ?? 'Store Item',
              'amount': amt,
              'status': 'unpaid',
              'receiptNo': sc['receiptNo']?.toString(),
              'items': sc['items'],
            });
          }
        }
      }
    }

    // 5. Month-Isolated Individual Custom Actions, Exams & Unpaid Aggregation
    double actionFee = 0.0;
    final List<Map<String, dynamic>> customItems = [];

    if (isTargetMonthPaid && feeHistoryEntry != null && feeHistoryEntry['customItems'] is List) {
      for (var c in feeHistoryEntry['customItems']) {
        if (c is Map) {
          final amt = parseDouble(c['amount']);
          final title = c['title']?.toString() ?? c['name']?.toString() ?? 'Custom Action';
          if (amt > 0) {
            actionFee += amt;
            customItems.add({
              'name': title,
              'amount': amt,
              'status': 'paid',
            });
          }
        }
      }
    } else if (!isTargetMonthPaid) {
      for (var act in kid.individualActions) {
        // Skip store charges here if already handled in storeItems
        if (act['type'] == 'store_inventory') {
          if (storeItems.any((si) => (si['receiptNo'] != null && si['receiptNo'] == act['receiptNo']) || si['name'] == act['name'])) {
            continue;
          }
        }

        final isActPaid = act['status']?.toString() == 'paid';
        if (isActPaid) {
          final actMonthKey = act['monthKey']?.toString() ?? '';
          if (actMonthKey != monthKeyFormatted) continue;
        }

        final actMonthKey = act['monthKey']?.toString() ?? 
            (act['createdAt'] != null && act['createdAt'].toString().length >= 7 ? act['createdAt'].toString().substring(0, 7) : 
            (act['date'] != null && act['date'].toString().length >= 7 ? act['date'].toString().substring(0, 7) : ''));

        final bool isEligibleForUnpaidMonth = (!isActPaid) &&
            (actMonthKey.isEmpty || actMonthKey.compareTo(monthKeyFormatted) <= 0);

        if (isEligibleForUnpaidMonth) {
          final amt = parseDouble(act['amount']);
          final title = act['name']?.toString() ?? act['title']?.toString() ?? 'Action Fee';
          if (amt > 0) {
            if (act['type'] == 'store_inventory') {
              storeDues += amt;
              storeItems.add({
                'name': title,
                'amount': amt,
                'status': 'unpaid',
              });
            } else {
              actionFee += amt;
              customItems.add({
                'name': title,
                'amount': amt,
                'status': 'unpaid',
              });
            }
          }
        }
      }
    }

    // 6. Late Fine / Penalty Calculation
    double penaltyFine = 0.0;
    if (feeHistoryEntry != null && parseDouble(feeHistoryEntry['fineAmount']) > 0) {
      penaltyFine = parseDouble(feeHistoryEntry['fineAmount']);
    } else if (feeSettings != null) {
      final dueDay = int.tryParse(feeSettings['dueDate']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '') ?? 10;
      final penaltyAmt = parseDouble(feeSettings['penaltyAmount']);
      final isCurrentTargetMonth = (yr == now.year && mIdx == (now.month - 1));

      if (isCurrentTargetMonth && now.day > dueDay && penaltyAmt > 0 && !is100PercentFree && !kid.lastPaymentFineWaived) {
        penaltyFine = penaltyAmt;
      }
    }

    // Total Calculation
    double totalPayable = is100PercentFree
        ? (storeDues + actionFee)
        : (tuitionPayable + transportFee + storeDues + actionFee + penaltyFine);

    // Paid Settlement Status
    bool isPaid = false;
    double paidAmount = 0.0;
    String? receiptNo;
    String? paymentMode;
    DateTime? paymentDate;

    // Check feeHistoryEntry
    if (feeHistoryEntry != null) {
      paidAmount = parseDouble(feeHistoryEntry['paidAmount']);
      receiptNo = feeHistoryEntry['receiptNo']?.toString();
      paymentMode = feeHistoryEntry['paymentMode']?.toString() ?? 'Online/Cash';
      if (feeHistoryEntry['paidAt'] != null) {
        paymentDate = DateTime.tryParse(feeHistoryEntry['paidAt'].toString())?.toLocal();
      }
      if (feeHistoryEntry['status'] == 'paid' || paidAmount >= totalPayable) {
        isPaid = true;
      }
    }

    // Fallback: Check kid.paidMonths string list
    if (!isPaid) {
      for (final pm in kid.paidMonths) {
        final s = pm.toLowerCase().trim();
        if (s == monthKeyFormatted.toLowerCase() ||
            s == '$yr-${mIdx + 1}' ||
            s.contains(targetMonthShort.toLowerCase()) ||
            s.contains(targetMonthName.toLowerCase())) {
          isPaid = true;
          paidAmount = totalPayable;
          receiptNo = receiptNo ?? 'PAID-CLEARED';
          paymentMode = paymentMode ?? kid.lastPaymentMode ?? 'Online Transfer';
          break;
        }
      }
    }

    // Global monthlyFeeStatus fallback for current month
    if (!isPaid && mIdx == (now.month - 1) && yr == now.year && kid.monthlyFeeStatus.toLowerCase() == 'paid') {
      isPaid = true;
      paidAmount = totalPayable;
      receiptNo = receiptNo ?? 'VERIFIED';
      paymentMode = paymentMode ?? kid.lastPaymentMode ?? 'Cash/Online';
    }

    // If 100% scholarship student has zero add-ons
    if (is100PercentFree && totalPayable == 0) {
      isPaid = true;
      receiptNo = 'SCHOLARSHIP';
      paymentMode = 'Full Scholarship';
      paidAmount = 0.0;
    }

    // Check if there is an active pending submission for this month
    final pending = kid.pendingPaymentSubmission;
    final bool isPending = pending != null &&
        (pending['status']?.toString() == 'pending') &&
        (pending['month']?.toString().toLowerCase().contains(targetMonthShort.toLowerCase()) == true ||
            pending['month']?.toString().toLowerCase().contains(targetMonthName.toLowerCase()) == true ||
            mIdx == (now.month - 1));

    double remainingBalance = isPaid ? 0.0 : (totalPayable - paidAmount).clamp(0.0, double.infinity);

    return ItemizedFeeBreakdown(
      is100PercentFree: is100PercentFree,
      baseTuition: baseTuition,
      discountAmount: discountAmount,
      tuitionPayable: tuitionPayable,
      transportFee: transportFee,
      storeDues: storeDues,
      actionFee: actionFee,
      penaltyFine: penaltyFine,
      totalPayable: totalPayable,
      paidAmount: paidAmount,
      remainingBalance: remainingBalance,
      isPaid: isPaid,
      isPending: isPending,
      receiptNo: receiptNo,
      paymentMode: paymentMode,
      paymentDate: paymentDate,
      targetMonthKey: monthKeyFormatted,
      targetMonthName: targetMonthName,
      recurringItems: recurringItems,
      storeItems: storeItems,
      customItems: customItems,
    );
  }

  /// Calculates payment reliability score
  static double calculateMonthlyScore(int dayPaid) {
    if (dayPaid <= 0) return 0.0;
    if (dayPaid >= 1 && dayPaid <= 3) return 110.0 - (10.0 * dayPaid);
    if (dayPaid >= 4 && dayPaid <= 6) return 110.0 - (10.0 * dayPaid);
    if (dayPaid >= 7 && dayPaid <= 10) return 80.0 - (5.0 * dayPaid);
    if (dayPaid >= 11 && dayPaid <= 15) {
      double score = 90.0 - (6.0 * dayPaid);
      return score < 0 ? 0.0 : score;
    }
    return 0.0;
  }

  /// Takes a list of days paid and calculates overall score
  static double calculateAggregateScore(List<int> pastPaymentDays) {
    if (pastPaymentDays.isEmpty) return 0.0;
    double total = 0.0;
    for (var day in pastPaymentDays) {
      total += calculateMonthlyScore(day);
    }
    return total / pastPaymentDays.length;
  }

  static String getReliabilityMessage(double score) {
    if (score >= 80) return "Excellent consistency! Your prompt payments help us maintain high educational standards.";
    if (score >= 60) return "Good standing. Thank you for your continued commitment to timely fee clearances.";
    if (score >= 40) return "Fair standing. Clearing dues within the first week of the month will improve your reliability.";
    return "Attention needed. Please ensure timely payments to avoid late fees and maintain a healthy standing.";
  }

  static Color getReliabilityColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  static IconData getReliabilityIcon(double score) {
    if (score >= 80) return Icons.verified_rounded;
    if (score >= 60) return Icons.thumb_up_rounded;
    if (score >= 40) return Icons.info_outline_rounded;
    return Icons.warning_amber_rounded;
  }

  static String getReliabilityLabel(double score) {
    if (score >= 80) return "Excellent";
    if (score >= 60) return "Good";
    if (score >= 40) return "Fair";
    return "Bad";
  }
}
