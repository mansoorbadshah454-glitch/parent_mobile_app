import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../kids/providers/kids_provider.dart';
import '../providers/fee_settings_provider.dart';
import '../providers/fee_transactions_provider.dart';
import '../screens/detailed_invoice_screen.dart';
import '../services/fee_calculator_service.dart';

enum FeeStatus { paid, scholarship, pending, overdue, upcoming, preAdmission }

class MonthFee {
  final int monthNumber;
  final String monthName;
  final FeeStatus status;
  final double amount;
  final ItemizedFeeBreakdown breakdown;

  MonthFee({
    required this.monthNumber,
    required this.monthName,
    required this.status,
    required this.amount,
    required this.breakdown,
  });
}

class YearlyFeeCalendar extends ConsumerWidget {
  final KidData kid;
  final String? dueDate;
  const YearlyFeeCalendar({super.key, required this.kid, this.dueDate});

  List<MonthFee> getMonths(Set<int> paidFromTxs, Map<String, dynamic> feeSettings) {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    final int dueDay = int.tryParse(dueDate?.replaceAll(RegExp(r'[^0-9]'), '') ?? '') ?? 10;

    // Parse admission month if available
    int admissionMonthNum = 1;
    if (kid.admissionDate != null && kid.admissionDate!.isNotEmpty) {
      final admDate = DateTime.tryParse(kid.admissionDate!);
      if (admDate != null && admDate.year == currentYear) {
        admissionMonthNum = admDate.month;
      }
    }

    final bool is100PercentFree = FeeCalculatorService.checkIs100PercentFree(kid);

    // Assemble authoritative set of paid months
    final Set<int> paidMonthsSet = Set<int>.from(paidFromTxs);

    // Scan kid.monthlyFeeHistory
    kid.monthlyFeeHistory.forEach((key, val) {
      if (val is Map && (val['status'] == 'paid' || FeeCalculatorService.parseDouble(val['remainingBalance']) == 0)) {
        final match = RegExp(r'(\d{4})-(\d{1,2})').firstMatch(key);
        if (match != null) {
          final yr = int.tryParse(match.group(1)!);
          final m = int.tryParse(match.group(2)!);
          if (yr == currentYear && m != null) {
            paidMonthsSet.add(m);
          }
        }
      }
    });

    // Scan explicit months in kid.paidMonths list
    for (final mStr in kid.paidMonths) {
      final parsed = _parseMonthStringToNumber(mStr, currentYear);
      if (parsed != null) paidMonthsSet.add(parsed);
    }

    // Scan global paid status for current month
    if (kid.monthlyFeeStatus.toLowerCase() == 'paid') {
      if (kid.monthlyFeeDate != null) {
        final d = DateTime.tryParse(kid.monthlyFeeDate!)?.toLocal();
        if (d != null && d.year == currentYear) {
          paidMonthsSet.add(d.month);
        } else {
          paidMonthsSet.add(currentMonth);
        }
      } else {
        paidMonthsSet.add(currentMonth);
      }
    }

    final List<String> monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    List<MonthFee> activeMonths = [];
    for (int i = 0; i < 12; i++) {
      final int monthNumber = i + 1;
      final bool isMonthPaid = paidMonthsSet.contains(monthNumber);

      final breakdown = FeeCalculatorService.calculateItemizedFeeBreakdown(
        kid,
        targetMonthIdx: i,
        targetYear: currentYear,
        feeSettings: feeSettings,
      );

      FeeStatus status;
      if (monthNumber < admissionMonthNum) {
        status = FeeStatus.preAdmission;
      } else if (is100PercentFree && breakdown.storeDues == 0 && breakdown.actionFee == 0) {
        status = FeeStatus.scholarship;
      } else if (isMonthPaid || breakdown.isPaid) {
        status = FeeStatus.paid;
      } else if (monthNumber > currentMonth) {
        status = FeeStatus.upcoming;
      } else if (monthNumber == currentMonth) {
        if (breakdown.isPending) {
          status = FeeStatus.pending;
        } else if (now.day > dueDay) {
          status = FeeStatus.overdue;
        } else {
          status = FeeStatus.pending;
        }
      } else {
        status = FeeStatus.overdue;
      }

      activeMonths.add(MonthFee(
        monthNumber: monthNumber,
        monthName: monthNames[i],
        status: status,
        amount: breakdown.totalPayable,
        breakdown: breakdown,
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
    final feeSettingsAsync = ref.watch(feeSettingsProvider);
    final feeSettings = feeSettingsAsync.value ?? <String, dynamic>{};

    final months = getMonths(paidFromTxs, feeSettings);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fee Calendar ${DateTime.now().year}',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ThemeColors.primaryText,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ThemeColors.primaryPurple.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Tap month for invoice',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ThemeColors.primaryPurple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
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
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.15,
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
    String statusLabel;

    switch (month.status) {
      case FeeStatus.paid:
        bgColor = const Color(0xFF10B981);
        textColor = Colors.white;
        icon = Icons.check_circle_rounded;
        statusLabel = 'PAID';
        break;
      case FeeStatus.scholarship:
        bgColor = const Color(0xFF059669);
        textColor = Colors.white;
        icon = Icons.star_rounded;
        statusLabel = 'FREE';
        break;
      case FeeStatus.pending:
        bgColor = const Color(0xFFF59E0B);
        textColor = Colors.white;
        icon = Icons.access_time_filled_rounded;
        statusLabel = 'DUE';
        break;
      case FeeStatus.overdue:
        bgColor = const Color(0xFFEF4444);
        textColor = Colors.white;
        icon = Icons.error_rounded;
        statusLabel = 'OVERDUE';
        break;
      case FeeStatus.upcoming:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF64748B);
        icon = Icons.lock_clock_rounded;
        statusLabel = 'UPCOMING';
        break;
      case FeeStatus.preAdmission:
        bgColor = const Color(0xFFF8FAFC);
        textColor = const Color(0xFF94A3B8);
        icon = Icons.remove_circle_outline_rounded;
        statusLabel = 'N/A';
        break;
    }

    final hasAddons = (month.breakdown.storeDues > 0 || month.breakdown.actionFee > 0);

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
          boxShadow: [
            if (month.status != FeeStatus.upcoming && month.status != FeeStatus.preAdmission)
              BoxShadow(
                color: bgColor.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: Icon(icon, color: textColor.withOpacity(0.9), size: 14),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  month.monthName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      month.status == FeeStatus.scholarship
                          ? 'Sponsored'
                          : 'Rs. ${month.amount.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Text(
                          statusLabel,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                            color: textColor.withOpacity(0.85),
                          ),
                        ),
                        if (hasAddons) ...[
                          const SizedBox(width: 3),
                          Text(
                            '• Addon',
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: textColor.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
