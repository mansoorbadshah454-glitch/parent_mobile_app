import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../kids/providers/kids_provider.dart';
import '../../kids/widgets/shining_profile_avatar.dart';
import '../../../core/providers/parent_data_provider.dart';
import '../providers/fee_settings_provider.dart';
import '../services/fee_calculator_service.dart';
import '../widgets/pay_fee_bottom_sheet.dart';
import '../widgets/yearly_fee_calendar.dart';
import 'detailed_invoice_screen.dart';

class FeeScreen extends ConsumerStatefulWidget {
  final KidData kid;
  final int? initialMonthIdx;
  final int? initialYear;

  const FeeScreen({
    super.key,
    required this.kid,
    this.initialMonthIdx,
    this.initialYear,
  });

  @override
  ConsumerState<FeeScreen> createState() => _FeeScreenState();
}

class _FeeScreenState extends ConsumerState<FeeScreen> {
  late int _selectedMonthIdx;
  late int _selectedYear;
  final ScrollController _monthScrollController = ScrollController();
  bool _hasScrolled = false;
  bool _hasSmartAutoSelected = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonthIdx = widget.initialMonthIdx ?? (now.month - 1);
    _selectedYear = widget.initialYear ?? now.year;
    if (widget.initialMonthIdx != null) {
      _hasSmartAutoSelected = true;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedMonth();
    });
  }

  void _scrollToSelectedMonth({bool force = false}) {
    if (!_monthScrollController.hasClients) return;
    if (_hasScrolled && !force) return;
    _hasScrolled = true;
    final targetOffset = (_selectedMonthIdx * 90.0) - 20.0;
    _monthScrollController.animateTo(
      targetOffset.clamp(0.0, _monthScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  int _determineEarliestDueMonth(KidData kid, Map<String, dynamic> feeSettings) {
    final now = DateTime.now();
    final int currentMonthIdx = now.month - 1;
    final int currentYear = now.year;

    for (int m = 0; m <= currentMonthIdx; m++) {
      final breakdown = FeeCalculatorService.calculateItemizedFeeBreakdown(
        kid,
        targetMonthIdx: m,
        targetYear: currentYear,
        feeSettings: feeSettings,
      );
      final bool isPaid = breakdown.isPaid || (breakdown.isFullScholarship && breakdown.totalPayable <= 0);
      if (!isPaid) {
        return m;
      }
    }
    return currentMonthIdx;
  }

  void _runInitialSmartMonthAutoSelect(KidData kid, Map<String, dynamic> feeSettings) {
    if (_hasSmartAutoSelected) return;
    _hasSmartAutoSelected = true;
    final smartMonthIdx = _determineEarliestDueMonth(kid, feeSettings);
    if (smartMonthIdx != _selectedMonthIdx) {
      _selectedMonthIdx = smartMonthIdx;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedMonth(force: true);
    });
  }

  @override
  void dispose() {
    _monthScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dynamically watch kids list for real-time updates
    final kidsAsyncValue = ref.watch(kidsProvider);
    final kidsList = kidsAsyncValue.value ?? [];
    final currentKid = kidsList.firstWhere((k) => k.id == widget.kid.id, orElse: () => widget.kid);

    final parentDataAsync = ref.watch(parentDataProvider);
    final String schoolName = parentDataAsync.value?.schoolName ?? 'School';

    final feeSettingsAsync = ref.watch(feeSettingsProvider);
    final feeSettings = feeSettingsAsync.value ?? <String, dynamic>{};
    final String dueDateStr = feeSettings['dueDate']?.toString().isNotEmpty == true
        ? feeSettings['dueDate'].toString()
        : '10th';

    // Auto-select earliest unpaid month if initialMonthIdx was not specified
    _runInitialSmartMonthAutoSelect(currentKid, feeSettings);

    final monthName = FeeCalculatorService.monthNames[_selectedMonthIdx];
    final String fullMonthTitle = '$monthName $_selectedYear';

    // Calculate exact SSOT itemized breakdown for the selected month
    final breakdown = FeeCalculatorService.calculateItemizedFeeBreakdown(
      currentKid,
      targetMonthIdx: _selectedMonthIdx,
      targetYear: _selectedYear,
      feeSettings: feeSettings,
    );

    final bool isPaid = breakdown.isPaid;
    final bool isFullScholarship = breakdown.isFullScholarship && breakdown.totalPayable <= 0;
    final pending = currentKid.pendingPaymentSubmission;
    final bool isCurrentMonth = _selectedMonthIdx == (DateTime.now().month - 1) && _selectedYear == DateTime.now().year;
    final bool isPending = breakdown.isPending || (pending != null &&
        (pending['status'] ?? '').toString().trim().toLowerCase() == 'pending' &&
        isCurrentMonth);
    final bool isNeedsReupload = pending != null &&
        (pending['status'] ?? '').toString().trim().toLowerCase() == 'needs_reupload' &&
        isCurrentMonth;
    final bool isRejected = pending != null &&
        (pending['status'] ?? '').toString().trim().toLowerCase() == 'rejected' &&
        isCurrentMonth;

    final now = DateTime.now();
    final dueDay = int.tryParse(dueDateStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 10;
    final bool isPastMonth = (_selectedYear < now.year) || (_selectedYear == now.year && _selectedMonthIdx < (now.month - 1));
    final bool isPastDueDate = isCurrentMonth && (now.day > dueDay);
    final bool isOverdue = !isPaid && !isFullScholarship && (isPastMonth || isPastDueDate);

    return Scaffold(
      backgroundColor: ThemeColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: ThemeColors.primaryPurple,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${currentKid.name}\'s Fee Ledger',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
            ),
            Text(
              'Class: ${currentKid.className} • Roll: ${currentKid.rollNo}',
              style: GoogleFonts.inter(fontSize: 11.5, color: Colors.white.withOpacity(0.85)),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Interactive Month Selector Ribbon
            _buildMonthSelectorRibbon(currentKid, feeSettings),
            const SizedBox(height: 16),

            // 2. Student Identity & Concession Banner
            _buildStudentIdentityBanner(currentKid, fullMonthTitle, isPaid, isFullScholarship, isOverdue),
            const SizedBox(height: 16),

            // 3. Main Itemized Categorized Breakdown Card
            _buildCategorizedBreakdownCard(breakdown, fullMonthTitle, isPaid, isFullScholarship),
            const SizedBox(height: 18),

            // 4. Action & Payment Status Section (Direct Individual Pay)
            _buildPaymentStatusAndActionSection(
              context,
              currentKid,
              breakdown,
              fullMonthTitle,
              monthName,
              isPaid,
              isFullScholarship,
              isPending,
              isNeedsReupload,
              isRejected,
              isOverdue,
              pending,
              schoolName,
            ),
            const SizedBox(height: 24),

            // 5. Academic Year Quick Clearance Summary
            _buildYearlyClearanceSummary(currentKid, feeSettings),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // 1. Month Selector Ribbon
  Widget _buildMonthSelectorRibbon(KidData kid, Map<String, dynamic> feeSettings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, size: 16, color: ThemeColors.primaryPurple),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Select Billing Month ($_selectedYear)',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${FeeCalculatorService.monthNames[_selectedMonthIdx]} Active',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: ThemeColors.primaryPurple),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: ListView.builder(
            controller: _monthScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: 12,
            itemBuilder: (context, idx) {
              final monthShort = FeeCalculatorService.monthShort[idx];
              final isSelected = (_selectedMonthIdx == idx);
              final breakdown = FeeCalculatorService.calculateItemizedFeeBreakdown(
                kid,
                targetMonthIdx: idx,
                targetYear: _selectedYear,
                feeSettings: feeSettings,
              );

              final bool isPaid = breakdown.isPaid || (breakdown.isFullScholarship && breakdown.totalPayable <= 0);
              final Color activeBorder = isPaid ? const Color(0xFF059669) : ThemeColors.primaryPurple;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedMonthIdx = idx;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: idx == 11 ? 0 : 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isPaid ? const Color(0xFFECFDF5) : ThemeColors.primaryPurple.withOpacity(0.12))
                        : (isPaid ? Colors.green.shade50.withOpacity(0.6) : Colors.white),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? activeBorder : (isPaid ? Colors.green.shade200 : Colors.grey.shade300),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: activeBorder.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        monthShort,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected
                              ? (isPaid ? const Color(0xFF065F46) : ThemeColors.primaryPurple)
                              : (isPaid ? Colors.green.shade800 : Colors.black87),
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (isPaid)
                        const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF059669))
                      else if (breakdown.totalPayable > 0)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 2. Student Identity & Concession Banner
  Widget _buildStudentIdentityBanner(
    KidData kid,
    String fullMonthTitle,
    bool isPaid,
    bool isFullScholarship,
    bool isOverdue,
  ) {
    Color bannerBg = isPaid
        ? const Color(0xFFECFDF5)
        : (isOverdue ? const Color(0xFFFEF2F2) : Colors.white);
    Color bannerBorder = isPaid
        ? const Color(0xFFA7F3D0)
        : (isOverdue ? const Color(0xFFFECACA) : Colors.grey.shade200);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bannerBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ShiningProfileAvatar(
            imageUrl: kid.imageUrl,
            radius: 26,
            strokeWidth: 2.5,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        kid.name,
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isFullScholarship)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('🎓 100% Free', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Class: ${kid.className}  •  Roll No: ${kid.rollNo}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  'Statement: $fullMonthTitle',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: ThemeColors.primaryPurple),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Main Itemized Categorized Breakdown Card
  Widget _buildCategorizedBreakdownCard(
    ItemizedFeeBreakdown breakdown,
    String fullMonthTitle,
    bool isPaid,
    bool isFullScholarship,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ThemeColors.primaryPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.receipt_long_rounded, color: ThemeColors.primaryPurple, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Categorized Breakdown',
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPaid ? const Color(0xFFECFDF5) : Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isPaid ? 'PAID' : 'DUE',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isPaid ? const Color(0xFF059669) : ThemeColors.primaryPurple,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Breakdown Items List
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // 1. Base Tuition Fee
                _buildBreakdownRow(
                  icon: Icons.school_rounded,
                  iconColor: const Color(0xFF2563EB),
                  title: 'Base Tuition Fee',
                  subtitle: isFullScholarship ? 'Covered by 100% Scholarship' : 'Monthly standard class fee',
                  amountText: 'Rs. ${breakdown.baseTuition.toStringAsFixed(0)}',
                ),

                // 2. Concession / Scholarship Discount
                if (breakdown.discountAmount > 0 || isFullScholarship) ...[
                  const SizedBox(height: 12),
                  _buildBreakdownRow(
                    icon: Icons.stars_rounded,
                    iconColor: const Color(0xFF059669),
                    title: breakdown.is100PercentFree ? '100% Scholarship Waiver' : (breakdown.concessionName.isNotEmpty ? breakdown.concessionName : 'Discount / Concession'),
                    subtitle: breakdown.is100PercentFree ? 'Full tuition sponsored by school' : 'Concession approved by administration',
                    amountText: '- Rs. ${(isFullScholarship ? breakdown.baseTuition : breakdown.discountAmount).toStringAsFixed(0)}',
                    amountColor: const Color(0xFF059669),
                  ),
                ],

                // 3. Transport Charges
                if (breakdown.transportFee > 0) ...[
                  const SizedBox(height: 12),
                  _buildBreakdownRow(
                    icon: Icons.directions_bus_rounded,
                    iconColor: const Color(0xFFD97706),
                    title: 'Transport Van Charges',
                    subtitle: 'Official school transport service',
                    amountText: 'Rs. ${breakdown.transportFee.toStringAsFixed(0)}',
                  ),
                ],

                // 4. Store Inventory Purchases (Uniform, Books, Stationery)
                if (breakdown.storeItems.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...breakdown.storeItems.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _buildBreakdownRow(
                      icon: Icons.shopping_bag_rounded,
                      iconColor: const Color(0xFF7C3AED),
                      title: '${item['name']} (Store)',
                      subtitle: 'School inventory store order',
                      amountText: 'Rs. ${item['amount']}',
                    ),
                  )),
                ],

                // 5. Custom Actions / Exam / Activity Fees
                if (breakdown.actions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...breakdown.actions.map((act) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _buildBreakdownRow(
                      icon: Icons.assignment_turned_in_rounded,
                      iconColor: const Color(0xFF0284C7),
                      title: '${act['name']} (Activity/Exam)',
                      subtitle: 'Special event / examination charge',
                      amountText: 'Rs. ${act['amount']}',
                    ),
                  )),
                ],

                // 6. Late Fine / Penalty
                if (breakdown.penaltyFine > 0) ...[
                  const SizedBox(height: 12),
                  _buildBreakdownRow(
                    icon: Icons.alarm_rounded,
                    iconColor: Colors.red.shade700,
                    title: 'Late Fine / Penalty',
                    subtitle: 'Submission after monthly due date',
                    amountText: 'Rs. ${breakdown.penaltyFine.toStringAsFixed(0)}',
                    amountColor: Colors.red.shade700,
                  ),
                ],

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Total Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Net Payable',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        Text(
                          'Billing for $fullMonthTitle',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    Text(
                      'Rs. ${breakdown.totalPayable.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isPaid ? const Color(0xFF059669) : ThemeColors.primaryPurple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String amountText,
    Color? amountColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          amountText,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: amountColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  // 4. Action & Payment Status Section (Direct Individual Pay or Download Invoice)
  Widget _buildPaymentStatusAndActionSection(
    BuildContext context,
    KidData kid,
    ItemizedFeeBreakdown breakdown,
    String fullMonthTitle,
    String monthName,
    bool isPaid,
    bool isFullScholarship,
    bool isPending,
    bool isNeedsReupload,
    bool isRejected,
    bool isOverdue,
    Map<String, dynamic>? pending,
    String schoolName,
  ) {
    if (isPaid) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isFullScholarship ? '100% Scholarship Enrolled' : 'Fee Paid & Cleared ✓',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF065F46)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isFullScholarship
                            ? 'All fees for $fullMonthTitle are covered by scholarship.'
                            : 'Payment has been verified & recorded in school database.',
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF047857)),
                      ),
                      if (breakdown.receiptNo != null && breakdown.receiptNo!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Receipt: ${breakdown.receiptNo}  •  Mode: ${breakdown.paymentMode ?? "Online"}',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF059669)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailedInvoiceScreen(
                        kid: kid,
                        month: MonthFee(
                          monthName: monthName,
                          monthNumber: _selectedMonthIdx + 1,
                          status: isPaid ? FeeStatus.paid : FeeStatus.pending,
                          amount: breakdown.totalPayable,
                          breakdown: breakdown,
                        ),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.download_rounded, color: Color(0xFF065F46), size: 18),
                label: Text(
                  'View & Download Official Invoice PDF',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF065F46)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF065F46),
                  side: const BorderSide(color: Color(0xFFA7F3D0)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (isPending) {
      return Container(
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
                        'Submitted via ${pending?['paymentMethod'] ?? 'Online / Bank'}',
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
                  child: Text('Pending', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Payment proof has been submitted for $fullMonthTitle. School administration will review and confirm shortly.',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.black87),
            ),
          ],
        ),
      );
    }

    if (isNeedsReupload || isRejected) {
      final isRej = isRejected;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isRej ? const Color(0xFFFEF2F2) : const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isRej ? const Color(0xFFFECACA) : const Color(0xFFFED7AA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isRej ? Colors.red.shade100 : Colors.orange.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isRej ? Icons.cancel_rounded : Icons.refresh_rounded,
                    color: isRej ? Colors.red.shade700 : Colors.orange.shade900,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isRej ? 'Payment Slip Rejected' : 'Slip Re-upload Requested',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isRej ? Colors.red.shade900 : Colors.orange.shade900,
                        ),
                      ),
                      Text(
                        'Action Required - Please Resubmit',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isRej ? Colors.red.shade700 : Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (pending?['rejectReason'] != null || pending?['message'] != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isRej ? Colors.red.shade200 : Colors.orange.shade200),
                ),
                child: Text(
                  pending?['rejectReason']?.toString() ?? pending?['message']?.toString() ?? 'Please upload a clearer receipt.',
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  PayFeeBottomSheet.show(
                    context,
                    kid,
                    breakdown.totalPayable,
                    feeMonth: fullMonthTitle,
                  );
                },
                icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 18),
                label: Text(
                  'Upload New Payment Slip',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRej ? Colors.red.shade700 : Colors.orange.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Unpaid & Ready to Pay
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              PayFeeBottomSheet.show(
                context,
                kid,
                breakdown.totalPayable,
                feeMonth: fullMonthTitle,
              );
            },
            icon: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
            label: Text(
              'Pay Fee for $monthName (Rs. ${breakdown.totalPayable.toStringAsFixed(0)})',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isOverdue ? Colors.red.shade700 : ThemeColors.primaryPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 3,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            'Transfer to school bank account and upload receipt screenshot.',
            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }

  // 5. Academic Year Quick Clearance Summary
  Widget _buildYearlyClearanceSummary(KidData kid, Map<String, dynamic> feeSettings) {
    int clearedMonthsCount = 0;
    const int totalMonths = 12;

    for (int i = 0; i < 12; i++) {
      final b = FeeCalculatorService.calculateItemizedFeeBreakdown(
        kid,
        targetMonthIdx: i,
        targetYear: _selectedYear,
        feeSettings: feeSettings,
      );
      if (b.isPaid || (b.isFullScholarship && b.totalPayable <= 0)) {
        clearedMonthsCount++;
      }
    }

    final double progress = (clearedMonthsCount / totalMonths).clamp(0.0, 1.0);
    final int percent = (progress * 100).toInt();
    final bool isAllCleared = clearedMonthsCount == totalMonths;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isAllCleared ? const Color(0xFF10B981) : ThemeColors.primaryPurple).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isAllCleared ? Icons.verified_rounded : Icons.pie_chart_rounded,
                        color: isAllCleared ? const Color(0xFF059669) : ThemeColors.primaryPurple,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Year $_selectedYear Clearance',
                        style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$clearedMonthsCount / 12 ($percent%)',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isAllCleared ? const Color(0xFF059669) : ThemeColors.primaryPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                isAllCleared ? const Color(0xFF10B981) : ThemeColors.primaryPurple,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isAllCleared
                ? '🌟 Outstanding! Full academic year has been completely settled.'
                : '$clearedMonthsCount months cleared, ${totalMonths - clearedMonthsCount} month(s) pending for $_selectedYear.',
            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
