import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../kids/providers/kids_provider.dart';
import '../../kids/widgets/shining_profile_avatar.dart';
import '../../../core/providers/parent_data_provider.dart';
import '../providers/fee_settings_provider.dart';
import '../services/fee_calculator_service.dart';
import '../utils/invoice_pdf_generator.dart';
import '../widgets/downloadable_invoice.dart';

class MonthlyPaidReceiptsScreen extends ConsumerStatefulWidget {
  final List<KidData> kids;
  final int selectedMonthIdx;
  final int selectedYear;
  final int initialKidIdx;

  const MonthlyPaidReceiptsScreen({
    super.key,
    required this.kids,
    required this.selectedMonthIdx,
    required this.selectedYear,
    this.initialKidIdx = 0,
  });

  @override
  ConsumerState<MonthlyPaidReceiptsScreen> createState() => _MonthlyPaidReceiptsScreenState();
}

class _MonthlyPaidReceiptsScreenState extends ConsumerState<MonthlyPaidReceiptsScreen> {
  late int _activeKidIdx;
  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    _activeKidIdx = widget.initialKidIdx.clamp(0, widget.kids.isNotEmpty ? widget.kids.length - 1 : 0);
  }

  Future<void> _downloadOrSharePdf({required bool isShare, required KidData kid, required String schoolName, required ItemizedFeeBreakdown breakdown, required String monthName}) async {
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final File pdfFile = await InvoicePdfGenerator.generateInvoice(
        kid: kid,
        schoolName: schoolName,
        monthName: monthName,
        isPaidOverride: true,
        breakdownOverride: breakdown,
      );

      if (!mounted) return;

      if (isShare) {
        final xFile = XFile(pdfFile.path);
        await Share.shareXFiles(
          [xFile],
          text: 'Official Fee Receipt for ${kid.name} ($monthName) - $schoolName',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Receipt PDF saved to device successfully! 📄',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to process PDF receipt: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final kidsAsync = ref.watch(kidsProvider);
    final currentKidsList = kidsAsync.value ?? widget.kids;

    final parentDataAsync = ref.watch(parentDataProvider);
    final String schoolName = parentDataAsync.value?.schoolName ?? 'School';

    final feeSettingsAsync = ref.watch(feeSettingsProvider);
    final feeSettings = feeSettingsAsync.value ?? <String, dynamic>{};

    final String selectedMonthName = FeeCalculatorService.monthNames[widget.selectedMonthIdx];
    final String fullMonthTitle = '$selectedMonthName ${widget.selectedYear}';

    final KidData activeKid = currentKidsList.isNotEmpty
        ? currentKidsList[_activeKidIdx.clamp(0, currentKidsList.length - 1)]
        : widget.kids.first;

    final breakdown = FeeCalculatorService.calculateItemizedFeeBreakdown(
      activeKid,
      targetMonthIdx: widget.selectedMonthIdx,
      targetYear: widget.selectedYear,
      feeSettings: feeSettings,
    );

    // Calculate total family paid amount for this month
    double totalFamilyPaid = 0.0;
    int clearedCount = 0;
    for (final k in currentKidsList) {
      final b = FeeCalculatorService.calculateItemizedFeeBreakdown(
        k,
        targetMonthIdx: widget.selectedMonthIdx,
        targetYear: widget.selectedYear,
        feeSettings: feeSettings,
      );
      if (b.isPaid || (b.isFullScholarship && b.totalPayable <= 0)) {
        clearedCount++;
        totalFamilyPaid += b.totalPayable;
      }
    }

    return Scaffold(
      backgroundColor: ThemeColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: ThemeColors.primaryPurple,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$selectedMonthName Paid Receipts',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
            ),
            Text(
              'Official Verified School Vouchers',
              style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.85)),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Share Receipt',
            icon: _isGeneratingPdf
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.share_rounded, color: Colors.white),
            onPressed: _isGeneratingPdf
                ? null
                : () => _downloadOrSharePdf(
                      isShare: true,
                      kid: activeKid,
                      schoolName: schoolName,
                      breakdown: breakdown,
                      monthName: fullMonthTitle,
                    ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Family Cleared Grand Hero Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF065F46), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF059669).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Family Month Cleared',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text('🎉', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$clearedCount of ${currentKidsList.length} children settled for $fullMonthTitle.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 2. Child Selector Ribbon (If Family has multiple kids)
            if (currentKidsList.length > 1) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Child Voucher',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '${_activeKidIdx + 1} of ${currentKidsList.length}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 52,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: currentKidsList.length,
                  itemBuilder: (context, idx) {
                    final kid = currentKidsList[idx];
                    final isSelected = (_activeKidIdx == idx);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _activeKidIdx = idx;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: EdgeInsets.only(right: idx == currentKidsList.length - 1 ? 0 : 10),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? ThemeColors.primaryPurple : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? ThemeColors.primaryPurple : Colors.grey.shade300,
                            width: isSelected ? 1.8 : 1,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: ThemeColors.primaryPurple.withOpacity(0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ShiningProfileAvatar(
                              imageUrl: kid.imageUrl,
                              radius: 15,
                              strokeWidth: 1.5,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              kid.name,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.check_circle_rounded,
                              size: 14,
                              color: isSelected ? Colors.greenAccent : const Color(0xFF059669),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
            ],

            // 3. Official Fee Voucher Preview
            FeeReceiptWidget(
              kid: activeKid,
              schoolName: schoolName,
              monthName: fullMonthTitle,
              isPaidOverride: true,
              breakdownOverride: breakdown,
            ),
            const SizedBox(height: 20),

            // 4. Action Buttons (Download PDF & Share)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isGeneratingPdf
                        ? null
                        : () => _downloadOrSharePdf(
                              isShare: false,
                              kid: activeKid,
                              schoolName: schoolName,
                              breakdown: breakdown,
                              monthName: fullMonthTitle,
                            ),
                    icon: _isGeneratingPdf
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.download_rounded, size: 18, color: Colors.white),
                    label: Text(
                      'Download PDF',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isGeneratingPdf
                        ? null
                        : () => _downloadOrSharePdf(
                              isShare: true,
                              kid: activeKid,
                              schoolName: schoolName,
                              breakdown: breakdown,
                              monthName: fullMonthTitle,
                            ),
                    icon: const Icon(Icons.share_rounded, size: 18, color: ThemeColors.primaryPurple),
                    label: Text(
                      'Share Voucher',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: ThemeColors.primaryPurple),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ThemeColors.primaryPurple,
                      side: const BorderSide(color: ThemeColors.primaryPurple, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
