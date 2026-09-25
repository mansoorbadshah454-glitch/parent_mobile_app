import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../kids/providers/kids_provider.dart';
import '../services/fee_calculator_service.dart';

class InvoicePdfGenerator {
  static Future<File> generateInvoice({
    required KidData kid,
    required String schoolName,
    String? monthName,
    bool? isPaidOverride,
    ItemizedFeeBreakdown? breakdownOverride,
  }) async {
    final pdf = pw.Document();

    final breakdown = breakdownOverride ?? FeeCalculatorService.calculateItemizedFeeBreakdown(kid);
    final bool isPaid = isPaidOverride ?? breakdown.isPaid;
    final String targetMonthDisplay = monthName ?? breakdown.targetMonthName;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFFDFBF7),
              border: pw.Border.all(color: PdfColors.grey300, width: 2),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    schoolName.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: const PdfColor.fromInt(0xFF673AB7),
                      letterSpacing: 1,
                    ),
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Center(
                  child: pw.Text(
                    'OFFICIAL FEE INVOICE & RECEIPT',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Center(
                  child: pw.Text(
                    'Student: ${kid.name}  |  Class: ${kid.className}  |  Roll: ${kid.rollNo}',
                    style: const pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.grey800,
                    ),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    'Billing Month: $targetMonthDisplay  |  Issue Date: ${DateTime.now().toIso8601String().substring(0, 10)}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
                pw.SizedBox(height: 18),
                pw.Divider(color: PdfColors.grey400, borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 12),

                // 1. Recurring Fees Section
                pw.Text('1. MONTHLY TUITION & RECURRING CHARGES', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                pw.SizedBox(height: 6),
                if (breakdown.is100PercentFree)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Tuition Fee (100% Scholarship / Free-Ship)', style: const pw.TextStyle(fontSize: 11, color: PdfColors.green700)),
                      pw.Text('Rs. 0 (Fully Sponsored)', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
                    ],
                  )
                else ...[
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Base Tuition Fee', style: const pw.TextStyle(fontSize: 11, color: PdfColors.black)),
                      pw.Text('Rs. ${breakdown.baseTuition.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 11, color: PdfColors.black)),
                    ],
                  ),
                  if (breakdown.discountAmount > 0)
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 2),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Concession / Fee Discount', style: const pw.TextStyle(fontSize: 11, color: PdfColors.green700)),
                          pw.Text('- Rs. ${breakdown.discountAmount.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
                        ],
                      ),
                    ),
                  if (breakdown.transportFee > 0)
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 2),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Transport / Van Charges', style: const pw.TextStyle(fontSize: 11, color: PdfColors.black)),
                          pw.Text('Rs. ${breakdown.transportFee.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 11, color: PdfColors.black)),
                        ],
                      ),
                    ),
                  if (breakdown.recurringItems.isNotEmpty)
                    ...breakdown.recurringItems.map((fee) => pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 2),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(fee['name']?.toString() ?? 'Recurring Fee', style: const pw.TextStyle(fontSize: 11, color: PdfColors.black)),
                          pw.Text('Rs. ${FeeCalculatorService.parseDouble(fee['amount']).toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 11, color: PdfColors.black)),
                        ],
                      ),
                    )),
                ],

                // 2. Store Items Section
                if (breakdown.storeItems.isNotEmpty) ...[
                  pw.SizedBox(height: 12),
                  pw.Text('2. STORE CHARGES (UNIFORM & BOOKS THIS MONTH)', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                  pw.SizedBox(height: 6),
                  ...breakdown.storeItems.map((item) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(item['name']?.toString() ?? 'Store Item', style: const pw.TextStyle(fontSize: 10, color: PdfColors.black)),
                        pw.Text('Rs. ${FeeCalculatorService.parseDouble(item['amount']).toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.black)),
                      ],
                    ),
                  )),
                ],

                // 3. Custom Actions Section
                if (breakdown.customItems.isNotEmpty) ...[
                  pw.SizedBox(height: 12),
                  pw.Text('3. SPECIAL ACTIONS & EXAMS (THIS MONTH)', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                  pw.SizedBox(height: 6),
                  ...breakdown.customItems.map((item) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(item['name']?.toString() ?? 'Action', style: const pw.TextStyle(fontSize: 10, color: PdfColors.black)),
                        pw.Text('Rs. ${FeeCalculatorService.parseDouble(item['amount']).toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.black)),
                      ],
                    ),
                  )),
                ],

                if (breakdown.penaltyFine > 0) ...[
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Late Payment Penalty', style: const pw.TextStyle(fontSize: 11, color: PdfColors.red700)),
                      pw.Text('Rs. ${breakdown.penaltyFine.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 11, color: PdfColors.red700)),
                    ],
                  ),
                ],

                pw.SizedBox(height: 14),
                pw.Divider(color: PdfColors.grey400, borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 10),

                // Totals
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOTAL INVOICE AMOUNT', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                    pw.Text('Rs. ${breakdown.totalPayable.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                  ],
                ),
                if (isPaid) ...[
                  pw.SizedBox(height: 6),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('SETTLED / PAID AMOUNT', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
                      pw.Text('- Rs. ${(breakdown.paidAmount > 0 ? breakdown.paidAmount : breakdown.totalPayable).toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
                    ],
                  ),
                ],

                pw.SizedBox(height: 8),
                pw.Divider(color: PdfColors.grey400, borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('NET BALANCE DUE', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                    pw.Text(
                      isPaid ? 'Rs. 0' : 'Rs. ${breakdown.totalPayable.toStringAsFixed(0)}',
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: isPaid ? PdfColors.green700 : PdfColors.red700),
                    ),
                  ],
                ),

                pw.SizedBox(height: 24),

                // Settlement Badge & Verification Box
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: isPaid ? PdfColors.green : PdfColors.red, width: 1.5),
                    borderRadius: pw.BorderRadius.circular(8),
                    color: isPaid ? const PdfColor.fromInt(0xFFECFDF5) : const PdfColor.fromInt(0xFFFEF2F2),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            isPaid ? 'STATUS: PAID & VERIFIED ✓' : 'STATUS: PAYMENT DUE / UNPAID',
                            style: pw.TextStyle(
                              color: isPaid ? PdfColors.green800 : PdfColors.red800,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          if (isPaid && breakdown.receiptNo != null)
                            pw.Text(
                              'Receipt No: ${breakdown.receiptNo} | Mode: ${breakdown.paymentMode ?? 'Online Transfer'}',
                              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                            ),
                        ],
                      ),
                      pw.Text(
                        isPaid ? 'CLEARED' : 'PENDING',
                        style: pw.TextStyle(
                          color: isPaid ? PdfColors.green700 : PdfColors.red700,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final fileName = 'Invoice_${kid.name.replaceAll(' ', '_')}_${targetMonthDisplay.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
