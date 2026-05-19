import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../kids/providers/kids_provider.dart';

class InvoicePdfGenerator {
  static Future<File> generateInvoice({
    required KidData kid,
    required String schoolName,
    String? monthName,
  }) async {
    final pdf = pw.Document();

    bool isPaid = kid.monthlyFeeStatus.toLowerCase() == 'paid';
    double totalRecurring = 0;
    for (var fee in kid.feeStructure) {
      totalRecurring += (fee['amount'] as num?)?.toDouble() ?? 0.0;
    }

    double totalActions = 0;
    double paidActions = 0;
    for (var action in kid.individualActions) {
      totalActions += (action['amount'] as num?)?.toDouble() ?? 0.0;
      if (action['status'] == 'paid') {
        paidActions += (action['amount'] as num?)?.toDouble() ?? 0.0;
      }
    }

    double grandTotal = totalRecurring + totalActions;
    double totalPaid = (isPaid ? totalRecurring : 0) + paidActions;
    double totalDue = grandTotal - totalPaid;

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
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text(
                    'FEE RECEIPT',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text(
                    monthName != null ? 'Month: $monthName' : 'Date: ${DateTime.now().toIso8601String().substring(0, 10)}',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
                pw.SizedBox(height: 24),
                pw.Divider(color: PdfColors.grey400, borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 16),
                
                // Recurring Fees
                pw.Text('RECURRING FEES', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                pw.SizedBox(height: 8),
                if (kid.feeStructure.isEmpty)
                  pw.Text('  None', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                ...kid.feeStructure.map((f) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(f['name']?.toString() ?? 'Fee', style: const pw.TextStyle(fontSize: 14, color: PdfColors.black)),
                      pw.Text('Rs ${f['amount']}', style: const pw.TextStyle(fontSize: 14, color: PdfColors.black)),
                    ],
                  ),
                )).toList(),
                
                pw.SizedBox(height: 16),
                
                // Individual Actions
                pw.Text('INDIVIDUAL ACTIONS', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                pw.SizedBox(height: 8),
                if (kid.individualActions.isEmpty)
                  pw.Text('  None', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                ...kid.individualActions.map((a) {
                  bool actionPaid = a['status'] == 'paid';
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            '${a['name']} (${actionPaid ? 'paid' : 'unpaid'})', 
                            style: pw.TextStyle(fontSize: 14, color: actionPaid ? PdfColors.green700 : PdfColors.black)
                          )
                        ),
                        pw.Text('Rs ${a['amount']}', style: pw.TextStyle(fontSize: 14, color: actionPaid ? PdfColors.green700 : PdfColors.black)),
                      ],
                    ),
                  );
                }).toList(),
                
                pw.SizedBox(height: 16),
                pw.Divider(color: PdfColors.grey400, borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 16),
                
                // Totals
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOTAL BILL', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                    pw.Text('Rs $grandTotal', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('PAID AMOUNT', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
                    pw.Text('- Rs $totalPaid', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Divider(color: PdfColors.grey400, borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 16),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('AMOUNT DUE', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                    pw.Text('Rs $totalDue', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: totalDue > 0 ? PdfColors.red700 : PdfColors.green700)),
                  ],
                ),
                
                pw.SizedBox(height: 32),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: isPaid ? PdfColors.green : PdfColors.red, width: 2),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Text(
                      isPaid ? 'PAID' : 'UNPAID',
                      style: pw.TextStyle(
                        color: isPaid ? PdfColors.green : PdfColors.red,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final fileName = monthName != null ? 'Invoice_${monthName}_${DateTime.now().millisecondsSinceEpoch}.pdf' : 'Invoice_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
