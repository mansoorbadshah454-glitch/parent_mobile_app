import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../kids/providers/kids_provider.dart';
import '../providers/fee_transactions_provider.dart';
import '../screens/detailed_invoice_screen.dart';
import '../services/fee_calculator_service.dart';

enum FeeStatus { paid, pending, overdue, upcoming }

class MonthFee {
  final int monthNumber;
  final String monthName;
  final FeeStatus status;
  final double amount;

  MonthFee({
    required this.monthNumber,
    required this.monthName,
    required this.status,
    required this.amount,
  });
}

class YearlyFeeCalendar extends ConsumerWidget {
  final KidData kid;
  final String? dueDate;
  const YearlyFeeCalendar({super.key, required this.kid, this.dueDate});

  List<MonthFee> getMonths(Set<int> paidFromTxs) {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    final int dueDay = int.tryParse(dueDate?.replaceAll(RegExp(r'[^0-9]'), '') ?? '') ?? 10;

    final bool isGlobalPaid = (kid.monthlyFeeStatus.isNotEmpty ? kid.monthlyFeeStatus.toLowerCase() : '') == 'paid';
    final bool isPending = kid.pendingPaymentSubmission != null && (kid.pendingPaymentSubmission!['status'] ?? '').toString() == 'pending';
    final DateTime? paidDate = kid.monthlyFeeDate != null ? DateTime.tryParse(kid.monthlyFeeDate!)?.toLocal() : null;

    // Calculate base monthly fee from student fee structure
    double monthlyAmount = 0.0;
    for (final fee in kid.feeStructure) {
      monthlyAmount += FeeCalculatorService.parseDouble(fee['amount']);
    }
    if (monthlyAmount <= 0) monthlyAmount = 1500.0;

    // Assemble authoritative set of paid months
    final Set<int> paidMonthsSet = Set<int>.from(paidFromTxs);

    // 1. If student monthlyFeeStatus == 'paid' and monthlyFeeDate is recorded
    if (isGlobalPaid && paidDate != null && paidDate.year == currentYear) {
      paidMonthsSet.add(paidDate.month);
    }

    // 2. Add any explicit months in kid.paidMonths list
    for (final mStr in kid.paidMonths) {
      final parsed = _parseMonthStringToNumber(mStr, currentYear);
      if (parsed != null) paidMonthsSet.add(parsed);
    }

    // 3. Add approved online submission month if present
    if (kid.pendingPaymentSubmission != null && (kid.pendingPaymentSubmission!['status'] ?? '').toString() == 'approved') {
      final mStr = kid.pendingPaymentSubmission!['month']?.toString() ?? '';
      final parsed = _parseMonthStringToNumber(mStr, currentYear);
      if (parsed != null) paidMonthsSet.add(parsed);
    }

    final List<String> monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    List<MonthFee> activeMonths = [];
    for (int i = 0; i < 12; i++) {
      final int monthNumber = i + 1;
      final bool isMonthPaid = paidMonthsSet.contains(monthNumber);

      FeeStatus status;
      if (isMonthPaid) {
        status = FeeStatus.paid;
      } else if (monthNumber > currentMonth) {
        status = FeeStatus.upcoming;
      } else if (monthNumber == currentMonth) {
        if (isPending) {
          status = FeeStatus.pending;
        } else if (now.day > dueDay) {
          status = FeeStatus.overdue;
        } else {
          status = FeeStatus.pending;
        }
      } else {
        // Month < currentMonth and not in paidMonthsSet -> Strictly Overdue
        status = FeeStatus.overdue;
      }

      activeMonths.add(MonthFee(
        monthNumber: monthNumber,
        monthName: monthNames[i],
        status: status,
        amount: monthlyAmount,
      ));
    }
    return activeMonths;
  }

  static int? _parseMonthStringToNumber(String str, int currentYear) {
    final s = str.toLowerCase().trim();
    if (s.isEmpty) return null;

    final yearMatch = RegExp(r'\b(20\d\d)\b').firstMatch(s);
    if (yearMatch != null) {
      final parsedY = int.tryParse(yearMatch.group(1)!);
      if (parsedY != null && parsedY != currentYear) return null;
    }

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

    final numMatch = RegExp(r'^\d{1,2}$').firstMatch(s);
    if (numMatch != null) {
      final n = int.tryParse(s);
      if (n != null && n >= 1 && n <= 12) return n;
    }

    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paidTxsAsync = ref.watch(studentPaidMonthsProvider(kid.id));
    final paidFromTxs = paidTxsAsync.value ?? <int>{};
    final months = getMonths(paidFromTxs);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fee Calendar ${DateTime.now().year}',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ThemeColors.primaryText,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: ThemeColors.primaryPurple.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.0,
              ),
              itemCount: months.length,
              itemBuilder: (context, index) {
                final month = months[index];
                return _buildMonthCard(context, month);
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildMonthCard(BuildContext context, MonthFee month) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (month.status) {
      case FeeStatus.paid:
        bgColor = Colors.green;
        textColor = Colors.white;
        icon = Icons.check_circle_rounded;
        break;
      case FeeStatus.pending:
        bgColor = Colors.orange;
        textColor = Colors.white;
        icon = Icons.access_time_filled_rounded;
        break;
      case FeeStatus.overdue:
        bgColor = Colors.red;
        textColor = Colors.white;
        icon = Icons.error_rounded;
        break;
      case FeeStatus.upcoming:
        bgColor = Colors.grey[300]!;
        textColor = Colors.grey[600]!;
        icon = Icons.lock_clock_rounded;
        break;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailedInvoiceScreen(kid: kid, month: month),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: textColor.withOpacity(0.2), width: 1),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 8,
              right: 8,
              child: Icon(icon, color: textColor, size: 16),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    month.monthName,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor == Colors.white ? Colors.white : ThemeColors.primaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
