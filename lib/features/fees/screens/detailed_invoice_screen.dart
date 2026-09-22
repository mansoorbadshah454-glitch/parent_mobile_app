import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../kids/providers/kids_provider.dart';
import '../../../core/providers/parent_data_provider.dart';
import '../widgets/downloadable_invoice.dart';
import '../widgets/pay_fee_bottom_sheet.dart';
import '../widgets/yearly_fee_calendar.dart';

class DetailedInvoiceScreen extends ConsumerWidget {
  final KidData kid;
  final MonthFee month;

  const DetailedInvoiceScreen({super.key, required this.kid, required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Refresh kid data dynamically from kidsProvider
    final kidsAsync = ref.watch(kidsProvider);
    final currentKid = kidsAsync.value?.firstWhere((k) => k.id == kid.id, orElse: () => kid) ?? kid;

    final parentDataAsync = ref.watch(parentDataProvider);
    final String schoolName = parentDataAsync.value?.schoolName ?? 'School';

    final int currentYear = DateTime.now().year;
    final String fullMonthTitle = '${month.monthName} $currentYear';

    final bool isPaid = month.status == FeeStatus.paid;
    final bool isOverdue = month.status == FeeStatus.overdue;
    final bool isPending = month.status == FeeStatus.pending;
    final bool isUpcoming = month.status == FeeStatus.upcoming;

    // Check if there is an active pending submission for this month
    final pendingMap = currentKid.pendingPaymentSubmission;
    final bool isThisMonthPendingVerification = pendingMap != null &&
        (pendingMap['status'] ?? '').toString() == 'pending' &&
        (pendingMap['month']?.toString().toLowerCase().contains(month.monthName.toLowerCase()) ?? false);

    return Scaffold(
      backgroundColor: ThemeColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: ThemeColors.primaryPurple,
        elevation: 0,
        title: Text(
          '$fullMonthTitle Invoice',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Visual Invoice Widget with PDF Download
            DownloadableInvoice(
              kid: currentKid,
              schoolName: schoolName,
              monthName: fullMonthTitle,
              isPaid: isPaid,
            ),
            const SizedBox(height: 24),

            // Contextual Payment & Status Action Card
            if (isPaid) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fee Paid & Cleared',
                            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF065F46)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'The fee for $fullMonthTitle has been cleared and verified.',
                            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF047857)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (isThisMonthPendingVerification) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Under Verification',
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF92400E)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Payment proof for $fullMonthTitle is currently being verified by the principal.',
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFB45309)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (isOverdue || isPending) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isOverdue ? const Color(0xFFFEF2F2) : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isOverdue ? const Color(0xFFFECACA) : const Color(0xFFFED7AA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isOverdue ? Icons.error_outline_rounded : Icons.info_outline_rounded,
                          color: isOverdue ? Colors.red.shade700 : Colors.orange.shade800,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isOverdue ? 'Overdue Payment' : 'Pending Payment',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isOverdue ? Colors.red.shade900 : Colors.orange.shade900,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isOverdue ? Colors.red.shade100 : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Rs. ${month.amount.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isOverdue ? Colors.red.shade900 : Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isOverdue
                          ? 'This month\'s fee is past due. Please submit your payment slip to avoid penalties.'
                          : 'Kindly clear this month\'s dues before the due date.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isOverdue ? Colors.red.shade800 : Colors.orange.shade800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          PayFeeBottomSheet.show(
                            context,
                            currentKid,
                            month.amount,
                            feeMonth: fullMonthTitle,
                          );
                        },
                        icon: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                        label: Text(
                          'Pay Fee for ${month.monthName} (Rs. ${month.amount.toStringAsFixed(0)})',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isOverdue ? Colors.red.shade700 : ThemeColors.primaryPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (isUpcoming) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_clock_rounded, color: Colors.grey.shade600, size: 24),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upcoming Billing Period',
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Fee for $fullMonthTitle will open for payment once this billing cycle starts.',
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
