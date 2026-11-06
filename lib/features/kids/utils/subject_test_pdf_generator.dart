import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../kids/providers/kids_provider.dart';

class SubjectTestPdfGenerator {
  static const PdfColor _primaryIndigo = PdfColor.fromInt(0xFF4F46E5);
  static const PdfColor _slateDark = PdfColor.fromInt(0xFF0F172A);
  static const PdfColor _slateText = PdfColor.fromInt(0xFF334155);
  static const PdfColor _slateLight = PdfColor.fromInt(0xFF64748B);
  static const PdfColor _borderColor = PdfColor.fromInt(0xFFE2E8F0);
  static const PdfColor _bgSoft = PdfColor.fromInt(0xFFF8FAFC);
  static const PdfColor _emeraldGreen = PdfColor.fromInt(0xFF10B981);
  static const PdfColor _roseRed = PdfColor.fromInt(0xFFEF4444);
  static const PdfColor _amberOrange = PdfColor.fromInt(0xFFF59E0B);

  static final Map<String, Uint8List> _imageCache = {};

  static Future<Uint8List?> _fetchImageBytes(String? url) async {
    if (url == null || url.trim().isEmpty) return null;
    final cleanUrl = url.trim();
    if (_imageCache.containsKey(cleanUrl)) {
      return _imageCache[cleanUrl];
    }
    try {
      final uri = Uri.parse(cleanUrl);
      final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 2000);
      final request = await client.getUrl(uri).timeout(const Duration(milliseconds: 2000));
      final response = await request.close().timeout(const Duration(milliseconds: 2000));
      if (response.statusCode == 200) {
        final List<int> bytes = [];
        await for (var chunk in response) {
          bytes.addAll(chunk);
        }
        final result = Uint8List.fromList(bytes);
        _imageCache[cleanUrl] = result;
        return result;
      }
    } catch (_) {}
    return null;
  }

  static Future<File> generateSubjectReportPdf({
    required KidData kid,
    required String subject,
    required List<Map<String, dynamic>> testReports,
    required String schoolName,
    String? schoolLogoUrl,
  }) async {
    final pdf = pw.Document();

    // Fetch School Logo
    Uint8List? logoBytes;
    if (schoolLogoUrl != null && schoolLogoUrl.isNotEmpty) {
      try {
        logoBytes = await _fetchImageBytes(schoolLogoUrl);
      } catch (_) {}
    }

    // Performance Calculations
    int totalTests = testReports.length;
    int presentTests = 0;
    int absentTests = 0;
    num totalPossibleMarks = 0;
    num totalObtainedMarks = 0;

    for (var test in testReports) {
      final isAbsent = test['isAbsent'] == true;
      final maxM = num.tryParse(test['maxMarks']?.toString() ?? '10') ?? 10;
      totalPossibleMarks += maxM;

      if (isAbsent) {
        absentTests++;
      } else {
        presentTests++;
        final obt = num.tryParse(test['score']?.toString() ?? '0') ?? 0;
        totalObtainedMarks += obt;
      }
    }

    double overallPercentage = totalPossibleMarks > 0
        ? (totalObtainedMarks / totalPossibleMarks) * 100
        : 0.0;

    String overallGrade = '-';
    PdfColor gradeColor = _slateDark;
    if (overallPercentage >= 90) {
      overallGrade = 'A+ (Outstanding)';
      gradeColor = _emeraldGreen;
    } else if (overallPercentage >= 80) {
      overallGrade = 'A (Excellent)';
      gradeColor = _emeraldGreen;
    } else if (overallPercentage >= 70) {
      overallGrade = 'B (Very Good)';
      gradeColor = _primaryIndigo;
    } else if (overallPercentage >= 60) {
      overallGrade = 'C (Good)';
      gradeColor = _amberOrange;
    } else if (overallPercentage >= 50) {
      overallGrade = 'D (Fair)';
      gradeColor = _amberOrange;
    } else {
      overallGrade = 'E (Needs Improvement)';
      gradeColor = _roseRed;
    }

    final currentDateStr = DateFormat('dd MMM yyyy').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // 1. Header Banner
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: pw.BoxDecoration(
                color: _primaryIndigo,
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logoBytes != null && logoBytes.isNotEmpty)
                    pw.Container(
                      width: 52,
                      height: 52,
                      margin: const pw.EdgeInsets.only(right: 14),
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        color: PdfColors.white,
                        image: pw.DecorationImage(
                          image: pw.MemoryImage(logoBytes),
                          fit: pw.BoxFit.cover,
                        ),
                      ),
                    ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          schoolName.isNotEmpty ? schoolName : 'Smart School System',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'STUDENT ACADEMIC TEST REPORT • $subject',
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'ISSUED',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: _slateLight,
                          ),
                        ),
                        pw.Text(
                          currentDateStr,
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: _slateDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 16),

            // 2. Student Info & Subject Snapshot
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: _bgSoft,
                borderRadius: pw.BorderRadius.circular(10),
                border: pw.Border.all(color: _borderColor),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildInfoLabel('STUDENT NAME', kid.name.isNotEmpty ? kid.name : 'N/A'),
                      pw.SizedBox(height: 6),
                      _buildInfoLabel('CLASS & SECTION', kid.className.isNotEmpty ? kid.className : 'N/A'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildInfoLabel('ROLL NUMBER', kid.rollNo.isNotEmpty ? kid.rollNo : 'N/A'),
                      pw.SizedBox(height: 6),
                      _buildInfoLabel('SUBJECT', subject),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildInfoLabel('TOTAL TESTS', '$totalTests Tests'),
                      pw.SizedBox(height: 6),
                      _buildInfoLabel('OVERALL GRADE', overallGrade, valueColor: gradeColor),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 16),

            // 3. Overall Statistics Cards
            pw.Row(
              children: [
                _buildStatPill('Total Tests', '$totalTests', _primaryIndigo),
                pw.SizedBox(width: 8),
                _buildStatPill('Present', '$presentTests', _emeraldGreen),
                pw.SizedBox(width: 8),
                _buildStatPill('Absent', '$absentTests', absentTests > 0 ? _roseRed : _slateLight),
                pw.SizedBox(width: 8),
                _buildStatPill('Total Score', '$totalObtainedMarks / $totalPossibleMarks', _slateDark),
                pw.SizedBox(width: 8),
                _buildStatPill('Overall %', '${overallPercentage.toStringAsFixed(1)}%', gradeColor),
              ],
            ),

            pw.SizedBox(height: 20),

            // 4. Test Records Table
            pw.Text(
              'DETAILED TEST HISTORY',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: _slateDark,
              ),
            ),
            pw.SizedBox(height: 8),

            pw.Table(
              border: pw.TableBorder.all(color: _borderColor, width: 0.7),
              columnWidths: {
                0: const pw.FixedColumnWidth(26), // #
                1: const pw.FixedColumnWidth(64), // Date
                2: const pw.FixedColumnWidth(60), // Type
                3: const pw.FlexColumnWidth(3),   // Chapter / Topic
                4: const pw.FixedColumnWidth(48), // Max
                5: const pw.FixedColumnWidth(54), // Obtained
                6: const pw.FixedColumnWidth(44), // %
                7: const pw.FixedColumnWidth(64), // Status
              },
              children: [
                // Table Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: _bgSoft),
                  children: [
                    _buildTableHeader('#'),
                    _buildTableHeader('Date'),
                    _buildTableHeader('Type'),
                    _buildTableHeader('Chapter / Syllabus'),
                    _buildTableHeader('Max'),
                    _buildTableHeader('Score'),
                    _buildTableHeader('%'),
                    _buildTableHeader('Status'),
                  ],
                ),
                // Table Rows
                ...testReports.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final test = entry.value;
                  final isAbsent = test['isAbsent'] == true;
                  final maxM = num.tryParse(test['maxMarks']?.toString() ?? '10') ?? 10;
                  final obt = isAbsent ? null : num.tryParse(test['score']?.toString() ?? '0');
                  
                  final dateStr = test['date'] ?? test['dateStr'] ?? 'TBD';
                  String formattedDate = dateStr;
                  try {
                    if (dateStr != 'TBD' && dateStr.isNotEmpty) {
                      final dt = DateTime.parse(dateStr);
                      formattedDate = DateFormat('dd/MM/yy').format(dt);
                    }
                  } catch (_) {}

                  final testType = test['testType'] ?? 'Written';
                  final chapter = test['chapter'] ?? 'Chapter Assessment';
                  final topic = test['paragraphs'] ?? '';
                  final syllabusText = topic.isNotEmpty ? '$chapter ($topic)' : chapter;

                  double pct = 0;
                  if (!isAbsent && obt != null && maxM > 0) {
                    pct = (obt / maxM) * 100;
                  }

                  String statusText = 'Pass';
                  PdfColor statusColor = _emeraldGreen;
                  if (isAbsent) {
                    statusText = 'ABSENT';
                    statusColor = _roseRed;
                  } else if (pct >= 85) {
                    statusText = 'Distinction';
                    statusColor = _emeraldGreen;
                  } else if (pct >= 50) {
                    statusText = 'Pass';
                    statusColor = _primaryIndigo;
                  } else {
                    statusText = 'Needs Work';
                    statusColor = _amberOrange;
                  }

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: entry.key % 2 == 0 ? PdfColors.white : _bgSoft,
                    ),
                    children: [
                      _buildTableCell('$idx', align: pw.TextAlign.center),
                      _buildTableCell(formattedDate, align: pw.TextAlign.center),
                      _buildTableCell(testType, align: pw.TextAlign.center),
                      _buildTableCell(syllabusText),
                      _buildTableCell('$maxM', align: pw.TextAlign.center),
                      _buildTableCell(isAbsent ? 'ABS' : (obt != null ? '$obt' : '-'),
                          align: pw.TextAlign.center,
                          bold: true,
                          color: isAbsent ? _roseRed : _slateDark),
                      _buildTableCell(isAbsent ? '-' : '${pct.toStringAsFixed(0)}%',
                          align: pw.TextAlign.center),
                      _buildTableCell(statusText,
                          align: pw.TextAlign.center, bold: true, color: statusColor),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 32),

            // 5. Signatures Footer
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  children: [
                    pw.Container(
                      width: 140,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(color: _borderColor, width: 1.2)),
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text('Subject Teacher Signature', style: const pw.TextStyle(color: _slateLight, fontSize: 9)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Container(
                      width: 140,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(color: _borderColor, width: 1.2)),
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text('Principal Stamp & Signature', style: const pw.TextStyle(color: _slateLight, fontSize: 9)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    // Save PDF to temp directory
    final outputDir = await getTemporaryDirectory();
    final sanitizedSubject = subject.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
    final sanitizedKid = kid.name.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
    final file = File('${outputDir.path}/Test_Report_${sanitizedKid}_$sanitizedSubject.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _buildInfoLabel(String label, String value, {PdfColor? valueColor}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 7.5,
            color: _slateLight,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10.5,
            fontWeight: pw.FontWeight.bold,
            color: valueColor ?? _slateDark,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildStatPill(String title, String val, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: pw.BoxDecoration(
          color: _bgSoft,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: _borderColor),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              title,
              style: const pw.TextStyle(fontSize: 8, color: _slateLight),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              val,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 4),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 8.5,
          color: _slateDark,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    bool bold = false,
    PdfColor color = _slateText,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
        textAlign: align,
      ),
    );
  }
}
