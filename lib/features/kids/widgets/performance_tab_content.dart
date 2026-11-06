import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/kids_provider.dart';
import '../providers/academic_performance_provider.dart';
import '../../alerts/screens/scheduled_tests_screen.dart';
import '../../../core/theme/theme_colors.dart';

class PerformanceTabContent extends ConsumerStatefulWidget {
  final KidData kid;

  const PerformanceTabContent({Key? key, required this.kid}) : super(key: key);

  @override
  ConsumerState<PerformanceTabContent> createState() => _PerformanceTabContentState();
}

class _PerformanceTabContentState extends ConsumerState<PerformanceTabContent> {

  DateTime? _parseReportDate(Map<String, dynamic> r) {
    try {
      final c = r['createdAt'] ?? r['date'] ?? r['timestamp'];
      if (c is Timestamp) return c.toDate();
      if (c is String && c.isNotEmpty) return DateTime.tryParse(c);
    } catch (_) {}
    return null;
  }

  ({double score, bool hasData}) _calcAcademicScore(AcademicPerformanceData? data) {
    if (data == null || data.academicScores.isEmpty) {
      return (score: 0.0, hasData: false);
    }
    final scores = data.academicScores.values.toList();
    if (scores.isEmpty) return (score: 0.0, hasData: false);
    final avg = scores.reduce((a, b) => a + b) / scores.length;
    return (score: avg.clamp(0.0, 100.0), hasData: true);
  }

  ({double score, bool hasData}) _calcHomeworkScore(AcademicPerformanceData? data, KidData kid) {
    if (data != null && data.homeworkAverage > 0) {
      return (score: data.homeworkAverage.clamp(0.0, 100.0), hasData: true);
    }
    if (data != null && data.homeworkScores.isNotEmpty) {
      final vals = data.homeworkScores.values.toList();
      final avg = vals.reduce((a, b) => a + b) / vals.length;
      return (score: avg.clamp(0.0, 100.0), hasData: true);
    }
    if (kid.homeworkScores.isNotEmpty) {
      double total = 0.0;
      int count = 0;
      for (var item in kid.homeworkScores) {
        final val = double.tryParse(item['score']?.toString() ?? '');
        if (val != null) {
          total += val;
          count++;
        }
      }
      if (count > 0) {
        return (score: (total / count).clamp(0.0, 100.0), hasData: true);
      }
    }
    return (score: 0.0, hasData: false);
  }

  ({double score, bool hasData}) _calcAttendanceScore(Map<String, String> history) {
    if (history.isEmpty) return (score: 0.0, hasData: false);
    int present = 0;
    int total = 0;
    history.forEach((date, status) {
      final s = status.toLowerCase().trim();
      if (s == 'present' || s == 'p' || s == 'late' || s == 'l') {
        present++;
        total++;
      } else if (s == 'absent' || s == 'a') {
        total++;
      }
    });
    if (total == 0) return (score: 0.0, hasData: false);
    return (score: ((present / total) * 100.0).clamp(0.0, 100.0), hasData: true);
  }

  ({double score, bool hasData}) _calcWellnessScore(Map<String, int> wellness) {
    if (wellness.isEmpty) return (score: 0.0, hasData: false);
    final b = wellness['behavior']?.toDouble();
    final h = wellness['health']?.toDouble();
    final hy = wellness['hygiene']?.toDouble();
    if (b == null && h == null && hy == null) {
      return (score: 0.0, hasData: false);
    }
    final bVal = b ?? 80.0;
    final hVal = h ?? 80.0;
    final hyVal = hy ?? 80.0;
    return (score: ((bVal + hVal + hyVal) / 3.0).clamp(0.0, 100.0), hasData: true);
  }

  ({double score, bool hasData}) _calcTestsScore(List<Map<String, dynamic>> reports) {
    if (reports.isEmpty) return (score: 0.0, hasData: false);
    double totalObtained = 0.0;
    double totalPossible = 0.0;
    for (var r in reports) {
      final obt = double.tryParse(r['obtainedMarks']?.toString() ?? '') ??
          double.tryParse(r['score']?.toString() ?? '');
      final tot = double.tryParse(r['totalMarks']?.toString() ?? '') ?? 100.0;
      if (obt != null && tot > 0) {
        totalObtained += obt;
        totalPossible += tot;
      }
    }
    if (totalPossible == 0) return (score: 0.0, hasData: false);
    return (score: ((totalObtained / totalPossible) * 100.0).clamp(0.0, 100.0), hasData: true);
  }

  ({String label, String grade, Color color, Color bg, IconData icon}) _getStatusBadge(double score, bool hasAnyData) {
    if (!hasAnyData) {
      return (
        label: "Pending",
        grade: "Pending Eval",
        color: const Color(0xFF6B7280),
        bg: const Color(0xFFF3F4F6),
        icon: Icons.hourglass_top_rounded,
      );
    }
    if (score >= 85) {
      return (
        label: "Outstanding",
        grade: "A+ Distinction",
        color: const Color(0xFF059669),
        bg: const Color(0xFFECFDF5),
        icon: Icons.workspace_premium_rounded,
      );
    } else if (score >= 70) {
      return (
        label: "Excellent",
        grade: "Grade A",
        color: const Color(0xFF10B981),
        bg: const Color(0xFFECFDF5),
        icon: Icons.trending_up_rounded,
      );
    } else if (score >= 45) {
      return (
        label: "Good Standing",
        grade: "Grade B",
        color: const Color(0xFF16A34A),
        bg: const Color(0xFFF0FDF4),
        icon: Icons.thumb_up_rounded,
      );
    } else if (score >= 35) {
      return (
        label: "Developing",
        grade: "Grade C",
        color: const Color(0xFFF97316),
        bg: const Color(0xFFFFF7ED),
        icon: Icons.eco_rounded,
      );
    } else {
      return (
        label: "Needs Focus",
        grade: "Grade D",
        color: const Color(0xFFDC2626),
        bg: const Color(0xFFFEF2F2),
        icon: Icons.priority_high_rounded,
      );
    }
  }

  List<({String name, int year, int month})> _getLast6Months() {
    final now = DateTime.now();
    const names = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    List<({String name, int year, int month})> list = [];
    for (int i = 5; i >= 0; i--) {
      int year = now.year;
      int month = now.month - i;
      while (month <= 0) {
        month += 12;
        year -= 1;
      }
      list.add((name: names[month - 1], year: year, month: month));
    }
    return list;
  }

  ({
    List<String> months,
    List<FlSpot> spots,
    String growthText,
    IconData growthIcon,
    Color growthColor,
    Color growthBg,
    Color growthBorder,
  }) _computeDynamicMonthlyTrend({
    required double currentScore,
    required List<Map<String, dynamic>> testReports,
    required Map<String, String> attendanceHistory,
  }) {
    final monthEntries = _getLast6Months();
    final List<String> monthLabels = monthEntries.map((m) => m.name).toList();
    final List<double?> monthlyAverages = [];

    for (var m in monthEntries) {
      // 1. Test scores in this specific month
      double testObtained = 0.0;
      double testPossible = 0.0;
      for (var r in testReports) {
        final dt = _parseReportDate(r);
        if (dt != null && dt.year == m.year && dt.month == m.month) {
          final obt = double.tryParse(r['obtainedMarks']?.toString() ?? '') ??
              double.tryParse(r['score']?.toString() ?? '');
          final tot = double.tryParse(r['totalMarks']?.toString() ?? '') ?? 100.0;
          if (obt != null && tot > 0) {
            testObtained += obt;
            testPossible += tot;
          }
        }
      }
      final bool hasTests = testPossible > 0;
      final double testAvg = hasTests ? (testObtained / testPossible) * 100.0 : 0.0;

      // 2. Attendance in this specific month
      final prefix = "${m.year}-${m.month.toString().padLeft(2, '0')}";
      int present = 0;
      int totalDays = 0;
      attendanceHistory.forEach((dateKey, status) {
        if (dateKey.startsWith(prefix)) {
          final s = status.toLowerCase().trim();
          if (s == 'present' || s == 'p' || s == 'late' || s == 'l') {
            present++;
            totalDays++;
          } else if (s == 'absent' || s == 'a') {
            totalDays++;
          }
        }
      });
      final bool hasAtt = totalDays > 0;
      final double attAvg = hasAtt ? (present / totalDays) * 100.0 : 0.0;

      if (hasTests && hasAtt) {
        monthlyAverages.add(((testAvg + attAvg) / 2.0).clamp(0.0, 100.0));
      } else if (hasTests) {
        monthlyAverages.add(testAvg.clamp(0.0, 100.0));
      } else if (hasAtt) {
        monthlyAverages.add(attAvg.clamp(0.0, 100.0));
      } else {
        monthlyAverages.add(null);
      }
    }

    final List<FlSpot> spots = [];
    double fallback = currentScore > 0 ? currentScore : 0.0;

    double? lastKnown;
    for (int i = 0; i < 6; i++) {
      if (monthlyAverages[i] != null) {
        lastKnown = monthlyAverages[i];
      }
    }

    for (int i = 0; i < 6; i++) {
      final val = monthlyAverages[i];
      double spotVal;
      if (val != null) {
        spotVal = val;
      } else if (i == 5 && currentScore > 0) {
        spotVal = currentScore;
      } else if (lastKnown != null) {
        spotVal = lastKnown;
      } else {
        spotVal = fallback;
      }
      spots.add(FlSpot(i.toDouble(), spotVal.clamp(0.0, 100.0)));
    }

    // Determine growth comparison (compare latest recorded month to previous)
    double? currentMonthScore = monthlyAverages[5] ?? (currentScore > 0 ? currentScore : null);
    double? previousMonthScore;

    for (int i = 4; i >= 0; i--) {
      if (monthlyAverages[i] != null) {
        previousMonthScore = monthlyAverages[i];
        break;
      }
    }

    String growthText;
    IconData growthIcon;
    Color growthColor;
    Color growthBg;
    Color growthBorder;

    if (currentMonthScore != null && previousMonthScore != null) {
      final diff = currentMonthScore - previousMonthScore;
      if (diff > 0) {
        growthText = "+${diff.toStringAsFixed(1)}% Growth";
        growthIcon = Icons.arrow_upward_rounded;
        growthColor = const Color(0xFF059669);
        growthBg = const Color(0xFFECFDF5);
        growthBorder = const Color(0xFF6EE7B7);
      } else if (diff < 0) {
        growthText = "${diff.toStringAsFixed(1)}% Pace";
        growthIcon = Icons.arrow_downward_rounded;
        growthColor = const Color(0xFFDC2626);
        growthBg = const Color(0xFFFEF2F2);
        growthBorder = const Color(0xFFFCA5A5);
      } else {
        growthText = "Steady (0.0%)";
        growthIcon = Icons.trending_flat_rounded;
        growthColor = const Color(0xFF2563EB);
        growthBg = const Color(0xFFEFF6FF);
        growthBorder = const Color(0xFF93C5FD);
      }
    } else if (currentScore > 0) {
      growthText = "Tracking Active";
      growthIcon = Icons.trending_up_rounded;
      growthColor = const Color(0xFF059669);
      growthBg = const Color(0xFFECFDF5);
      growthBorder = const Color(0xFF6EE7B7);
    } else {
      growthText = "No Records Yet";
      growthIcon = Icons.info_outline_rounded;
      growthColor = const Color(0xFF6B7280);
      growthBg = const Color(0xFFF3F4F6);
      growthBorder = const Color(0xFFE5E7EB);
    }

    return (
      months: monthLabels,
      spots: spots,
      growthText: growthText,
      growthIcon: growthIcon,
      growthColor: growthColor,
      growthBg: growthBg,
      growthBorder: growthBorder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final academicAsync = ref.watch(academicPerformanceProvider((
      id: widget.kid.id,
      classId: widget.kid.classId,
      className: widget.kid.className,
    )));

    final reportsAsync = ref.watch(testReportsProvider(
      TestReportArgs(classId: widget.kid.classId, studentId: widget.kid.id),
    ));

    final academicData = academicAsync.value;
    final testReports = reportsAsync.value ?? [];

    final academicRes = _calcAcademicScore(academicData);
    final homeworkRes = _calcHomeworkScore(academicData, widget.kid);
    final attendanceRes = _calcAttendanceScore(widget.kid.attendanceHistory);
    final wellnessRes = _calcWellnessScore(widget.kid.wellness);
    final testsRes = _calcTestsScore(testReports);

    final academicScore = academicRes.score;
    final homeworkScore = homeworkRes.score;
    final attendanceScore = attendanceRes.score;
    final wellnessScore = wellnessRes.score;
    final testsScore = testsRes.score;

    final hasAcademic = academicRes.hasData;
    final hasHomework = homeworkRes.hasData;
    final hasAttendance = attendanceRes.hasData;
    final hasWellness = wellnessRes.hasData;
    final hasTests = testsRes.hasData;

    final bool hasAnyData = hasAcademic || hasHomework || hasAttendance || hasWellness || hasTests;

    // Dynamically calculate cumulative score based on actively available pillars
    double totalWeight = 0.0;
    double weightedSum = 0.0;

    if (hasAcademic) {
      weightedSum += (academicScore * 25.0);
      totalWeight += 25.0;
    }
    if (hasHomework) {
      weightedSum += (homeworkScore * 20.0);
      totalWeight += 20.0;
    }
    if (hasAttendance) {
      weightedSum += (attendanceScore * 20.0);
      totalWeight += 20.0;
    }
    if (hasWellness) {
      weightedSum += (wellnessScore * 15.0);
      totalWeight += 15.0;
    }
    if (hasTests) {
      weightedSum += (testsScore * 20.0);
      totalWeight += 20.0;
    }

    final double totalScore = totalWeight > 0.0 ? (weightedSum / totalWeight).clamp(0.0, 100.0) : 0.0;
    final status = _getStatusBadge(totalScore, hasAnyData);

    final trendData = _computeDynamicMonthlyTrend(
      currentScore: totalScore,
      testReports: testReports,
      attendanceHistory: widget.kid.attendanceHistory,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Hero Overall Performance Score Card
          _buildHeroScoreCard(
            totalScore: totalScore,
            status: status,
            academicData: academicData,
            testReports: testReports,
            attendanceScore: attendanceScore,
            hasAttendance: hasAttendance,
          ),

          const SizedBox(height: 20),

          // 2. Monthly Growth / Trend Section
          _buildMonthlyGrowthSection(trendData),

          const SizedBox(height: 20),

          // 3. 5-Pillar Score Breakdown Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Performance Pillars",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ThemeColors.primaryText,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ThemeColors.primaryPurple.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "5 Core Metrics",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ThemeColors.primaryPurple,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 5-Pillar Detailed Cards (100% Dynamic & Real)
          _buildPillarCard(
            title: "Academic Subjects",
            subtitle: hasAcademic
                ? "${academicData!.academicScores.length} subjects evaluated"
                : "No teacher evaluations recorded yet",
            score: academicScore,
            weight: "25% weight",
            icon: Icons.menu_book_rounded,
            color: const Color(0xFF6366F1),
            hasData: hasAcademic,
          ),
          const SizedBox(height: 10),
          _buildPillarCard(
            title: "Homework & Assignments",
            subtitle: hasHomework
                ? "Daily tasks completion & grading"
                : "No homework scores recorded yet",
            score: homeworkScore,
            weight: "20% weight",
            icon: Icons.assignment_turned_in_rounded,
            color: const Color(0xFF0EA5E9),
            hasData: hasHomework,
          ),
          const SizedBox(height: 10),
          _buildPillarCard(
            title: "Attendance & Punctuality",
            subtitle: hasAttendance
                ? "${widget.kid.attendanceHistory.length} total school days logged"
                : "No attendance logged yet",
            score: attendanceScore,
            weight: "20% weight",
            icon: Icons.calendar_month_rounded,
            color: const Color(0xFF10B981),
            hasData: hasAttendance,
          ),
          const SizedBox(height: 10),
          _buildPillarCard(
            title: "Wellness & Behavior",
            subtitle: hasWellness
                ? "Conduct, health care & hygiene"
                : "No wellness ratings saved yet",
            score: wellnessScore,
            weight: "15% weight",
            icon: Icons.favorite_rounded,
            color: const Color(0xFFEC4899),
            hasData: hasWellness,
          ),
          const SizedBox(height: 10),
          _buildPillarCard(
            title: "Tests & Assessments",
            subtitle: hasTests
                ? "${testReports.length} test ${testReports.length == 1 ? 'assessment' : 'assessments'} recorded"
                : "No test reports submitted yet",
            score: testsScore,
            weight: "20% weight",
            icon: Icons.quiz_rounded,
            color: const Color(0xFFF59E0B),
            hasData: hasTests,
          ),
        ],
      ),
    );
  }

  // --- Ultra Modern Executive Hero Score Card ---
  Widget _buildHeroScoreCard({
    required double totalScore,
    required ({String label, String grade, Color color, Color bg, IconData icon}) status,
    required AcademicPerformanceData? academicData,
    required List<Map<String, dynamic>> testReports,
    required double attendanceScore,
    required bool hasAttendance,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Ambient soft glowing background accent
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: status.color.withOpacity(0.08),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Title Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Analytics Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: ThemeColors.primaryPurple.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: ThemeColors.primaryPurple.withOpacity(0.16)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.insights_rounded, size: 13, color: ThemeColors.primaryPurple),
                            SizedBox(width: 5),
                            Text(
                              "TOTAL PERFORMANCE",
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: ThemeColors.primaryPurple,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Grade / Standing Chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: status.bg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: status.color.withOpacity(0.35)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(status.icon, size: 13, color: status.color),
                            const SizedBox(width: 4),
                            Text(
                              status.grade,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: status.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Center Hero Row: Dual Radial Gauge + Score Breakdown
                  Row(
                    children: [
                      // Radial Progress Ring
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: totalScore),
                        duration: const Duration(milliseconds: 1400),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFF8FAFC),
                              boxShadow: [
                                BoxShadow(
                                  color: status.color.withOpacity(0.12),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: CircularProgressIndicator(
                                    value: (value / 100.0).clamp(0.0, 1.0),
                                    strokeWidth: 8,
                                    backgroundColor: const Color(0xFFE2E8F0),
                                    valueColor: AlwaysStoppedAnimation<Color>(status.color),
                                    strokeCap: StrokeCap.round,
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "${value.toStringAsFixed(0)}%",
                                      style: GoogleFonts.poppins(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0F172A),
                                        height: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "INDEX",
                                      style: GoogleFonts.inter(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(width: 18),

                      // Performance Standing & Evaluation Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Cumulative Standing",
                              style: GoogleFonts.poppins(
                                fontSize: 16.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "Aggregated across learning & development pillars",
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.grey[600],
                                height: 1.3,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Performance Status Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: status.color.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Standing: ${status.label}",
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: status.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 14),

                  // Bottom 3 Quick KPI Badges (100% Real from Teacher App)
                  Row(
                    children: [
                      _buildQuickKpi(
                        label: "Attendance",
                        value: hasAttendance ? "${attendanceScore.toInt()}%" : "N/A",
                        icon: Icons.calendar_month_rounded,
                        color: const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickKpi(
                        label: "Tests Taken",
                        value: "${testReports.length}",
                        icon: Icons.quiz_rounded,
                        color: const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickKpi(
                        label: "Subjects",
                        value: "${academicData?.academicScores.length ?? 0}",
                        icon: Icons.menu_book_rounded,
                        color: const Color(0xFF6366F1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickKpi({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // --- Monthly Growth & Trend Line Chart (Dynamic 6-Month Real Analysis) ---
  Widget _buildMonthlyGrowthSection(
    ({
      List<String> months,
      List<FlSpot> spots,
      String growthText,
      IconData growthIcon,
      Color growthColor,
      Color growthBg,
      Color growthBorder,
    }) trendData,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Grow/Down Pill
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Monthly Growth Trend",
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: ThemeColors.primaryText,
                      ),
                    ),
                    const Text(
                      "6-Month progression analysis",
                      style: TextStyle(fontSize: 11.5, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Dynamic Growth Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: trendData.growthBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: trendData.growthBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(trendData.growthIcon, size: 13, color: trendData.growthColor),
                    const SizedBox(width: 3),
                    Text(
                      trendData.growthText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: trendData.growthColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Line Chart
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey[200]!,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 25,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) => Text(
                        "${value.toInt()}%",
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < trendData.months.length) {
                          final isLast = idx == trendData.months.length - 1;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              trendData.months[idx],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isLast ? FontWeight.bold : FontWeight.w500,
                                color: isLast ? ThemeColors.primaryPurple : Colors.grey[600],
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: trendData.spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: ThemeColors.primaryPurple,
                    barWidth: 3.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        final isLast = index == trendData.spots.length - 1;
                        return FlDotCirclePainter(
                          radius: isLast ? 6 : 4,
                          color: isLast ? ThemeColors.primaryPurple : Colors.white,
                          strokeWidth: 2.5,
                          strokeColor: ThemeColors.primaryPurple,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          ThemeColors.primaryPurple.withOpacity(0.24),
                          ThemeColors.primaryPurple.withOpacity(0.01),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Pillar Score Card ---
  Widget _buildPillarCard({
    required String title,
    required String subtitle,
    required double score,
    required String weight,
    required IconData icon,
    required Color color,
    required bool hasData,
  }) {
    final displayScore = hasData ? "${score.toInt()}%" : "Pending";
    final double progressValue = hasData ? (score / 100.0).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: ThemeColors.primaryText,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: hasData ? Colors.grey[600] : Colors.grey[400],
                        fontStyle: hasData ? FontStyle.normal : FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    displayScore,
                    style: GoogleFonts.poppins(
                      fontSize: hasData ? 16 : 13,
                      fontWeight: FontWeight.bold,
                      color: hasData ? color : Colors.grey[400],
                    ),
                  ),
                  Text(
                    weight,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Animated Linear Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 6,
              backgroundColor: Colors.grey[100],
              valueColor: AlwaysStoppedAnimation<Color>(hasData ? color : Colors.grey[300]!),
            ),
          ),
        ],
      ),
    );
  }
}
