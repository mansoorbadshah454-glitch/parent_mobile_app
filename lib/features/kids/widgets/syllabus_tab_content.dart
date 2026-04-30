import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/kids_provider.dart';
import '../providers/syllabus_provider.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/utils/translation_helper.dart';

class SyllabusTabContent extends ConsumerWidget {
  final KidData kid;

  const SyllabusTabContent({Key? key, required this.kid}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(classSubjectsProvider((classId: kid.classId, className: kid.className)));
    final lang = ref.watch(languageProvider);

    return subjectsAsync.when(
      data: (subjects) {
        if (subjects.isEmpty) {
          return Center(
            child: Text(
              TranslationHelper.translate("No syllabus data available.", lang),
              style: TranslationHelper.getTextStyle(lang, color: Colors.grey, fontSize: 16)
                  .copyWith(fontFamily: lang != 'ur' ? GoogleFonts.montserrat().fontFamily : null),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(classSubjectsProvider((classId: kid.classId, className: kid.className)));
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return SubjectStreamCard(kid: kid, subject: subject, lang: lang);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: ThemeColors.primaryPurple)),
      error: (e, st) => Center(
        child: Text(
          TranslationHelper.translate("Failed to load syllabus.", lang),
          style: TranslationHelper.getTextStyle(lang, color: Colors.red)
              .copyWith(fontFamily: lang != 'ur' ? GoogleFonts.montserrat().fontFamily : null),
        ),
      ),
    );
  }
}

class SubjectStreamCard extends ConsumerWidget {
  final KidData kid;
  final String subject;
  final String lang;

  const SubjectStreamCard({
    Key? key,
    required this.kid,
    required this.subject,
    required this.lang,
  }) : super(key: key);

  String _getSubjectIcon(String subjectName) {
    final s = subjectName.toLowerCase();
    if (s.contains('english')) return '📚';
    if (s.contains('urdu')) return '📖';
    if (s.contains('math')) return '📐';
    if (s.contains('science')) return '🔬';
    if (s.contains('islam')) return '🕌';
    if (s.contains('social') || s == 'sst') return '🌍';
    if (s.contains('computer') || s == 'it') return '💻';
    if (s.contains('physic')) return '⚡';
    if (s.contains('chemist')) return '🧪';
    if (s.contains('bio')) return '🧬';
    if (s.contains('art') || s.contains('draw')) return '🎨';
    return '📓';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chaptersAsync = ref.watch(
      subjectChaptersProvider((classId: kid.classId, className: kid.className, subject: subject))
    );

    return chaptersAsync.when(
      data: (inProgressChapters) {
        final hasInProgress = inProgressChapters.isNotEmpty;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shadowColor: ThemeColors.primaryPurple.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: hasInProgress ? ThemeColors.primaryPurple.withOpacity(0.5) : Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              iconColor: ThemeColors.primaryPurple,
              collapsedIconColor: Colors.grey,
              tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ThemeColors.primaryPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getSubjectIcon(subject),
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          TranslationHelper.translate(subject, lang),
                          style: TranslationHelper.getTextStyle(lang, fontWeight: FontWeight.bold, fontSize: 16, color: ThemeColors.primaryText)
                              .copyWith(fontFamily: lang != 'ur' ? GoogleFonts.montserrat().fontFamily : null),
                        ),
                        if (hasInProgress)
                          Text(
                            TranslationHelper.translate("Active Chapter Available", lang),
                            style: TranslationHelper.getTextStyle(lang, fontWeight: FontWeight.w500, fontSize: 12, color: ThemeColors.primaryPurple)
                                .copyWith(fontFamily: lang != 'ur' ? GoogleFonts.montserrat().fontFamily : null),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                  child: hasInProgress 
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: inProgressChapters.map((chapter) {
                          final chapterTitle = chapter['title'] ?? chapter['name'] ?? 'Current Chapter';
                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: ThemeColors.primaryPurple.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: ThemeColors.primaryPurple.withOpacity(0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.school_rounded, color: ThemeColors.primaryPurple, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        TranslationHelper.translate("Currently Teaching in School", lang),
                                        style: TranslationHelper.getTextStyle(lang, fontWeight: FontWeight.w700, fontSize: 14, color: ThemeColors.primaryPurple)
                                            .copyWith(fontFamily: lang != 'ur' ? GoogleFonts.montserrat().fontFamily : null, height: 1.2),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  TranslationHelper.translate("Chapter: $chapterTitle", lang),
                                  style: TranslationHelper.getTextStyle(lang, fontWeight: FontWeight.bold, fontSize: 16, color: ThemeColors.primaryText)
                                      .copyWith(fontFamily: lang != 'ur' ? GoogleFonts.montserrat().fontFamily : null, height: 1.2),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  TranslationHelper.translate("Our faculty is currently focusing on this chapter, ensuring a deep understanding of core concepts. We highly encourage you to discuss these topics with your child at home to reinforce their learning.", lang),
                                  style: TranslationHelper.getTextStyle(lang, fontSize: 13, color: Colors.black87, height: 1.5)
                                      .copyWith(fontFamily: lang != 'ur' ? GoogleFonts.montserrat().fontFamily : null),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      )
                    : Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: Text(
                          TranslationHelper.translate("No chapter is currently marked as 'In Progress' for this subject.", lang),
                          style: TranslationHelper.getTextStyle(lang, fontSize: 13, color: Colors.grey[600])
                              .copyWith(fontFamily: lang != 'ur' ? GoogleFonts.montserrat().fontFamily : null, fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center,
                        ),
                      ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator(color: ThemeColors.primaryPurple)),
      ),
      error: (e, st) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            TranslationHelper.translate("Failed to load chapters.", lang),
            style: TranslationHelper.getTextStyle(lang, color: Colors.red)
                .copyWith(fontFamily: lang != 'ur' ? GoogleFonts.montserrat().fontFamily : null),
          ),
        ),
      ),
    );
  }
}
