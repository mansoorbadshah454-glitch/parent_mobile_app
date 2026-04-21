import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/kids_provider.dart';
import '../providers/academic_performance_provider.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/utils/translation_helper.dart';

class AcademicTabContent extends ConsumerStatefulWidget {
  final KidData kid;
  
  const AcademicTabContent({Key? key, required this.kid}) : super(key: key);

  @override
  ConsumerState<AcademicTabContent> createState() => _AcademicTabContentState();
}

class _AcademicTabContentState extends ConsumerState<AcademicTabContent> {
  bool _startAnimation = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _startAnimation = true;
        });
      }
    });
  }
  
  // Badge logic mapping natively using Records Feature in Dart 3!
  ({String msg, Color color, IconData icon, String title}) _getScoreData(double score, String lang) {
    if (score >= 90) {
      return (
        msg: "Outstanding! 🎉 Your child is performing exceptionally well in both academics and homework. We are proud of their progress!",
        color: Colors.green.shade600,
        icon: Icons.star_rounded,
        title: "Excellent Standing",
      );
    } else if (score >= 80) {
      return (
        msg: "Excellent work! 🌟 Your child is showing great dedication. Keep encouraging them to maintain this high standard.",
        color: Colors.teal.shade500,
        icon: Icons.thumb_up_rounded,
        title: "Very Good",
      );
    } else if (score >= 70) {
      return (
        msg: "Doing Good! 👍 Your child is on the right track. A little extra focus could help them reach the top scores!",
        color: ThemeColors.primaryPurple,
        icon: Icons.check_circle_rounded,
        title: "Good Progress",
      );
    } else if (score >= 60) {
      return (
        msg: "Fair performance. 📚 Your child's basics are clear, but allocating more review time for homework will yield better results.",
        color: Colors.orange.shade500,
        icon: Icons.menu_book_rounded,
        title: "Fair",
      );
    } else if (score >= 50) {
      return (
        msg: "Needs attention. ⚠️ Your child is scoring below average. Let's work together to identify areas where they need help.",
        color: Colors.deepOrange.shade500,
        icon: Icons.warning_rounded,
        title: "Needs Attention",
      );
    } else {
      return (
        msg: "Action required. 🚨 We've noticed a drop in performance. Please arrange a meeting with the teachers so we can support your child better.",
        color: Colors.red.shade600,
        icon: Icons.error_rounded,
        title: "Action Required",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final performanceAsync = ref.watch(academicPerformanceProvider((
      id: widget.kid.id,
      classId: widget.kid.classId,
      className: widget.kid.className,
    )));
    final lang = ref.watch(languageProvider);

    return Builder(
      builder: (context) {
        if (performanceAsync.hasValue) {
          final data = performanceAsync.value;
          if (data == null || data.academicScores.isEmpty) {
            return _buildEmptyState();
          }

          final subjectScores = data.academicScores;
          final homeworkScore = data.homeworkAverage;

          final double averageAcademic = subjectScores.values.reduce((a, b) => a + b) / subjectScores.length;
          final double overallScore = (averageAcademic * 0.6) + (homeworkScore * 0.4);
          final badgeData = _getScoreData(overallScore, lang);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(TranslationHelper.translate("Academic Performance", lang), lang),
                const SizedBox(height: 16),
                _buildAcademicBarChart(subjectScores),
                
                const SizedBox(height: 32),
                _buildSectionTitle(TranslationHelper.translate("Homework Completion", lang), lang),
                const SizedBox(height: 16),
                _buildHomeworkChart(homeworkScore),
                
                const SizedBox(height: 32),
                _buildSectionTitle(TranslationHelper.translate("Progress Insight", lang), lang),
                const SizedBox(height: 16),
                _buildInfoBadge(badgeData, lang),
                const SizedBox(height: 24),
              ],
            ),
          );
        }
        
        if (performanceAsync.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("Failed to load academic data.", style: TextStyle(color: Colors.red)),
            ),
          );
        }
        
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(40.0),
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_graph_rounded, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              "No Academic Data Yet",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ThemeColors.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Scores and performance insights will appear here once updated by the teacher.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String lang) {
    return Text(
      title,
      style: TranslationHelper.getTextStyle(
        lang,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: ThemeColors.primaryText,
      ).copyWith(height: 1.2),
    );
  }

  Widget _buildAcademicBarChart(Map<String, double> subjectScores) {
    return Container(
      height: 220,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: subjectScores.entries.map((entry) {
            final percentage = entry.value;
            final maxBarHeight = 140.0;
            final barHeight = _startAnimation ? (percentage / 100) * maxBarHeight : 0.0;
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${percentage.toInt()}%',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: ThemeColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutQuart,
                    height: barHeight,
                    width: 28,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [ThemeColors.lightPurple, ThemeColors.primaryPurple],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.key.substring(0, entry.key.length > 3 ? 3 : entry.key.length).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ThemeColors.primaryText,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildHomeworkChart(double homeworkScore) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            height: 90,
            width: 90,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: _startAnimation ? homeworkScore / 100 : 0),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: value,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        value >= 0.8 ? Colors.green : (value >= 0.5 ? Colors.orange : Colors.red),
                      ),
                      strokeCap: StrokeCap.round,
                    ),
                    Center(
                      child: Text(
                        '${(value * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: ThemeColors.primaryText,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Recent Homework",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ThemeColors.primaryText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Most assigned tasks completed nicely. Make sure to review the pending ones.",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(({String msg, Color color, IconData icon, String title}) data, String lang) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: data.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: data.color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.icon,
              color: data.color,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TranslationHelper.translate(data.title, lang),
                  style: TranslationHelper.getTextStyle(
                    lang,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: data.color,
                  ).copyWith(height: 1.2),
                ),
                const SizedBox(height: 6),
                Text(
                  TranslationHelper.translate(data.msg, lang),
                  style: TranslationHelper.getTextStyle(
                    lang,
                    fontSize: 13,
                    color: ThemeColors.primaryText,
                    height: 1.5,
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
