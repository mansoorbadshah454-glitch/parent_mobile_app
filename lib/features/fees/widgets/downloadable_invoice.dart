import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../kids/providers/kids_provider.dart';
import '../screens/fee_screen.dart';
import '../utils/invoice_pdf_generator.dart';

class DownloadableInvoice extends StatefulWidget {
  final KidData kid;
  final String schoolName;
  final String? monthName;
  final bool? isPaid;

  const DownloadableInvoice({
    super.key,
    required this.kid,
    required this.schoolName,
    this.monthName,
    this.isPaid,
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
        // Displays the visual receipt as usual
        FeeReceiptWidget(
          kid: widget.kid,
          schoolName: widget.schoolName,
          monthName: widget.monthName,
          isPaidOverride: widget.isPaid,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _isDownloading ? null : _downloadInvoice,
          icon: _isDownloading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20),
          label: Text(
            _isDownloading ? 'Generating PDF...' : 'Download as PDF',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: ThemeColors.primaryPurple,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
            elevation: 2,
          ),
        ),
      ],
    );
  }
}
