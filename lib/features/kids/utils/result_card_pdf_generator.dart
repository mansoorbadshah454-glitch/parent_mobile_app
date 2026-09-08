import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../providers/exam_results_provider.dart';

class ResultCardPdfGenerator {
  static Future<Uint8List?> _fetchImageBytes(String? url) async {
    if (url == null || url.trim().isEmpty) return null;
    try {
      final uri = Uri.parse(url);
      final request = await HttpClient().getUrl(uri);
      final response = await request.close();
      if (response.statusCode == 200) {
        final List<int> bytes = [];
        await for (var chunk in response) {
          bytes.addAll(chunk);
        }
        return Uint8List.fromList(bytes);
      }
    } catch (_) {}
    return null;
  }

  static Future<File> generateDmcPdf({
    required StudentExamResult result,
    required String schoolName,
    String? schoolAddress,
    String? schoolLogoUrl,
    Uint8List? schoolLogoBytes,
  }) async {
    final pdf = pw.Document();

    final isPassed = result.isPassed;
    final primaryColor = PdfColor.fromInt(0xFF4A148C); // Deep purple
    final successColor = PdfColor.fromInt(0xFF2E7D32); // Green
    final dangerColor = PdfColor.fromInt(0xFFC62828); // Red
    final statusColor = isPassed ? successColor : dangerColor;

    Uint8List? logoBytes = schoolLogoBytes;
    if (logoBytes == null && schoolLogoUrl != null && schoolLogoUrl.isNotEmpty) {
      logoBytes = await _fetchImageBytes(schoolLogoUrl);
    }
    pw.MemoryImage? logoImage;
    if (logoBytes != null && logoBytes.isNotEmpty) {
      try {
        logoImage = pw.MemoryImage(logoBytes);
      } catch (_) {}
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: primaryColor, width: 2.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // 1. School Header with optional Logo
                pw.Center(
                  child: pw.Column(
                    children: [
                      if (logoImage != null) ...[
                        pw.Container(
                          width: 52,
                          height: 52,
                          margin: const pw.EdgeInsets.only(bottom: 8),
                          decoration: pw.BoxDecoration(
                            shape: pw.BoxShape.circle,
                            border: pw.Border.all(color: primaryColor, width: 1.5),
                          ),
                          child: pw.ClipOval(
                            child: pw.Image(logoImage, fit: pw.BoxFit.cover),
                          ),
                        ),
                      ],
                      pw.Text(
                        schoolName.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      if (schoolAddress != null && schoolAddress.isNotEmpty) ...[
                        pw.SizedBox(height: 3),
                        pw.Text(
                          schoolAddress,
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                          textAlign: pw.TextAlign.center,
                        ),
                      ],
                      pw.SizedBox(height: 6),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: primaryColor,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                        ),
                        child: pw.Text(
                          'DETAILED MARKS CERTIFICATE (DMC) - ${result.examTitle.toUpperCase()}',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 18),

                // 2. Student Info Box
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFF9F9FB),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _infoRow('Student Name:', result.studentName),
                          pw.SizedBox(height: 5),
                          _infoRow('Father Name:', result.fatherName.isNotEmpty ? result.fatherName : '-'),
                          pw.SizedBox(height: 5),
                          _infoRow('Class:', result.className),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _infoRow('Roll No:', result.rollNumber),
                          pw.SizedBox(height: 5),
                          _infoRow('Position:', result.position.isNotEmpty && result.position != '-' ? '${result.position}' : 'N/A'),
                          pw.SizedBox(height: 5),
                          _infoRow('Attendance:', result.attendance.isNotEmpty ? result.attendance : 'Regular'),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 18),

                // 3. Subject-wise Marks Table
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.8),
                  children: [
                    // Header Row
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFEDE7F6)),
                      children: [
                        _tableHeaderCell('Subject', flex: 3),
                        _tableHeaderCell('Max Marks'),
                        _tableHeaderCell('Passing'),
                        _tableHeaderCell('Obtained'),
                        _tableHeaderCell('Grade'),
                        _tableHeaderCell('Remarks', flex: 2),
                      ],
                    ),
                    // Subject Rows
                    ...result.subjectMarks.entries.map((entry) {
                      final s = entry.value;
                      final isSubjPass = !s.isAbsent && (s.obtained ?? 0) >= s.passingMarks;
                      final obtText = s.isAbsent ? 'ABS' : (s.obtained != null ? '${s.obtained}' : '-');

                      return pw.TableRow(
                        children: [
                          _tableDataCell(entry.key, align: pw.TextAlign.left, flex: 3, isBold: true),
                          _tableDataCell('${s.totalMarks}'),
                          _tableDataCell('${s.passingMarks}'),
                          _tableDataCell(
                            obtText,
                            textColor: s.isAbsent ? dangerColor : (isSubjPass ? PdfColors.black : dangerColor),
                            isBold: true,
                          ),
                          _tableDataCell(s.grade),
                          _tableDataCell(s.remarks.isNotEmpty ? s.remarks : (isSubjPass ? 'Good' : 'Needs Focus'), align: pw.TextAlign.left, flex: 2),
                        ],
                      );
                    }).toList(),
                  ],
                ),
                pw.SizedBox(height: 16),

                // 4. Grand Total & Result Summary Box
                pw.Container(
                  padding: const pw.EdgeInsets.all(14),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFF3E5F5),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    border: pw.Border.all(color: primaryColor, width: 1.2),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Total Marks: ${result.totalObtained} / ${result.totalMax}',
                            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: primaryColor),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Percentage: ${result.percentage.toStringAsFixed(1)}%',
                            style: const pw.TextStyle(fontSize: 12, color: PdfColors.black),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            'Grade: ${result.grade}',
                            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryColor),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: pw.BoxDecoration(
                              color: statusColor,
                              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                            ),
                            child: pw.Text(
                              result.statusLabel.toUpperCase(),
                              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.Spacer(),

                // 5. Signatures
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _signatureBox('Class Teacher'),
                    _signatureBox('Controller of Exams'),
                    _signatureBox('Principal Stamp & Sign'),
                  ],
                ),
                pw.SizedBox(height: 14),

                // 6. Security Footer
                pw.Center(
                  child: pw.Text(
                    'Official Digital DMC • Generated securely via Smart School Portal • ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    final outputDir = await getTemporaryDirectory();
    final cleanStudentName = result.studentName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final cleanExamTitle = result.examTitle.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final file = File('${outputDir.path}/${cleanStudentName}_${cleanExamTitle}_DMC.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
        ),
        pw.SizedBox(width: 6),
        pw.Text(
          value,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.black),
        ),
      ],
    );
  }

  static pw.Widget _tableHeaderCell(String text, {int flex = 1}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF4A148C)),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _tableDataCell(
    String text, {
    int flex = 1,
    pw.TextAlign align = pw.TextAlign.center,
    PdfColor textColor = PdfColors.black,
    bool isBold = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9.5,
          color: textColor,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _signatureBox(String title) {
    return pw.Column(
      children: [
        pw.Container(
          width: 130,
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: PdfColors.grey600, width: 1)),
          ),
          padding: const pw.EdgeInsets.only(top: 4),
          child: pw.Text(
            title,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ],
    );
  }
}
