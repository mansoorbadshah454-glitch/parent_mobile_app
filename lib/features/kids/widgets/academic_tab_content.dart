import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/kids_provider.dart';
import '../providers/academic_performance_provider.dart';
import '../providers/homework_provider.dart';
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
  
  ({String msg, Color color, IconData icon, String title}) _getAcademicBadgeData(Map<String, double> scores, double average) {
    String highestSubj = scores.keys.isNotEmpty ? scores.entries.reduce((a, b) => a.value > b.value ? a : b).key : 'All Subjects';
    String lowestSubj = scores.keys.isNotEmpty ? scores.entries.reduce((a, b) => a.value < b.value ? a : b).key : 'All Subjects';
    double highestScore = scores.isNotEmpty ? scores[highestSubj] ?? 0 : average;
    double lowestScore = scores.isNotEmpty ? scores[lowestSubj] ?? 0 : average;

    if (average >= 90) {
      return (
        msg: "Exceptional performance! 🎉 Your child demonstrates outstanding academic excellence, particularly in $highestSubj (${highestScore.toInt()}%).",
        color: Colors.green.shade600,
        icon: Icons.star_rounded,
        title: "Distinction",
      );
    } else if (average >= 80) {
      return (
        msg: "Excellent progress! 🌟 Consistent high academic standards observed, with notable proficiency in $highestSubj (${highestScore.toInt()}%).",
        color: Colors.teal.shade500,
        icon: Icons.workspace_premium_rounded,
        title: "Excellent",
      );
    } else if (average >= 70) {
      return (
        msg: "Very good standing. 👍 A strong academic record overall. Maintaining focus on $lowestSubj (${lowestScore.toInt()}%) will further improve their grade.",
        color: ThemeColors.primaryPurple,
        icon: Icons.thumb_up_rounded,
        title: "Very Good",
      );
    } else if (average >= 60) {
      return (
        msg: "Good performance. 📚 Core concepts are clear, showing strength in $highestSubj. Additional revision for $lowestSubj is recommended.",
        color: Colors.blue.shade500,
        icon: Icons.check_circle_outline_rounded,
        title: "Good",
      );
    } else if (average >= 50) {
      return (
        msg: "Satisfactory progress. 📊 Academic results meet basic expectations. Dedicated study time for $lowestSubj (${lowestScore.toInt()}%) is advised.",
        color: Colors.orange.shade500,
        icon: Icons.trending_flat_rounded,
        title: "Satisfactory",
      );
    } else if (average >= 40) {
      return (
        msg: "Needs improvement. ⚠️ Below average performance detected. Guided support is necessary to address weaknesses in $lowestSubj (${lowestScore.toInt()}%).",
        color: Colors.deepOrange.shade600,
        icon: Icons.warning_rounded,
        title: "Needs Improvement",
      );
    } else if (average >= 30) {
      return (
        msg: "Poor academic standing. 📉 Significant difficulties observed. Please consult with the teacher regarding $lowestSubj (${lowestScore.toInt()}%).",
        color: Colors.red.shade500,
        icon: Icons.error_outline_rounded,
        title: "Poor Performance",
      );
    } else {
      return (
        msg: "Critical attention required. 🚨 Substantial academic intervention is urgently needed. Kindly schedule a meeting with the administration.",
        color: Colors.red.shade900,
        icon: Icons.error_rounded,
        title: "Action Required",
      );
    }
  }

  ({
    double average,
    int doneCount,
    int incompleteCount,
    int notDoneCount,
    int totalGraded,
    Map<String, double> subjectScores,
    bool hasGradedData,
  }) _calculateWeeklyHomeworkPerformance(List<HomeworkItem> homeworkList, KidData kid) {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final sevenDaysAgo = todayMidnight.subtract(const Duration(days: 7));

    int doneCount = 0;
    int incompleteCount = 0;
    int notDoneCount = 0;
    int totalGraded = 0;
    double totalScoreSum = 0;
    final Map<String, List<double>> subjScoreList = {};

    for (final hw in homeworkList) {
      // 1. Filter within last 7 days window
      DateTime? hwDate = hw.createdAt;
      if (hwDate == null && hw.assignedDate.isNotEmpty) {
        try {
          hwDate = DateTime.parse(hw.assignedDate);
        } catch (_) {}
      }
      if (hwDate != null) {
        final hwDay = DateTime(hwDate.year, hwDate.month, hwDate.day);
        if (hwDay.isBefore(sevenDaysAgo)) {
          continue; // Older than 7 days
        }
      }

      // 2. Check student's submission status in this homework
      double? score;
      String status = '';

      if (hw.submissions.containsKey(kid.id)) {
        final sub = hw.submissions[kid.id];
        if (sub is Map) {
          final statusStr = sub['status']?.toString().toLowerCase().trim() ?? '';
          final rawScore = sub['score'];
          final num? scoreNum = rawScore is num ? rawScore : num.tryParse(rawScore?.toString() ?? '');

          if (statusStr == 'done' || (scoreNum != null && scoreNum >= 75)) {
            score = 100.0;
            status = 'done';
          } else if (statusStr == 'incomplete' || (scoreNum != null && scoreNum >= 25 && scoreNum < 75)) {
            score = 50.0;
            status = 'incomplete';
          } else if (statusStr == 'not_done' || statusStr == 'notdone' || (scoreNum != null && scoreNum < 25)) {
            score = 0.0;
            status = 'not_done';
          }
        } else if (sub is String) {
          final s = sub.toLowerCase().trim();
          if (s == 'done') {
            score = 100.0;
            status = 'done';
          } else if (s == 'incomplete') {
            score = 50.0;
            status = 'incomplete';
          } else if (s == 'not_done' || s == 'notdone') {
            score = 0.0;
            status = 'not_done';
          }
        }
      }

      // Fallback: check kid.homeworkScores if not in submissions
      if (score == null && kid.homeworkScores.isNotEmpty) {
        final hwDateStr = hw.assignedDate.length >= 10 ? hw.assignedDate.substring(0, 10) : hw.assignedDate;
        final match = kid.homeworkScores.firstWhere(
          (h) =>
              (h['homeworkId'] != null && h['homeworkId'].toString() == hw.id) ||
              (h['subject'] != null &&
                  h['subject'].toString().toLowerCase() == hw.subject.toLowerCase() &&
                  h['date']?.toString() == hwDateStr),
          orElse: () => <String, dynamic>{},
        );
        if (match.isNotEmpty) {
          final statusStr = match['status']?.toString().toLowerCase().trim() ?? '';
          final rawScore = match['score'];
          final num? scoreNum = rawScore is num ? rawScore : num.tryParse(rawScore?.toString() ?? '');
          if (statusStr == 'done' || (scoreNum != null && scoreNum >= 75)) {
            score = 100.0;
            status = 'done';
          } else if (statusStr == 'incomplete' || (scoreNum != null && scoreNum >= 25 && scoreNum < 75)) {
            score = 50.0;
            status = 'incomplete';
          } else if (statusStr == 'not_done' || statusStr == 'notdone' || (scoreNum != null && scoreNum < 25)) {
            score = 0.0;
            status = 'not_done';
          }
        }
      }

      // Accumulate if graded
      if (score != null) {
        if (status == 'done') doneCount++;
        if (status == 'incomplete') incompleteCount++;
        if (status == 'not_done') notDoneCount++;

        totalScoreSum += score;
        totalGraded++;

        final subj = hw.subject.trim().isNotEmpty ? hw.subject.trim() : 'General';
        subjScoreList.putIfAbsent(subj, () => []).add(score);
      }
    }

    final Map<String, double> subjectAverages = {};
    for (final entry in subjScoreList.entries) {
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      subjectAverages[entry.key] = avg;
    }

    if (totalGraded == 0) {
      return (
        average: 0.0,
        doneCount: 0,
        incompleteCount: 0,
        notDoneCount: 0,
        totalGraded: 0,
        subjectScores: {},
        hasGradedData: false,
      );
    }

    final double average = totalScoreSum / totalGraded;
    return (
      average: average,
      doneCount: doneCount,
      incompleteCount: incompleteCount,
      notDoneCount: notDoneCount,
      totalGraded: totalGraded,
      subjectScores: subjectAverages,
      hasGradedData: true,
    );
  }

  ({String msg, Color color, IconData icon, String title}) _getHomeworkBadgeData({
    required Map<String, double> scores,
    required double average,
    required bool hasGradedData,
    required int totalGraded,
    required int doneCount,
    required int notDoneCount,
  }) {
    if (!hasGradedData) {
      return (
        msg: "No graded homework in the last 7 days. Completion rate will update live as teachers evaluate daily assignments.",
        color: Colors.blueGrey,
        icon: Icons.info_outline_rounded,
        title: "Awaiting Evaluation",
      );
    }

    String highestSubj = scores.keys.isNotEmpty ? scores.entries.reduce((a, b) => a.value > b.value ? a : b).key : 'All Subjects';
    String lowestSubj = scores.keys.isNotEmpty ? scores.entries.reduce((a, b) => a.value < b.value ? a : b).key : 'All Subjects';

    if (average >= 90) {
      return (
        msg: "Exceptional weekly consistency! 📝 $doneCount of $totalGraded assignments completely Done ($highestSubj leading).",
        color: Colors.green.shade600,
        icon: Icons.assignment_turned_in_rounded,
        title: "Distinction",
      );
    } else if (average >= 80) {
      return (
        msg: "Excellent weekly progress! 🎒 Consistent completion across assignments ($doneCount Done), showing strong academic responsibility.",
        color: Colors.teal.shade500,
        icon: Icons.assignment_rounded,
        title: "Excellent",
      );
    } else if (average >= 70) {
      return (
        msg: "Very good consistency. 📓 Most homework submitted on time ($doneCount Done). Focus on completing pending tasks in $lowestSubj.",
        color: ThemeColors.primaryPurple,
        icon: Icons.menu_book_rounded,
        title: "Very Good",
      );
    } else if (average >= 50) {
      return (
        msg: "Satisfactory completion. 📋 Assignments partially met. Regular checks on $lowestSubj homework are recommended.",
        color: Colors.orange.shade500,
        icon: Icons.pending_actions_rounded,
        title: "Satisfactory",
      );
    } else {
      return (
        msg: "Needs attention. ⚠️ Incomplete or missing assignments noted ($notDoneCount Not Done). Please review $lowestSubj homework with the child.",
        color: Colors.red.shade700,
        icon: Icons.assignment_late_rounded,
        title: "Needs Attention",
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
    final homeworkAsync = ref.watch(classHomeworkProvider((
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
          final homeworkList = homeworkAsync.value ?? [];
          final weeklyHw = _calculateWeeklyHomeworkPerformance(homeworkList, widget.kid);

          final double homeworkScore = weeklyHw.hasGradedData
              ? weeklyHw.average
              : data.homeworkAverage;

          final double averageAcademic = subjectScores.values.reduce((a, b) => a + b) / subjectScores.length;
          final academicBadgeData = _getAcademicBadgeData(subjectScores, averageAcademic);
          final homeworkBadgeData = _getHomeworkBadgeData(
            scores: weeklyHw.hasGradedData ? weeklyHw.subjectScores : data.homeworkScores,
            average: homeworkScore,
            hasGradedData: weeklyHw.hasGradedData,
            totalGraded: weeklyHw.totalGraded,
            doneCount: weeklyHw.doneCount,
            notDoneCount: weeklyHw.notDoneCount,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(TranslationHelper.translate("Academic Performance", lang), lang),
                const SizedBox(height: 16),
                _buildAcademicBarChart(subjectScores),
                const SizedBox(height: 16),
                _buildInfoBadge(academicBadgeData, lang),
                
                const SizedBox(height: 32),
                _buildSectionTitle(TranslationHelper.translate("Homework Completion", lang), lang),
                const SizedBox(height: 16),
                _buildHomeworkChart(
                  homeworkScore: homeworkScore,
                  hasGradedData: weeklyHw.hasGradedData,
                  doneCount: weeklyHw.doneCount,
                  incompleteCount: weeklyHw.incompleteCount,
                  notDoneCount: weeklyHw.notDoneCount,
                  totalGraded: weeklyHw.totalGraded,
                ),
                const SizedBox(height: 16),
                _buildInfoBadge(homeworkBadgeData, lang),
                
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

  Widget _buildHomeworkChart({
    required double homeworkScore,
    required bool hasGradedData,
    required int doneCount,
    required int incompleteCount,
    required int notDoneCount,
    required int totalGraded,
  }) {
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
              tween: Tween<double>(begin: 0, end: _startAnimation ? (hasGradedData ? homeworkScore / 100 : 0) : 0),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: hasGradedData ? value : 0.0,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        hasGradedData
                            ? (value >= 0.8 ? Colors.green : (value >= 0.5 ? Colors.orange : Colors.red))
                            : Colors.grey.shade400,
                      ),
                      strokeCap: StrokeCap.round,
                    ),
                    Center(
                      child: Text(
                        hasGradedData ? '${(value * 100).toInt()}%' : '--',
                        style: TextStyle(
                          fontSize: hasGradedData ? 20 : 16,
                          fontWeight: FontWeight.bold,
                          color: hasGradedData ? ThemeColors.primaryText : Colors.grey.shade500,
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
                  "Weekly Homework",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ThemeColors.primaryText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hasGradedData
                      ? "Last 7 Days: $doneCount Done • $incompleteCount Incomplete • $notDoneCount Not Done"
                      : "No homework graded by teachers in the last 7 days yet.",
                  style: TextStyle(
                    fontSize: 13,
                    color: hasGradedData ? const Color(0xFF374151) : Colors.grey.shade600,
                    fontWeight: hasGradedData ? FontWeight.w600 : FontWeight.normal,
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
