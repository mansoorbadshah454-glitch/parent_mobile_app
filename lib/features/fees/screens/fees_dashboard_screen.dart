import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../kids/providers/kids_provider.dart';
import '../../kids/widgets/shining_profile_avatar.dart';
import '../widgets/pay_family_fee_bottom_sheet.dart';
import '../services/fee_calculator_service.dart';
import '../providers/fee_settings_provider.dart';
import 'fee_screen.dart';
import 'monthly_paid_receipts_screen.dart';

class FeesDashboardScreen extends ConsumerStatefulWidget {
  const FeesDashboardScreen({super.key});

  @override
  ConsumerState<FeesDashboardScreen> createState() => _FeesDashboardScreenState();
}

class _FeesDashboardScreenState extends ConsumerState<FeesDashboardScreen> {
  late int _selectedMonthIdx;
  late int _selectedYear;
  final ScrollController _timelineScrollController = ScrollController();
  bool _hasInitialScrolled = false;
  bool _hasSmartAutoSelected = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonthIdx = now.month - 1;
    _selectedYear = now.year;
  }

  @override
  void dispose() {
    _timelineScrollController.dispose();
    super.dispose();
  }

  /// Scans from January up to Current Month to find the earliest unpaid month
  int _determineEarliestDueMonth(List<KidData> kids, Map<String, dynamic> feeSettings) {
    final now = DateTime.now();
    final int currentMonthIdx = now.month - 1;
    final int currentYear = now.year;

    for (int m = 0; m <= currentMonthIdx; m++) {
      bool isMonthAllCleared = true;
      for (final kid in kids) {
        final breakdown = FeeCalculatorService.calculateItemizedFeeBreakdown(
          kid,
          targetMonthIdx: m,
          targetYear: currentYear,
          feeSettings: feeSettings,
        );
        final bool isPaid = breakdown.isPaid || (breakdown.isFullScholarship && breakdown.totalPayable <= 0);
        if (!isPaid) {
          isMonthAllCleared = false;
          break;
        }
      }

      // Earliest pending month found
      if (!isMonthAllCleared) {
        return m;
      }
    }

    return currentMonthIdx;
  }

  void _runInitialSmartMonthAutoSelect(List<KidData> kids, Map<String, dynamic> feeSettings) {
    if (_hasSmartAutoSelected || kids.isEmpty) return;
    _hasSmartAutoSelected = true;
    final smartMonthIdx = _determineEarliestDueMonth(kids, feeSettings);
    if (smartMonthIdx != _selectedMonthIdx) {
      _selectedMonthIdx = smartMonthIdx;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedMonth(force: true);
    });
  }

  void _scrollToSelectedMonth({bool force = false}) {
    if (!_timelineScrollController.hasClients) return;
    if (_hasInitialScrolled && !force) return;
    _hasInitialScrolled = true;
    final targetOffset = (_selectedMonthIdx * 118.0) - 20.0;
    _timelineScrollController.animateTo(
      targetOffset.clamp(0.0, _timelineScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final kidsAsyncValue = ref.watch(kidsProvider);
    final feeSettingsAsync = ref.watch(feeSettingsProvider);
    final feeSettings = feeSettingsAsync.value ?? <String, dynamic>{};
    final String dueDateStr = feeSettings['dueDate']?.toString().isNotEmpty == true
        ? feeSettings['dueDate'].toString()
        : '10th';

    return Scaffold(
      backgroundColor: ThemeColors.backgroundColor,
      body: Builder(
        builder: (context) {
          try {
            if (kidsAsyncValue.hasValue) {
              final kids = kidsAsyncValue.value ?? [];
              if (kids.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.family_restroom, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        const Text(
                          'No kids linked to this account.',
                          style: TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Auto-focus earliest unpaid month on initial load
              _runInitialSmartMonthAutoSelect(kids, feeSettings);

              final int totalKids = kids.length;
              int paidKids = 0;
              double totalUnpaidAmount = 0.0;
              final selectedMonthName = FeeCalculatorService.monthNames[_selectedMonthIdx];

              // Calculate financial summary for the SELECTED MONTH
              for (final kid in kids) {
                final breakdown = FeeCalculatorService.calculateItemizedFeeBreakdown(
                  kid,
                  targetMonthIdx: _selectedMonthIdx,
                  targetYear: _selectedYear,
                  feeSettings: feeSettings,
                );
                if (breakdown.isPaid || (breakdown.isFullScholarship && breakdown.totalPayable <= 0)) {
                  paidKids++;
                } else {
                  totalUnpaidAmount += breakdown.totalPayable;
                }
              }
              final int unpaidKids = totalKids - paidKids;

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                children: [
                  // 1. Dynamic Hero Financial Summary Card (Reacts to Selected Month)
                  _buildHeroFinancialCard(
                    context,
                    kids,
                    totalKids,
                    paidKids,
                    unpaidKids,
                    totalUnpaidAmount,
                    dueDateStr,
                    selectedMonthName,
                    _selectedMonthIdx,
                    _selectedYear,
                  ),
                  const SizedBox(height: 20),

                  // 2. Grand Family Monthly Timeline (Interactive Month Selection Ribbon)
                  _buildFamilyMonthlyTimeline(context, kids, _selectedYear, feeSettings),
                  const SizedBox(height: 24),

                  // 3. Section Title for Student Cards
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                'Student Fee Ledgers',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: ThemeColors.primaryPurple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$selectedMonthName $_selectedYear',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: ThemeColors.primaryPurple,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$totalKids Children',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 4. Children Cards List (Selected Month-Aware & Categorized)
                  ...kids.map((kid) => _buildStudentCard(context, kid, feeSettings)),

                  const SizedBox(height: 80),
                ],
              );
            }

            if (kidsAsyncValue.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: ThemeColors.primaryPurple),
              );
            }

            if (kidsAsyncValue.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Error loading fee data:\n${kidsAsyncValue.error}',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return const Center(
              child: CircularProgressIndicator(color: ThemeColors.primaryPurple),
            );
          } catch (e, stack) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: SelectableText(
                  'Crash caught in FeesDashboardScreen:\n$e\n\nStack:\n$stack',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  // 1. Dynamic Hero Financial Card with Status-Aware Gradient Colors
  Widget _buildHeroFinancialCard(
    BuildContext context,
    List<KidData> kids,
    int totalKids,
    int paidKids,
    int unpaidKids,
    double totalUnpaidAmount,
    String dueDateStr,
    String selectedMonthName,
    int targetMonthIdx,
    int targetYear,
  ) {
    final bool allCleared = unpaidKids == 0;
    final now = DateTime.now();
    final dueDay = int.tryParse(dueDateStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 10;

    // Determine status color logic:
    final bool isPastMonth = (targetYear < now.year) || (targetYear == now.year && targetMonthIdx < (now.month - 1));
    final bool isCurrentMonth = (targetYear == now.year && targetMonthIdx == (now.month - 1));
    final bool isPastDueDate = isCurrentMonth && (now.day > dueDay);
    final bool isOverdue = !allCleared && (isPastMonth || isPastDueDate);

    List<Color> gradientColors;
    Color shadowColor;
    String statusTitle;
    IconData statusIcon;

    if (allCleared) {
      gradientColors = const [Color(0xFF065F46), Color(0xFF059669)];
      shadowColor = const Color(0xFF059669);
      statusTitle = 'Family Dues Cleared';
      statusIcon = Icons.verified_rounded;
    } else if (isOverdue) {
      gradientColors = const [Color(0xFF881337), Color(0xFFE11D48)]; // Overdue Deep Red
      shadowColor = const Color(0xFFE11D48);
      statusTitle = 'Overdue Alert ($selectedMonthName)';
      statusIcon = Icons.warning_amber_rounded;
    } else {
      gradientColors = const [Color(0xFFB45309), Color(0xFFF59E0B)]; // Pending Warm Amber
      shadowColor = const Color(0xFFF59E0B);
      statusTitle = 'Pending Payment ($selectedMonthName)';
      statusIcon = Icons.hourglass_top_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
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
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        statusIcon,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            statusTitle,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Billing Month: $selectedMonthName $targetYear',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Due: $dueDateStr',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            allCleared ? 'Rs. 0 (All Settled! 🎉)' : 'Rs. ${totalUnpaidAmount.toStringAsFixed(0)}',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            allCleared
                ? 'All $totalKids children fees for $selectedMonthName are completely cleared.'
                : (isOverdue
                    ? '$unpaidKids of $totalKids child(ren) overdue for $selectedMonthName $targetYear.'
                    : '$unpaidKids of $totalKids child(ren) require payment for $selectedMonthName.'),
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 14),

          // Action Row / Status Pills
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildSummaryPill(
                icon: Icons.people_alt_rounded,
                label: '$totalKids Total',
                color: Colors.white.withOpacity(0.22),
              ),
              _buildSummaryPill(
                icon: Icons.check_circle_rounded,
                label: '$paidKids Cleared',
                color: const Color(0xFF10B981).withOpacity(0.4),
              ),
              if (unpaidKids > 0)
                _buildSummaryPill(
                  icon: Icons.hourglass_top_rounded,
                  label: '$unpaidKids Due',
                  color: Colors.white.withOpacity(0.25),
                ),
              if (paidKids > 0)
                _buildSummaryActionPill(
                  icon: Icons.receipt_long_rounded,
                  label: 'View Slips 🧾',
                  color: Colors.white.withOpacity(0.25),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MonthlyPaidReceiptsScreen(
                          kids: kids,
                          selectedMonthIdx: targetMonthIdx,
                          selectedYear: targetYear,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),

          if (unpaidKids > 0) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => PayFamilyFeeBottomSheet.show(
                  context,
                  kids,
                  feeMonth: '$selectedMonthName $targetYear',
                  targetMonthIdx: targetMonthIdx,
                  targetYear: targetYear,
                ),
                icon: const Icon(Icons.bolt_rounded, size: 18, color: ThemeColors.primaryPurple),
                label: Text(
                  'Pay Now! (Rs. ${totalUnpaidAmount.toStringAsFixed(0)})',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: ThemeColors.primaryPurple,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: ThemeColors.primaryPurple,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 3,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryPill({
    required IconData icon,
    required String label,
    required Color color,
    Color textColor = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryActionPill({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    Color textColor = Colors.white,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: textColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2. Grand Family Monthly Timeline (Months Ribbon Cards with Selection State)
  Widget _buildFamilyMonthlyTimeline(
    BuildContext context,
    List<KidData> kids,
    int currentYear,
    Map<String, dynamic> feeSettings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, size: 18, color: ThemeColors.primaryPurple),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Family Monthly Timeline ($currentYear)',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Select month',
              style: GoogleFonts.inter(fontSize: 11, color: ThemeColors.primaryPurple, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 108,
          child: ListView.builder(
            controller: _timelineScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: 12,
            itemBuilder: (context, idx) {
              final monthShort = FeeCalculatorService.monthShort[idx];
              final statusMap = _getFamilyMonthStatus(kids, idx, currentYear, feeSettings);

              final bool isSelected = (_selectedMonthIdx == idx);
              final bool allCleared = statusMap['allCleared'] as bool;
              final bool partialPaid = statusMap['partialPaid'] as bool;
              final int paidCount = statusMap['paidCount'] as int;
              final int totalKids = statusMap['totalKids'] as int;
              final double monthDue = statusMap['monthDue'] as double;
              final bool isCurrent = statusMap['isCurrent'] as bool;
              final bool isPastOrCurrent = statusMap['isPastOrCurrent'] as bool;

              Color bgColor;
              Color borderColor;
              Color textColor;
              String badgeText;

              if (allCleared) {
                bgColor = isSelected ? const Color(0xFFD1FAE5) : const Color(0xFFECFDF5);
                borderColor = isSelected ? const Color(0xFF059669) : const Color(0xFFA7F3D0);
                textColor = const Color(0xFF065F46);
                badgeText = 'All Cleared ✓';
              } else if (partialPaid) {
                bgColor = isSelected ? const Color(0xFFFEF3C7) : const Color(0xFFFFFBEB);
                borderColor = isSelected ? const Color(0xFFD97706) : const Color(0xFFFDE68A);
                textColor = const Color(0xFF92400E);
                badgeText = '$paidCount/$totalKids Paid';
              } else if (isPastOrCurrent) {
                bgColor = isSelected ? const Color(0xFFFEE2E2) : const Color(0xFFFEF2F2);
                borderColor = isSelected ? const Color(0xFFDC2626) : const Color(0xFFFECACA);
                textColor = const Color(0xFF991B1B);
                badgeText = 'Rs. ${monthDue.toStringAsFixed(0)}';
              } else {
                bgColor = isSelected ? Colors.purple.shade50 : Colors.grey.shade50;
                borderColor = isSelected ? ThemeColors.primaryPurple : Colors.grey.shade200;
                textColor = isSelected ? ThemeColors.primaryPurple : Colors.grey.shade600;
                badgeText = 'Upcoming';
              }

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedMonthIdx = idx;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 110,
                  margin: EdgeInsets.only(right: idx == 11 ? 0 : 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? (allCleared ? const Color(0xFF059669) : (isPastOrCurrent ? const Color(0xFFDC2626) : ThemeColors.primaryPurple)) : borderColor,
                      width: isSelected ? 2.2 : 1,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: (allCleared ? const Color(0xFF059669) : ThemeColors.primaryPurple).withOpacity(0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            monthShort,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.bold,
                              color: isSelected ? Colors.black : Colors.black87,
                            ),
                          ),
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: ThemeColors.primaryPurple,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('NOW', style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)),
                            )
                          else if (isSelected)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('VIEW', style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      Text(
                        allCleared
                            ? 'Paid ✓'
                            : (partialPaid ? 'Partial' : (isPastOrCurrent ? 'Due' : 'Upcoming')),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
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

  Map<String, dynamic> _getFamilyMonthStatus(
    List<KidData> kids,
    int monthIdx,
    int year,
    Map<String, dynamic> feeSettings,
  ) {
    int paidCount = 0;
    double monthDue = 0.0;
    final now = DateTime.now();

    for (final kid in kids) {
      final breakdown = FeeCalculatorService.calculateItemizedFeeBreakdown(
        kid,
        targetMonthIdx: monthIdx,
        targetYear: year,
        feeSettings: feeSettings,
      );
      if (breakdown.isPaid || (breakdown.isFullScholarship && breakdown.totalPayable <= 0)) {
        paidCount++;
      } else {
        monthDue += breakdown.totalPayable;
      }
    }

    final bool isPastOrCurrent = (year < now.year) || (year == now.year && monthIdx <= (now.month - 1));
    final bool allCleared = paidCount == kids.length;
    final bool partialPaid = paidCount > 0 && paidCount < kids.length;

    return {
      'allCleared': allCleared,
      'partialPaid': partialPaid,
      'paidCount': paidCount,
      'totalKids': kids.length,
      'monthDue': monthDue,
      'isPastOrCurrent': isPastOrCurrent,
      'isCurrent': year == now.year && monthIdx == (now.month - 1),
    };
  }

  // 4. Student Card (Selected Month-Aware & Direct Route to Dedicated Individual Fee Screen)
  Widget _buildStudentCard(BuildContext context, KidData kid, Map<String, dynamic> feeSettings) {
    final breakdown = FeeCalculatorService.calculateItemizedFeeBreakdown(
      kid,
      targetMonthIdx: _selectedMonthIdx,
      targetYear: _selectedYear,
      feeSettings: feeSettings,
    );
    final isPaid = breakdown.isPaid;
    final isFullScholarship = breakdown.isFullScholarship && breakdown.totalPayable <= 0;
    final isPending = breakdown.isPending || (kid.pendingPaymentSubmission != null &&
        (kid.pendingPaymentSubmission!['status'] ?? '').toString().trim().toLowerCase() == 'pending' &&
        _selectedMonthIdx == (DateTime.now().month - 1));
    final isRejected = kid.pendingPaymentSubmission != null &&
        (kid.pendingPaymentSubmission!['status'] ?? '').toString().trim().toLowerCase() == 'rejected' &&
        _selectedMonthIdx == (DateTime.now().month - 1);

    final String selectedMonthName = FeeCalculatorService.monthNames[_selectedMonthIdx];
    final String fullMonthTitle = '$selectedMonthName $_selectedYear';

    // Due Date and Difference Calculations
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = int.tryParse(feeSettings['dueDate']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '') ?? 10;
    final dueDate = DateTime(_selectedYear, _selectedMonthIdx + 1, dueDay);
    final int differenceDays = today.difference(dueDate).inDays;

    final bool isPastMonth = (_selectedYear < now.year) || (_selectedYear == now.year && _selectedMonthIdx < (now.month - 1));
    final bool isCurrentMonthPastDue = (_selectedYear == now.year && _selectedMonthIdx == (now.month - 1) && differenceDays > 0);
    final bool isOverdue = !isPaid && !isFullScholarship && (isPastMonth || isCurrentMonthPastDue);

    Color dueBadgeColor;
    String dueBadgeText;

    if (isPaid) {
      dueBadgeColor = const Color(0xFF059669);
      dueBadgeText = 'Fee Paid ✓';
    } else if (isFullScholarship) {
      dueBadgeColor = const Color(0xFF059669);
      dueBadgeText = '100% Scholarship';
    } else if (isRejected) {
      dueBadgeColor = Colors.red.shade700;
      dueBadgeText = 'Rejected / Action';
    } else if (isPending) {
      dueBadgeColor = Colors.amber.shade800;
      dueBadgeText = 'Under Review';
    } else if (isOverdue) {
      dueBadgeColor = Colors.red.shade700;
      dueBadgeText = 'Rs. ${breakdown.totalPayable.toStringAsFixed(0)} Overdue';
    } else {
      dueBadgeColor = ThemeColors.primaryPurple;
      dueBadgeText = 'Rs. ${breakdown.totalPayable.toStringAsFixed(0)} Due';
    }

    // Clean Status Strip Properties
    Color stripBg;
    Color stripBorder;
    Color stripTextColor;
    IconData stripIcon;
    String stripText;

    if (isPaid) {
      stripBg = const Color(0xFFECFDF5);
      stripBorder = const Color(0xFFA7F3D0);
      stripTextColor = const Color(0xFF065F46);
      stripIcon = Icons.check_circle_rounded;
      stripText = 'Fee Paid & Cleared for $fullMonthTitle ✓';
    } else if (isFullScholarship) {
      stripBg = const Color(0xFFECFDF5);
      stripBorder = const Color(0xFFA7F3D0);
      stripTextColor = const Color(0xFF065F46);
      stripIcon = Icons.school_rounded;
      stripText = '100% Scholarship Covered ($fullMonthTitle)';
    } else if (isRejected) {
      stripBg = const Color(0xFFFEF2F2);
      stripBorder = const Color(0xFFFECACA);
      stripTextColor = Colors.red.shade800;
      stripIcon = Icons.cancel_rounded;
      stripText = 'Payment Slip Rejected • Please Resubmit';
    } else if (isPending) {
      stripBg = const Color(0xFFFFFBEB);
      stripBorder = const Color(0xFFFDE68A);
      stripTextColor = const Color(0xFF92400E);
      stripIcon = Icons.hourglass_top_rounded;
      stripText = 'Payment Slip Under School Verification';
    } else if (differenceDays > 0) {
      // Overdue
      stripBg = const Color(0xFFFEF2F2);
      stripBorder = const Color(0xFFFECACA);
      stripTextColor = Colors.red.shade800;
      stripIcon = Icons.warning_amber_rounded;
      stripText = 'Due: ${dueDay}th $selectedMonthName $_selectedYear  •  $differenceDays Days Overdue';
    } else if (differenceDays == 0) {
      // Due Today
      stripBg = const Color(0xFFFFF7ED);
      stripBorder = const Color(0xFFFED7AA);
      stripTextColor = const Color(0xFFC2410C);
      stripIcon = Icons.alarm_rounded;
      stripText = 'Due Today (${dueDay}th $selectedMonthName $_selectedYear)';
    } else {
      // Upcoming
      final int daysRemaining = -differenceDays;
      stripBg = const Color(0xFFF8FAFC);
      stripBorder = const Color(0xFFE2E8F0);
      stripTextColor = Colors.blueGrey.shade700;
      stripIcon = Icons.event_note_rounded;
      stripText = 'Due: ${dueDay}th $selectedMonthName $_selectedYear  •  $daysRemaining Days Remaining';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOverdue ? Colors.red.shade200 : Colors.grey.shade200,
          width: isOverdue ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FeeScreen(
                kid: kid,
                initialMonthIdx: _selectedMonthIdx,
                initialYear: _selectedYear,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  // Preserved Shining Avatar
                  ShiningProfileAvatar(
                    imageUrl: kid.imageUrl,
                    radius: 28,
                    strokeWidth: 2.5,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kid.name,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ThemeColors.primaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Class: ${kid.className} • Roll: ${kid.rollNo}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: dueBadgeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: dueBadgeColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          dueBadgeText,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: dueBadgeColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            'View Fee Hub',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: ThemeColors.primaryPurple),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: ThemeColors.primaryPurple, size: 18),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              // Clean Bottom Status Strip (Due Date & Overdue Count)
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
                decoration: BoxDecoration(
                  color: stripBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: stripBorder),
                ),
                child: Row(
                  children: [
                    Icon(stripIcon, size: 14, color: stripTextColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        stripText,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: stripTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
