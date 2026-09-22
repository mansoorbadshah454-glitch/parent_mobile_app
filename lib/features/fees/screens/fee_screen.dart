import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_colors.dart';
import '../widgets/reliability_score_chart.dart';
import '../widgets/yearly_fee_calendar.dart';
import '../widgets/downloadable_invoice.dart';
import '../widgets/pay_fee_bottom_sheet.dart';
import '../widgets/pay_family_fee_bottom_sheet.dart';
import '../services/fee_calculator_service.dart';
import '../../kids/providers/kids_provider.dart';
import '../providers/fee_settings_provider.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/utils/translation_helper.dart';
import '../../../core/providers/parent_data_provider.dart';

class FeeScreen extends ConsumerWidget {
  final KidData kid;
  const FeeScreen({super.key, required this.kid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kidsAsyncValue = ref.watch(kidsProvider);
    final kidsList = kidsAsyncValue.value ?? [];
    final currentKid = kidsList.firstWhere((k) => k.id == kid.id, orElse: () => kid);
    
    final parentDataAsync = ref.watch(parentDataProvider);
    final String schoolName = parentDataAsync.value?.schoolName ?? 'School';

    final feeSettingsAsync = ref.watch(feeSettingsProvider);
    final feeSettings = feeSettingsAsync.value ?? {};
    final String dueDate = feeSettings['dueDate']?.toString().isNotEmpty == true ? feeSettings['dueDate'].toString() : '10th';
    final String penaltyAmount = feeSettings['penaltyAmount']?.toString().isNotEmpty == true ? feeSettings['penaltyAmount'].toString() : '500';
    final String calendarInfoMessage = "Kindly ensure fee submissions are completed by the $dueDate to avoid a late penalty of Rs. $penaltyAmount.";
    final lang = ref.watch(languageProvider);

    List<int> paymentHistory = [1, 5, 2, 8, 4]; // Dummy history for past months
    if ((currentKid.monthlyFeeStatus.isNotEmpty ? currentKid.monthlyFeeStatus.toLowerCase() : '') == 'paid' && currentKid.monthlyFeeDate != null) {
      final date = DateTime.tryParse(currentKid.monthlyFeeDate!)?.toLocal();
      if (date != null) {
        paymentHistory.add(date.day);
      }
    }

    double score = FeeCalculatorService.calculateAggregateScore(paymentHistory);
    String badgeMessage = FeeCalculatorService.getReliabilityMessage(score);
    Color badgeColor = FeeCalculatorService.getReliabilityColor(score);
    IconData badgeIcon = FeeCalculatorService.getReliabilityIcon(score);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: ThemeColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: ThemeColors.primaryPurple,
          elevation: 0,
          title: Text('${currentKid.name}\'s Fees', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(68.0), // Extra padding for fancy look
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24.0),
                ),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4.0), // minimizes default horizontal padding to prevent squishing
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: ThemeColors.primaryPurple,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                  unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                  splashBorderRadius: BorderRadius.circular(24.0),
                  tabs: const [
                    Tab(text: "Overview"),
                    Tab(text: "Calendar"),
                    Tab(text: "Payment"),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Overview
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      // Reliability Score Gauge
                      ReliabilityScoreChart(paymentHistoryDays: paymentHistory, lang: lang),
                      const SizedBox(height: 20),
                      // Info Badge
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: badgeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: badgeColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(badgeIcon, color: badgeColor),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  TranslationHelper.translate(badgeMessage, lang),
                                  style: lang == 'en' 
                                    ? GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: badgeColor,
                                      )
                                    : TranslationHelper.getTextStyle(
                                        lang,
                                        fontSize: 13,
                                        color: badgeColor,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 100), // padding for scrolling
                    ],
                  ),
                ),
              ],
            ),
            
            // Tab 2: Fee Calendar
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      // Yearly Fee Grid
                      YearlyFeeCalendar(kid: currentKid, dueDate: dueDate),
                      const SizedBox(height: 20),
                      // Info Badge Restored
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: ThemeColors.primaryPurple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: ThemeColors.primaryPurple.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, color: ThemeColors.primaryPurple),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  TranslationHelper.translate(calendarInfoMessage, lang),
                                  style: lang == 'en'
                                    ? GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: ThemeColors.primaryPurple,
                                      )
                                    : TranslationHelper.getTextStyle(
                                        lang,
                                        fontSize: 13,
                                        color: ThemeColors.primaryPurple,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 100), // padding for scrolling
                    ],
                  ),
                ),
              ],
            ),

            // Tab 3: Fee Payment
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Builder(
                builder: (context) {
                  final isPaid = (currentKid.monthlyFeeStatus.isNotEmpty ? currentKid.monthlyFeeStatus.toLowerCase() : '') == 'paid';
                  final pending = currentKid.pendingPaymentSubmission;
                  final isPending = pending != null && (pending['status'] ?? '').toString() == 'pending';
                  final isNeedsReupload = pending != null && (pending['status'] ?? '').toString() == 'needs_reupload';
                  final isRejected = pending != null && (pending['status'] ?? '').toString().trim().toLowerCase() == 'rejected';

                  double totalRecurring = 0.0;
                  for (var fee in currentKid.feeStructure) {
                    totalRecurring += FeeCalculatorService.parseDouble(fee['amount']);
                  }
                  double totalActions = 0.0;
                  double paidActions = 0.0;
                  for (var action in currentKid.individualActions) {
                    final actAmount = FeeCalculatorService.parseDouble(action['amount']);
                    totalActions += actAmount;
                    if ((action['status'] ?? '').toString().toLowerCase() == 'paid') {
                      paidActions += actAmount;
                    }
                  }
                  double calculatedDue = (totalRecurring + totalActions) - ((isPaid ? totalRecurring : 0) + paidActions);
                  if (calculatedDue <= 0 && !isPaid) {
                    calculatedDue = totalRecurring > 0 ? totalRecurring : 1000.0;
                  }

                  return Column(
                    children: [
                      DownloadableInvoice(kid: currentKid, schoolName: schoolName),
                      const SizedBox(height: 28),

                      if (isPaid) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.verified_rounded, color: Color(0xFF059669), size: 28),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Fee Cleared / Paid',
                                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF065F46)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'All dues for this period have been cleared successfully.',
                                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF047857)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (currentKid.lastPaymentFineWaived) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF86EFAC)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.celebration_rounded, color: Color(0xFF059669), size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Late Fine Waived by Principal',
                                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF166534)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'The late penalty fee was kindly waived by the administration.',
                                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF15803D)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ] else if (isPending) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade200,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.hourglass_top_rounded, color: Colors.amber.shade900, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Payment Under Verification',
                                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                        ),
                                        Text(
                                          'Submitted via ${pending['paymentMethod'] ?? 'Online'}',
                                          style: GoogleFonts.inter(fontSize: 12, color: Colors.amber.shade800),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Pending',
                                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                    ),
                                  ),
                                ],
                              ),
                                const SizedBox(height: 12),
                                Text(
                                  'Payment proof of Rs. ${pending['amount'] ?? calculatedDue} has been submitted. The school admin will verify and confirm shortly.',
                                  style: GoogleFonts.inter(fontSize: 12, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ] else if (isNeedsReupload) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFFED7AA)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade200,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.refresh_rounded, color: Colors.orange.shade900, size: 24),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Slip Re-upload Requested',
                                            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                                          ),
                                          Text(
                                            'Action Required',
                                            style: GoogleFonts.inter(fontSize: 12, color: Colors.orange.shade800),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.orange.shade200),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.info_outline_rounded, size: 18, color: Colors.orange.shade800),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          pending['message']?.toString().isNotEmpty == true
                                              ? pending['message'].toString()
                                              : 'The school administration requested a clearer screenshot or proof of payment.',
                                          style: GoogleFonts.inter(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () => PayFeeBottomSheet.show(context, currentKid, calculatedDue),
                                  icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 18),
                                  label: Text(
                                    'Re-upload Payment Slip',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange.shade800,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (isRejected) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.cancel_rounded, color: Colors.red.shade700, size: 24),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Payment Rejected',
                                            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                                          ),
                                          Text(
                                            'Action Required - Please Resubmit',
                                            style: GoogleFonts.inter(fontSize: 12, color: Colors.red.shade700),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Rejected',
                                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.red.shade200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.info_outline_rounded, size: 16, color: Colors.red.shade700),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Reason from School Admin:',
                                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        pending['rejectReason']?.toString().isNotEmpty == true
                                            ? pending['rejectReason'].toString()
                                            : (pending['message']?.toString().isNotEmpty == true
                                                ? pending['message'].toString()
                                                : 'Your payment submission was rejected by the administration. Please check details and resubmit.'),
                                        style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () => PayFeeBottomSheet.show(context, currentKid, calculatedDue),
                                  icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                                  label: Text(
                                    'Submit New Payment',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                        ElevatedButton.icon(
                          onPressed: () => PayFeeBottomSheet.show(context, currentKid, calculatedDue),
                          icon: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                          label: Text(
                            'Pay Now (Rs. ${calculatedDue.toStringAsFixed(0)})',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ThemeColors.primaryPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
                            elevation: 4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_outline_rounded, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text(
                              'Pay via EasyPaisa, JazzCash, or Bank Transfer',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        if (kidsList.length > 1) ...[
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed: () => PayFamilyFeeBottomSheet.show(context, kidsList),
                            icon: const Icon(Icons.diversity_3_rounded, size: 18, color: ThemeColors.primaryPurple),
                            label: Text(
                              'Pay for all siblings together',
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: ThemeColors.primaryPurple),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              side: const BorderSide(color: ThemeColors.primaryPurple, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        ],
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZigZagClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    double notchSize = 6.0;

    // Top ZigZag
    path.moveTo(0, notchSize);
    for (double i = 0; i < size.width; i += notchSize * 2) {
      path.lineTo(i + notchSize, 0);
      path.lineTo(i + notchSize * 2, notchSize);
    }
    
    // Right edge
    path.lineTo(size.width, size.height - notchSize);

    // Bottom ZigZag
    for (double i = size.width; i > 0; i -= notchSize * 2) {
      path.lineTo(i - notchSize, size.height);
      path.lineTo(i - notchSize * 2, size.height - notchSize);
    }

    // Left edge
    path.lineTo(0, notchSize);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class FeeReceiptWidget extends StatelessWidget {
  final KidData kid;
  final String schoolName;
  final String? monthName;
  final bool? isPaidOverride;
  const FeeReceiptWidget({
    super.key,
    required this.kid,
    required this.schoolName,
    this.monthName,
    this.isPaidOverride,
  });

  @override
  Widget build(BuildContext context) {
    bool isPaid = isPaidOverride ?? ((kid.monthlyFeeStatus.isNotEmpty ? kid.monthlyFeeStatus.toLowerCase() : '') == 'paid');
    double totalRecurring = 0;
    for (var fee in kid.feeStructure) {
      totalRecurring += FeeCalculatorService.parseDouble(fee['amount']);
    }

    double totalActions = 0;
    double paidActions = 0;
    for (var action in kid.individualActions) {
      final actAmount = FeeCalculatorService.parseDouble(action['amount']);
      totalActions += actAmount;
      if ((action['status'] ?? '').toString().toLowerCase() == 'paid') {
        paidActions += actAmount;
      }
    }

    double grandTotal = totalRecurring + totalActions;
    double totalPaid = (isPaid ? totalRecurring : 0) + paidActions;
    double totalDue = grandTotal - totalPaid;

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipPath(
        clipper: _ZigZagClipper(),
        child: Container(
          width: double.infinity,
          color: const Color(0xFFFDFBF7), // receipt paper color
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      schoolName.toUpperCase(),
                      style: GoogleFonts.spaceMono(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: ThemeColors.primaryPurple,
                        letterSpacing: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'FEE RECEIPT',
                      style: GoogleFonts.spaceMono(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      monthName != null ? 'Month: $monthName' : 'Date: ${DateTime.now().toIso8601String().substring(0, 10)}',
                      style: GoogleFonts.spaceMono(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDashedLine(),
              const SizedBox(height: 16),
              Text('RECURRING FEES', style: GoogleFonts.spaceMono(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 8),
              if (kid.feeStructure.isEmpty)
                Text('  None', style: GoogleFonts.spaceMono(fontSize: 14, color: Colors.black54)),
              ...kid.feeStructure.map((f) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(f['name']?.toString() ?? 'Fee', style: GoogleFonts.spaceMono(fontSize: 14, color: Colors.black87)),
                        Text('Rs ${f['amount']}', style: GoogleFonts.spaceMono(fontSize: 14, color: Colors.black87)),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
              Text('INDIVIDUAL ACTIONS', style: GoogleFonts.spaceMono(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 8),
              if (kid.individualActions.isEmpty)
                Text('  None', style: GoogleFonts.spaceMono(fontSize: 14, color: Colors.black54)),
              ...kid.individualActions.map((a) {
                bool actionPaid = a['status'] == 'paid';
                return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text('${a['name']}\n(${actionPaid ? 'paid' : 'unpaid'})', style: GoogleFonts.spaceMono(fontSize: 14, color: actionPaid ? Colors.green[700] : Colors.black87, height: 1.2))),
                        Text('Rs ${a['amount']}', style: GoogleFonts.spaceMono(fontSize: 14, color: actionPaid ? Colors.green[700] : Colors.black87)),
                      ],
                    ),
                  );
              }),
              if (kid.lastPaymentFineWaived) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.celebration_rounded, color: Color(0xFF059669), size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'Late Penalty Waived',
                            style: GoogleFonts.spaceMono(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF065F46)),
                          ),
                        ],
                      ),
                      Text(
                        'Rs 0 (Maaf)',
                        style: GoogleFonts.spaceMono(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF059669)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _buildDashedLine(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TOTAL BILL', style: GoogleFonts.spaceMono(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
                  Text('Rs $grandTotal', style: GoogleFonts.spaceMono(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('PAID AMOUNT', style: GoogleFonts.spaceMono(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green[700])),
                  Text('- Rs $totalPaid', style: GoogleFonts.spaceMono(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green[700])),
                ],
              ),
              const SizedBox(height: 8),
              _buildDashedLine(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('AMOUNT DUE', style: GoogleFonts.spaceMono(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  Text('Rs $totalDue', style: GoogleFonts.spaceMono(fontSize: 16, fontWeight: FontWeight.bold, color: totalDue > 0 ? Colors.red[700] : Colors.green[700])),
                ],
              ),
            ],
          ),
          Positioned(
                top: 25,
                left: 12,
                child: Transform.rotate(
                  angle: -0.25, // classic stamp tilt
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPaid ? Colors.green.withOpacity(0.05) : Colors.red.withOpacity(0.05),
                      border: Border.all(color: isPaid ? Colors.green : Colors.red, width: 3),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: isPaid ? Colors.green : Colors.red, width: 1),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isPaid ? Icons.verified : Icons.do_not_disturb_alt, 
                              color: isPaid ? Colors.green : Colors.red, 
                              size: 24
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isPaid ? 'PAID' : 'UNPAID',
                              style: GoogleFonts.spaceMono(
                                color: isPaid ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(decoration: BoxDecoration(color: Colors.black38)),
            );
          }),
        );
      },
    );
  }
}
