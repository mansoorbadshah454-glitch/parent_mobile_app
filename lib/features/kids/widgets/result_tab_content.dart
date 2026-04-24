import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import '../providers/kids_provider.dart';
import '../../../core/theme/theme_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/utils/translation_helper.dart';

class ResultTabContent extends ConsumerStatefulWidget {
  final KidData kid;

  const ResultTabContent({Key? key, required this.kid}) : super(key: key);

  @override
  ConsumerState<ResultTabContent> createState() => _ResultTabContentState();
}

class _ResultTabContentState extends ConsumerState<ResultTabContent> {
  Future<void> _downloadResultCard(BuildContext context) async {
    final liveKids = ref.read(kidsProvider).value;
    final liveKid = liveKids?.firstWhere((k) => k.id == widget.kid.id, orElse: () => widget.kid) ?? widget.kid;
    final urlStr = liveKid.resultUrl;
    
    if (urlStr == null || urlStr.isEmpty) return;

    try {
      final String originalName = liveKid.resultFileName ?? 'result_card.pdf';
      final String ext = originalName.contains('.') ? originalName.split('.').last.toLowerCase() : 'pdf';
      final bool isImage = ['jpg', 'jpeg', 'png'].contains(ext);
      final uri = Uri.parse(urlStr);

      if (isImage) {
        // Image Download Logic -> directly download to storage
        final String baseName = originalName.contains('.') ? originalName.substring(0, originalName.lastIndexOf('.')) : originalName;
        final String uniqueName = '${baseName}_${DateTime.now().millisecondsSinceEpoch}.$ext';

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading image to device storage...')));
        }
        
        await FileDownloader.downloadFile(
          url: urlStr,
          name: uniqueName,
          onDownloadCompleted: (String path) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image Saved successfully!\n$path'), duration: const Duration(seconds: 4)));
            }
          },
          onDownloadError: (String error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error downloading image: $error')));
            }
          },
        ).timeout(const Duration(seconds: 45), onTimeout: () {
          throw Exception('Download timed out.');
        });
      } else {
        // PDF Logic -> Open in external browser natively
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening PDF document in browser...')));
        }
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error processing file: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final liveKids = ref.watch(kidsProvider).value;
    final kid = liveKids?.firstWhere((k) => k.id == widget.kid.id, orElse: () => widget.kid) ?? widget.kid;
    
    final hasResult = kid.resultUrl != null && kid.resultUrl!.isNotEmpty;
    final lang = ref.watch(languageProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Download Action Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: hasResult ? Colors.green.shade50 : Colors.grey.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasResult ? Icons.inventory_rounded : Icons.pending_actions_rounded,
                    color: hasResult ? Colors.green : Colors.grey,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  TranslationHelper.translate(hasResult ? 'Result Card Available' : 'Result Card Not Yet Uploaded', lang),
                  style: TranslationHelper.getTextStyle(
                    lang,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ).copyWith(fontFamily: lang == 'en' ? GoogleFonts.montserrat().fontFamily : null),
                  textAlign: TextAlign.center,
                ),
                if (hasResult && kid.resultFileName != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    kid.resultFileName!,
                    style: GoogleFonts.montserrat(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: hasResult ? () => _downloadResultCard(context) : null,
                    icon: const Icon(Icons.download_rounded, size: 20),
                    label: Text(
                      TranslationHelper.translate('Download Result Card', lang),
                      style: TranslationHelper.getTextStyle(
                        lang,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ).copyWith(fontFamily: lang == 'en' ? GoogleFonts.montserrat().fontFamily : null),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeColors.primaryPurple,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: hasResult ? 4 : 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),

          // Professional Info Badge
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        TranslationHelper.translate('Result Card Information', lang),
                        style: TranslationHelper.getTextStyle(
                          lang,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                          fontSize: 16,
                        ).copyWith(fontFamily: lang == 'en' ? GoogleFonts.montserrat().fontFamily : null),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        TranslationHelper.translate("When your child's result card is available, it will be uploaded here by the school administration or class teacher. You will be able to download it securely.", lang),
                        style: TranslationHelper.getTextStyle(
                          lang,
                          color: Colors.blue.shade800,
                          fontSize: 13,
                          height: 1.5,
                        ).copyWith(fontFamily: lang == 'en' ? GoogleFonts.montserrat().fontFamily : null),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
