import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../providers/exam_results_provider.dart';

class ResultCardPdfGenerator {
  static const PdfColor _navyHeader = PdfColor.fromInt(0xFF0F172A); // [15, 23, 42]
  static const PdfColor _slateDark = PdfColor.fromInt(0xFF1E293B);   // [30, 41, 59]
  static const PdfColor _borderColor = PdfColor.fromInt(0xFFCBD5E1); // [203, 213, 225]
  static const PdfColor _bgBoxColor = PdfColor.fromInt(0xFFF8FAFC);  // [248, 250, 252]
  static const PdfColor _labelSlate = PdfColor.fromInt(0xFF64748B);  // [100, 116, 139]
  static const PdfColor _indigoAccent = PdfColor.fromInt(0xFF4F46E5);// [79, 70, 229]
  static const PdfColor _emeraldGreen = PdfColor.fromInt(0xFF10B981);// [16, 185, 129]
  static const PdfColor _roseRed = PdfColor.fromInt(0xFFE11D48);     // [225, 29, 72]

  static final Map<String, Uint8List> _imageCache = {};

  static Future<Uint8List?> _fetchImageBytes(String? url) async {
    if (url == null || url.trim().isEmpty) return null;
    final cleanUrl = url.trim();
    if (_imageCache.containsKey(cleanUrl)) {
      return _imageCache[cleanUrl];
    }
    try {
      final uri = Uri.parse(cleanUrl);
      final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 1500);
      final request = await client.getUrl(uri).timeout(const Duration(milliseconds: 1500));
      final response = await request.close().timeout(const Duration(milliseconds: 1500));
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

  // --- 1. SINGLE TERM DMC PDF (A4 Portrait - Exact Principal WebApp Replica) ---
  static Future<File> generateDmcPdf({
    required StudentExamResult result,
    required String schoolName,
    String? schoolAddress,
    String? schoolPhone,
    String? schoolLogoUrl,
    Uint8List? schoolLogoBytes,
    String? studentPhotoUrl,
  }) async {
    final pdf = pw.Document();

    // Fast parallel image pre-fetching with in-memory caching
    Uint8List? logoBytes = schoolLogoBytes;
    Uint8List? studentBytes;
    final List<Future<void>> futures = [];

    if (logoBytes == null && schoolLogoUrl != null && schoolLogoUrl.isNotEmpty) {
      futures.add(_fetchImageBytes(schoolLogoUrl).then((b) => logoBytes = b));
    }
    if (studentPhotoUrl != null && studentPhotoUrl.isNotEmpty) {
      futures.add(_fetchImageBytes(studentPhotoUrl).then((b) => studentBytes = b));
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }

    pw.MemoryImage? logoImage;
    final lBytes = logoBytes;
    if (lBytes != null && lBytes.isNotEmpty) {
      try {
        logoImage = pw.MemoryImage(lBytes);
      } catch (_) {}
    }

    pw.MemoryImage? studentPhoto;
    final sBytes = studentBytes;
    if (sBytes != null && sBytes.isNotEmpty) {
      try {
        studentPhoto = pw.MemoryImage(sBytes);
      } catch (_) {}
    }

    final isPassed = result.isPassed;
    final nowFormatted = '${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _borderColor, width: 1.2),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // 1. Header (Logo on Left, Centered Title, Photo on Right)
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Left: Logo
                    pw.Container(
                      width: 52,
                      height: 52,
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        border: pw.Border.all(color: _borderColor, width: 1.0),
                        color: _bgBoxColor,
                      ),
                      alignment: pw.Alignment.center,
                      child: logoImage != null
                          ? pw.ClipOval(child: pw.Image(logoImage, width: 50, height: 50, fit: pw.BoxFit.cover))
                          : pw.Text('LOGO', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _labelSlate)),
                    ),

                    // Center: School Info & DMC Badge
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            schoolName.toUpperCase(),
                            style: pw.TextStyle(
                              fontSize: 15,
                              fontWeight: pw.FontWeight.bold,
                              color: _navyHeader,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            '${schoolAddress ?? 'Campus Address'} ${schoolPhone != null ? '• Phone: $schoolPhone' : ''}',
                            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                            textAlign: pw.TextAlign.center,
                          ),
                          pw.SizedBox(height: 5),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 3.5),
                            decoration: const pw.BoxDecoration(
                              color: _slateDark,
                              borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                            ),
                            child: pw.Text(
                              'DETAILED MARKS CERTIFICATE (DMC)',
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right: Student Photo / Box Placeholder
                    pw.Container(
                      width: 48,
                      height: 56,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: _borderColor, width: 0.8),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                        color: _bgBoxColor,
                      ),
                      alignment: pw.Alignment.center,
                      child: studentPhoto != null
                          ? pw.ClipRRect(
                              horizontalRadius: 3,
                              verticalRadius: 3,
                              child: pw.Image(studentPhoto, width: 46, height: 54, fit: pw.BoxFit.cover),
                            )
                          : pw.Text('PHOTO', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: _labelSlate)),
                    ),
                  ],
                ),

                pw.SizedBox(height: 12),

                // 2. Student Info Box (4-column Grid exactly like Principal WebApp)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: _bgBoxColor,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    border: pw.Border.all(color: _borderColor, width: 0.8),
                  ),
                  child: pw.Column(
                    children: [
                      // Row 1
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          _metaCell('STUDENT NAME:', result.studentName.toUpperCase(), flex: 3),
                          _metaCell('CLASS / SEC:', result.className.toUpperCase(), flex: 2),
                          _metaCell('ROLL NUMBER:', result.rollNumber, valueColor: _indigoAccent, flex: 2),
                          _metaCell('DATE OF ISSUE:', nowFormatted, flex: 2),
                        ],
                      ),
                      pw.SizedBox(height: 5),
                      // Row 2
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          _metaCell("FATHER'S NAME:", (result.fatherName.isNotEmpty ? result.fatherName : '-').toUpperCase(), flex: 3),
                          _metaCell('EXAMINATION:', result.examTitle, flex: 2),
                          _metaCell('SESSION:', '2025-2026', flex: 2),
                          _metaCell('OVERALL ATTD:', result.attendance.isNotEmpty ? result.attendance : 'Regular', valueColor: _emeraldGreen, flex: 2),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 12),

                // 3. Subject-wise Marks Table (Principal WebApp autoTable replica)
                pw.Table(
                  border: pw.TableBorder.all(color: _borderColor, width: 0.6),
                  children: [
                    // Header Row
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: _navyHeader),
                      children: [
                        _thCell('Sr.', width: 28),
                        _thCell('Subject Name', align: pw.TextAlign.left),
                        _thCell('Total Marks', width: 62),
                        _thCell('Pass Marks', width: 62),
                        _thCell('Marks Obtained', width: 80),
                        _thCell('Grade', width: 50),
                        _thCell('Remarks', align: pw.TextAlign.left, width: 80),
                      ],
                    ),
                    // Body Rows
                    ...result.subjectMarks.entries.map((entry) {
                      final idx = result.subjectMarks.keys.toList().indexOf(entry.key) + 1;
                      final s = entry.value;
                      final isSubjPass = !s.isAbsent && (s.obtained ?? 0) >= s.passingMarks;
                      final obtText = s.isAbsent ? 'ABS' : '${s.obtained ?? '-'}';
                      final isEven = idx % 2 == 0;

                      return pw.TableRow(
                        decoration: pw.BoxDecoration(color: isEven ? _bgBoxColor : PdfColors.white),
                        children: [
                          _tdCell('$idx', align: pw.TextAlign.center),
                          _tdCell(entry.key, align: pw.TextAlign.left, isBold: true),
                          _tdCell('${s.totalMarks}', align: pw.TextAlign.center),
                          _tdCell('${s.passingMarks}', align: pw.TextAlign.center),
                          _tdCell(
                            obtText,
                            align: pw.TextAlign.center,
                            textColor: s.isAbsent ? _roseRed : (isSubjPass ? PdfColors.black : _roseRed),
                            isBold: true,
                          ),
                          _tdCell(s.grade, align: pw.TextAlign.center, isBold: true),
                          _tdCell(s.remarks.isNotEmpty ? s.remarks : (isSubjPass ? 'Good' : 'Needs Focus'), align: pw.TextAlign.left),
                        ],
                      );
                    }),
                  ],
                ),

                pw.SizedBox(height: 10),

                // 4. Summary Strip Box (5 Metrics Box)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: _bgBoxColor,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    border: pw.Border.all(color: _borderColor, width: 0.8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      _summaryCol('TOTAL MARKS', '${result.totalObtained} / ${result.totalMax}'),
                      _vDivider(),
                      _summaryCol('PERCENTAGE', '${result.percentage.toStringAsFixed(1)}%'),
                      _vDivider(),
                      _summaryCol('OVERALL GRADE', result.grade, valueColor: _indigoAccent),
                      _vDivider(),
                      _summaryCol('CLASS POSITION', result.position.isNotEmpty && result.position != '-' ? result.position : 'N/A', valueColor: _emeraldGreen),
                      _vDivider(),
                      _summaryCol('RESULT STATUS', result.statusLabel.toUpperCase(), valueColor: isPassed ? _emeraldGreen : _roseRed),
                    ],
                  ),
                ),

                pw.SizedBox(height: 10),

                // 5. Grading Scale Legend Table (Exact Principal WebApp Matrix)
                pw.Table(
                  border: pw.TableBorder.all(color: _borderColor, width: 0.5),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: _navyHeader),
                      children: [
                        _legendCell('Grade', isBold: true, textColor: PdfColors.white),
                        _legendCell('A+', textColor: PdfColor.fromInt(0xFF38BDF8)),
                        _legendCell('A', textColor: PdfColor.fromInt(0xFF38BDF8)),
                        _legendCell('B', textColor: PdfColor.fromInt(0xFF38BDF8)),
                        _legendCell('C', textColor: PdfColor.fromInt(0xFF38BDF8)),
                        _legendCell('D', textColor: PdfColor.fromInt(0xFF38BDF8)),
                        _legendCell('E', textColor: PdfColor.fromInt(0xFF38BDF8)),
                        _legendCell('F', textColor: _roseRed),
                      ],
                    ),
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.white),
                      children: [
                        _legendCell('Range (%)', isBold: true),
                        _legendCell('90%+'),
                        _legendCell('80-89%'),
                        _legendCell('70-79%'),
                        _legendCell('60-69%'),
                        _legendCell('50-59%'),
                        _legendCell('40-49%'),
                        _legendCell('<40%'),
                      ],
                    ),
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: _bgBoxColor),
                      children: [
                        _legendCell('Remarks', isBold: true),
                        _legendCell('Outstanding'),
                        _legendCell('Excellent'),
                        _legendCell('Very Good'),
                        _legendCell('Good'),
                        _legendCell('Fair'),
                        _legendCell('Needs Attention'),
                        _legendCell('Action Required'),
                      ],
                    ),
                  ],
                ),

                pw.Spacer(),

                // 6. Signatures (Exact 3 Signatures)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _sigLine('Class Teacher'),
                    _sigLine('Controller of Examinations'),
                    _sigLine('Principal Stamp & Signature'),
                  ],
                ),

                pw.SizedBox(height: 6),

                // 7. Official Security Footer
                pw.Center(
                  child: pw.Text(
                    'Official Digital DMC • Verified Digitally via Smart School Management System • $nowFormatted',
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
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
    final file = File('${outputDir.path}/${cleanStudentName}_${cleanExamTitle}_Official_DMC.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // --- 2. ANNUAL CONSOLIDATED ALL-IN-ONE (3-TERMS) DMC PDF (A4 Landscape - Exact Principal WebApp Replica) ---
  static Future<File> generateConsolidatedDmcPdf({
    required ConsolidatedExamResult consolidated,
    required String schoolName,
    String? schoolAddress,
    String? schoolPhone,
    String? schoolLogoUrl,
    Uint8List? schoolLogoBytes,
    String? studentPhotoUrl,
  }) async {
    final pdf = pw.Document();

    // Fast parallel image pre-fetching with in-memory caching
    Uint8List? logoBytes = schoolLogoBytes;
    Uint8List? studentBytes;
    final List<Future<void>> futures = [];

    if (logoBytes == null && schoolLogoUrl != null && schoolLogoUrl.isNotEmpty) {
      futures.add(_fetchImageBytes(schoolLogoUrl).then((b) => logoBytes = b));
    }
    if (studentPhotoUrl != null && studentPhotoUrl.isNotEmpty) {
      futures.add(_fetchImageBytes(studentPhotoUrl).then((b) => studentBytes = b));
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }

    pw.MemoryImage? logoImage;
    final lBytes = logoBytes;
    if (lBytes != null && lBytes.isNotEmpty) {
      try {
        logoImage = pw.MemoryImage(lBytes);
      } catch (_) {}
    }

    pw.MemoryImage? studentPhoto;
    final sBytes = studentBytes;
    if (sBytes != null && sBytes.isNotEmpty) {
      try {
        studentPhoto = pw.MemoryImage(sBytes);
      } catch (_) {}
    }

    final isPassed = consolidated.isPassed;
    final terms = consolidated.activeTerms;
    final nowFormatted = '${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _borderColor, width: 1.2),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // 1. Header (Logo, Centered School Info, Photo)
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Left Logo
                    pw.Container(
                      width: 46,
                      height: 46,
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        border: pw.Border.all(color: _borderColor, width: 1.0),
                        color: _bgBoxColor,
                      ),
                      alignment: pw.Alignment.center,
                      child: logoImage != null
                          ? pw.ClipOval(child: pw.Image(logoImage, width: 44, height: 44, fit: pw.BoxFit.cover))
                          : pw.Text('LOGO', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _labelSlate)),
                    ),

                    // Center: School Info & All-in-One DMC Badge
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            schoolName.toUpperCase(),
                            style: pw.TextStyle(
                              fontSize: 15,
                              fontWeight: pw.FontWeight.bold,
                              color: _navyHeader,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                          pw.SizedBox(height: 1),
                          pw.Text(
                            '${schoolAddress ?? 'Campus Address'} ${schoolPhone != null ? '• Phone: $schoolPhone' : ''}',
                            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                            textAlign: pw.TextAlign.center,
                          ),
                          pw.SizedBox(height: 4),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                            decoration: const pw.BoxDecoration(
                              color: _slateDark,
                              borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                            ),
                            child: pw.Text(
                              'ANNUAL CONSOLIDATED DETAILED MARKS CERTIFICATE (ALL-IN-ONE DMC)',
                              style: pw.TextStyle(
                                fontSize: 8.5,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right Photo
                    pw.Container(
                      width: 44,
                      height: 48,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: _borderColor, width: 0.8),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                        color: _bgBoxColor,
                      ),
                      alignment: pw.Alignment.center,
                      child: studentPhoto != null
                          ? pw.ClipRRect(
                              horizontalRadius: 3,
                              verticalRadius: 3,
                              child: pw.Image(studentPhoto, width: 42, height: 46, fit: pw.BoxFit.cover),
                            )
                          : pw.Text('PHOTO', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: _labelSlate)),
                    ),
                  ],
                ),

                pw.SizedBox(height: 8),

                // 2. Student Info Box (4-column Grid)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: _bgBoxColor,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    border: pw.Border.all(color: _borderColor, width: 0.8),
                  ),
                  child: pw.Column(
                    children: [
                      // Row 1
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          _metaCell('STUDENT NAME:', consolidated.studentName.toUpperCase(), flex: 3),
                          _metaCell('CLASS / SEC:', consolidated.className.toUpperCase(), flex: 2),
                          _metaCell('ROLL NUMBER:', consolidated.rollNumber, valueColor: _indigoAccent, flex: 2),
                          _metaCell('DATE OF ISSUE:', nowFormatted, flex: 2),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      // Row 2
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          _metaCell("FATHER'S NAME:", (consolidated.fatherName.isNotEmpty ? consolidated.fatherName : '-').toUpperCase(), flex: 3),
                          _metaCell('EXAMINATION:', 'Annual Consolidated (All Terms)', flex: 2),
                          _metaCell('SESSION:', consolidated.session, flex: 2),
                          _metaCell('OVERALL ATTD:', consolidated.attendance.isNotEmpty ? consolidated.attendance : 'Regular', valueColor: _emeraldGreen, flex: 2),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 8),

                // 3. Multi-Term 3-in-1 Side-by-Side Comparison Table (Exact Principal App Replica)
                pw.Table(
                  border: pw.TableBorder.all(color: _borderColor, width: 0.5),
                  children: [
                    // Row 1 Header: Terms side-by-side + Consolidated Final
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: _navyHeader),
                      children: [
                        _thCell('Sr.', width: 22),
                        _thCell('Subject Name', align: pw.TextAlign.left, width: 85),
                        ...terms.map((t) => _thCell(
                              t.title.replaceAll(' Examination', '').replaceAll(' 2026', ''),
                              align: pw.TextAlign.center,
                            )),
                        _thCell('Annual Consolidated Final', align: pw.TextAlign.center, width: 110),
                      ],
                    ),
                    // Row 2 Sub-Header: Max | Obt | Grd
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: _slateDark),
                      children: [
                        _legendCell('#', textColor: PdfColors.white),
                        _legendCell('Subject', textColor: PdfColors.white),
                        ...terms.map((_) => _legendCell('Max | Obt | Grd', textColor: PdfColor.fromInt(0xFF38BDF8))),
                        _legendCell('Total | Obt | % | Grade', textColor: PdfColor.fromInt(0xFFFDE047)),
                      ],
                    ),
                    // Subject rows comparing all terms
                    ...consolidated.subjects.entries.map((entry) {
                      final idx = consolidated.subjects.keys.toList().indexOf(entry.key) + 1;
                      final subj = entry.value;
                      final isSubjPass = subj.percentage >= 33;
                      final isEven = idx % 2 == 0;

                      return pw.TableRow(
                        decoration: pw.BoxDecoration(color: isEven ? _bgBoxColor : PdfColors.white),
                        children: [
                          _tdCell('$idx', align: pw.TextAlign.center, fontSize: 7.5),
                          _tdCell(subj.subjectName, align: pw.TextAlign.left, isBold: true, fontSize: 8),
                          ...terms.map((t) {
                            final score = subj.terms[t.id];
                            if (score == null) return _tdCell('—', align: pw.TextAlign.center, fontSize: 7.5);
                            final obtStr = score.isAbsent ? 'ABS' : '${score.obtained ?? '-'}';
                            return _tdCell('${score.totalMarks} | $obtStr | ${score.grade}', align: pw.TextAlign.center, fontSize: 7.5);
                          }),
                          _tdCell(
                            '${subj.totalMax} | ${subj.totalObtained} | ${subj.percentage}% | ${subj.grade}',
                            align: pw.TextAlign.center,
                            isBold: true,
                            textColor: isSubjPass ? PdfColors.black : _roseRed,
                            fontSize: 8,
                          ),
                        ],
                      );
                    }),
                  ],
                ),

                pw.SizedBox(height: 6),

                // 4. Summary Strip Box
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: _bgBoxColor,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    border: pw.Border.all(color: _borderColor, width: 0.8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      _summaryCol('CUMULATIVE TOTAL', '${consolidated.grandTotalObtained} / ${consolidated.grandTotalMax}'),
                      _vDivider(),
                      _summaryCol('OVERALL PERCENTAGE', '${consolidated.overallPercentage.toStringAsFixed(1)}%'),
                      _vDivider(),
                      _summaryCol('OVERALL GRADE', consolidated.overallGrade, valueColor: _indigoAccent),
                      _vDivider(),
                      _summaryCol('CLASS POSITION', consolidated.position.isNotEmpty && consolidated.position != '-' ? consolidated.position : 'N/A', valueColor: _emeraldGreen),
                      _vDivider(),
                      _summaryCol('RESULT STATUS', consolidated.statusLabel.toUpperCase(), valueColor: isPassed ? _emeraldGreen : _roseRed),
                    ],
                  ),
                ),

                pw.SizedBox(height: 6),

                // 5. Grading Scale Legend
                pw.Table(
                  border: pw.TableBorder.all(color: _borderColor, width: 0.4),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: _navyHeader),
                      children: [
                        _legendCell('Grade', isBold: true, textColor: PdfColors.white),
                        _legendCell('A+', textColor: PdfColor.fromInt(0xFF38BDF8)),
                        _legendCell('A', textColor: PdfColor.fromInt(0xFF38BDF8)),
                        _legendCell('B', textColor: PdfColor.fromInt(0xFF38BDF8)),
                        _legendCell('C', textColor: PdfColor.fromInt(0xFF38BDF8)),
                        _legendCell('D', textColor: PdfColor.fromInt(0xFF38BDF8)),
                        _legendCell('E', textColor: PdfColor.fromInt(0xFF38BDF8)),
                        _legendCell('F', textColor: _roseRed),
                      ],
                    ),
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.white),
                      children: [
                        _legendCell('Range (%)', isBold: true),
                        _legendCell('90%+'),
                        _legendCell('80-89%'),
                        _legendCell('70-79%'),
                        _legendCell('60-69%'),
                        _legendCell('50-59%'),
                        _legendCell('40-49%'),
                        _legendCell('<40%'),
                      ],
                    ),
                  ],
                ),

                pw.Spacer(),

                // 6. Signatures (Class Teacher, Controller, Principal)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _sigLine('Class Teacher'),
                    _sigLine('Controller of Examinations'),
                    _sigLine('Principal Stamp & Signature'),
                  ],
                ),

                pw.SizedBox(height: 4),

                // 7. Security Footer
                pw.Center(
                  child: pw.Text(
                    'Official Multi-Term Consolidated DMC • Verified Digitally via Smart School Management System • $nowFormatted',
                    style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    final outputDir = await getTemporaryDirectory();
    final cleanStudentName = consolidated.studentName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final file = File('${outputDir.path}/${cleanStudentName}_Annual_Consolidated_All_in_One_DMC.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // Helper widgets for table and cells
  static pw.Widget _metaCell(String label, String value, {PdfColor? valueColor, int flex = 1}) {
    return pw.Expanded(
      flex: flex,
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label ',
              style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: _labelSlate),
            ),
            pw.TextSpan(
              text: value,
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: valueColor ?? _navyHeader),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _thCell(String text, {pw.TextAlign align = pw.TextAlign.center, double? width}) {
    return pw.Container(
      width: width,
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4.5),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _tdCell(String text, {pw.TextAlign align = pw.TextAlign.left, PdfColor textColor = PdfColors.black, bool isBold = false, double fontSize = 8.5}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          color: textColor,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _summaryCol(String label, String val, {PdfColor? valueColor}) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: _labelSlate),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          val,
          style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: valueColor ?? _navyHeader),
        ),
      ],
    );
  }

  static pw.Widget _legendCell(String text, {bool isBold = false, PdfColor? textColor}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5, horizontal: 3),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 6.5,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textColor ?? _navyHeader,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _vDivider() {
    return pw.Container(width: 1, height: 20, color: _borderColor);
  }

  static pw.Widget _sigLine(String title) {
    return pw.Column(
      children: [
        pw.Container(
          width: 130,
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: PdfColors.grey600, width: 0.8)),
          ),
          padding: const pw.EdgeInsets.only(top: 3),
          child: pw.Text(
            title,
            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ],
    );
  }
}
