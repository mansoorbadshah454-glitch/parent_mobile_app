import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../kids/providers/kids_provider.dart';
import '../services/fee_calculator_service.dart';
import '../utils/invoice_pdf_generator.dart';

class FeeReceiptWidget extends StatelessWidget {
  final KidData kid;
  final String schoolName;
  final String? monthName;
  final bool? isPaidOverride;
  final ItemizedFeeBreakdown? breakdownOverride;

  const FeeReceiptWidget({
    super.key,
    required this.kid,
    required this.schoolName,
    this.monthName,
    this.isPaidOverride,
    this.breakdownOverride,
  });

  @override
  Widget build(BuildContext context) {
    final breakdown = breakdownOverride ??
        FeeCalculatorService.calculateItemizedFeeBreakdown(
          kid,
          targetMonthKey: monthName,
        );
    final bool isPaid = isPaidOverride ?? breakdown.isPaid;
    final String activeMonth = monthName ?? breakdown.targetMonthName;
    final bool is100PercentFree = breakdown.is100PercentFree;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isPaid ? const Color(0xFFECFDF5) : ThemeColors.primaryPurple.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: isPaid ? const Color(0xFFA7F3D0) : Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schoolName,
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Official Fee Voucher • $activeMonth',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPaid ? const Color(0xFF059669) : ThemeColors.primaryPurple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isPaid ? 'PAID ✓' : 'UNPAID',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // Student Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Student Name:', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        kid.name,
                        textAlign: TextAlign.end,
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Class & Roll No:', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${kid.className} (${kid.rollNo})',
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (breakdown.receiptNo != null && breakdown.receiptNo!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Receipt Number:', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          breakdown.receiptNo!,
                          textAlign: TextAlign.end,
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF059669)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Itemized Breakdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Base Tuition Fee',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('Rs. ${breakdown.baseTuition.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                  ],
                ),
                if (breakdown.discountAmount > 0 || is100PercentFree) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          is100PercentFree ? 'Scholarship Waiver' : 'Concession / Discount',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('- Rs. ${(is100PercentFree ? breakdown.baseTuition : breakdown.discountAmount).toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
                if (breakdown.transportFee > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text('Transport Charges', style: TextStyle(fontSize: 12, color: Colors.black87)),
                      ),
                      const SizedBox(width: 8),
                      Text('Rs. ${breakdown.transportFee.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                    ],
                  ),
                ],
                if (breakdown.recurringItems.isNotEmpty) ...[
                  for (var fee in breakdown.recurringItems) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            fee['name']?.toString() ?? 'Recurring Fee',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF0D9488), fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('Rs. ${fee['amount']}', style: const TextStyle(fontSize: 12, color: Color(0xFF0D9488), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ],
                if (breakdown.storeItems.isNotEmpty) ...[
                  for (var item in breakdown.storeItems) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item['name']?.toString() ?? 'Store Item',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF7C3AED)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('Rs. ${item['amount']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF7C3AED))),
                      ],
                    ),
                  ],
                ],
                if (breakdown.actions.isNotEmpty) ...[
                  for (var act in breakdown.actions) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            act['name']?.toString() ?? 'Activity',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF0284C7)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('Rs. ${act['amount']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0284C7))),
                      ],
                    ),
                  ],
                ],
                if (breakdown.penaltyFine > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text('Late Fine / Penalty', style: TextStyle(fontSize: 12, color: Colors.red)),
                      ),
                      const SizedBox(width: 8),
                      Text('Rs. ${breakdown.penaltyFine.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Total Amount',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Rs. ${breakdown.totalPayable.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 18,
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
}

class DownloadableInvoice extends StatefulWidget {
  final KidData kid;
  final String schoolName;
  final String? monthName;
  final bool? isPaid;
  final ItemizedFeeBreakdown? breakdown;

  const DownloadableInvoice({
    super.key,
    required this.kid,
    required this.schoolName,
    this.monthName,
    this.isPaid,
    this.breakdown,
  });

  @override
  State<DownloadableInvoice> createState() => _DownloadableInvoiceState();
}

class _DownloadableInvoiceState extends State<DownloadableInvoice> {
  bool _isDownloading = false;

  Future<void> _downloadInvoice() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final pdfFile = await InvoicePdfGenerator.generateInvoice(
        kid: widget.kid,
        schoolName: widget.schoolName,
        monthName: widget.monthName,
        isPaidOverride: widget.isPaid,
        breakdownOverride: widget.breakdown,
      );

      if (mounted) {
        // Use share_plus to open native share/save dialogue
        final xFile = XFile(pdfFile.path);
        await Share.shareXFiles(
          [xFile],
          text: 'Fee Invoice - ${widget.schoolName}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Displays the visual receipt
        FeeReceiptWidget(
          kid: widget.kid,
          schoolName: widget.schoolName,
          monthName: widget.monthName,
          isPaidOverride: widget.isPaid,
          breakdownOverride: widget.breakdown,
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _isDownloading ? null : _downloadInvoice,
          icon: _isDownloading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(color: ThemeColors.primaryPurple, strokeWidth: 1.5),
                )
              : const Icon(Icons.picture_as_pdf_outlined, color: ThemeColors.primaryPurple, size: 16),
          label: Text(
            _isDownloading ? 'Generating PDF...' : 'Download Official PDF Voucher',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: ThemeColors.primaryPurple),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            side: BorderSide(color: ThemeColors.primaryPurple.withOpacity(0.35), width: 1.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: ThemeColors.primaryPurple.withOpacity(0.04),
          ),
        ),
      ],
    );
  }
}
