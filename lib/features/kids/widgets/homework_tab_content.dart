import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/kids_provider.dart';
import '../providers/homework_provider.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/providers/language_provider.dart';

class HomeworkTabContent extends ConsumerStatefulWidget {
  final KidData kid;

  const HomeworkTabContent({Key? key, required this.kid}) : super(key: key);

  @override
  ConsumerState<HomeworkTabContent> createState() => _HomeworkTabContentState();
}

class _HomeworkTabContentState extends ConsumerState<HomeworkTabContent> {
  String _selectedSubject = 'All';
  final Set<String> _expandedIds = {};

  void _toggleExpand(String id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
  }

  Color _getSubjectColor(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('math')) return const Color(0xFF6366F1);
    if (s.contains('eng')) return const Color(0xFF0EA5E9);
    if (s.contains('sci') || s.contains('phys') || s.contains('chem') || s.contains('bio')) return const Color(0xFF10B981);
    if (s.contains('urdu')) return const Color(0xFFF59E0B);
    if (s.contains('islam') || s.contains('isl')) return const Color(0xFF059669);
    if (s.contains('comp') || s.contains('it')) return const Color(0xFF8B5CF6);
    if (s.contains('soc') || s.contains('hist') || s.contains('geo')) return const Color(0xFFEC4899);
    return ThemeColors.primaryPurple;
  }

  IconData _getSubjectIcon(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('math')) return Icons.calculate_rounded;
    if (s.contains('eng')) return Icons.menu_book_rounded;
    if (s.contains('sci') || s.contains('phys') || s.contains('chem') || s.contains('bio')) return Icons.science_rounded;
    if (s.contains('urdu')) return Icons.auto_stories_rounded;
    if (s.contains('islam') || s.contains('isl')) return Icons.mosque_rounded;
    if (s.contains('comp') || s.contains('it')) return Icons.computer_rounded;
    if (s.contains('soc') || s.contains('hist') || s.contains('geo')) return Icons.public_rounded;
    return Icons.assignment_rounded;
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return "${dt.day} ${months[dt.month - 1]} ${dt.year}";
    } catch (_) {
      return dateStr;
    }
  }

  ({String label, Color color, Color bg}) _getDueStatus(HomeworkItem item) {
    final today = DateTime.now();
    final todayStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    if (item.assignedDate == todayStr) {
      return (label: "Today's Task", color: const Color(0xFF059669), bg: const Color(0xFFECFDF5));
    }

    if (item.dueDate.isNotEmpty) {
      if (item.dueDate == todayStr) {
        return (label: "Due Today", color: const Color(0xFFD97706), bg: const Color(0xFFFFFBEB));
      }
      try {
        final due = DateTime.parse(item.dueDate);
        final diff = due.difference(DateTime(today.year, today.month, today.day)).inDays;
        if (diff == 1) {
          return (label: "Due Tomorrow", color: const Color(0xFF2563EB), bg: const Color(0xFFEFF6FF));
        } else if (diff < 0) {
          return (label: "Past Due", color: const Color(0xFF6B7280), bg: const Color(0xFFF3F4F6));
        } else {
          return (label: "Due in $diff days", color: const Color(0xFF4F46E5), bg: const Color(0xFFEEF2FF));
        }
      } catch (_) {}
    }

    return (label: "Assigned", color: ThemeColors.primaryPurple, bg: const Color(0xFFF5F3FF));
  }

  ({
    String label,
    Color color,
    Color bg,
    IconData icon,
    String? remark,
    bool isTeacherVerified,
  }) _getStudentHomeworkStatus(HomeworkItem item, KidData kid) {
    // 1. Check direct submission in homework document
    if (item.submissions.containsKey(kid.id)) {
      final sub = item.submissions[kid.id];
      if (sub is Map) {
        final statusStr = sub['status']?.toString().toLowerCase().trim() ?? '';
        final score = sub['score'];
        final num? scoreNum = score is num ? score : num.tryParse(score?.toString() ?? '');

        if (statusStr == 'done' || (scoreNum != null && scoreNum >= 75)) {
          return (
            label: "Done (100%)",
            color: const Color(0xFF059669),
            bg: const Color(0xFFECFDF5),
            icon: Icons.check_circle_rounded,
            remark: "Teacher Checked: Completed & Verified",
            isTeacherVerified: true,
          );
        } else if (statusStr == 'incomplete' || (scoreNum != null && scoreNum >= 25 && scoreNum < 75)) {
          return (
            label: "Incomplete (50%)",
            color: const Color(0xFFD97706),
            bg: const Color(0xFFFFFBEB),
            icon: Icons.timelapse_rounded,
            remark: "Teacher Marked: Homework is Incomplete",
            isTeacherVerified: true,
          );
        } else if (statusStr == 'not_done' || statusStr == 'notdone' || (scoreNum != null && scoreNum < 25)) {
          return (
            label: "Not Done (0%)",
            color: const Color(0xFFDC2626),
            bg: const Color(0xFFFEF2F2),
            icon: Icons.cancel_rounded,
            remark: "Teacher Marked: Homework was Not Done",
            isTeacherVerified: true,
          );
        }
      } else if (sub is String) {
        final s = sub.toLowerCase().trim();
        if (s == 'done') {
          return (
            label: "Done (100%)",
            color: const Color(0xFF059669),
            bg: const Color(0xFFECFDF5),
            icon: Icons.check_circle_rounded,
            remark: "Teacher Checked: Completed & Verified",
            isTeacherVerified: true,
          );
        } else if (s == 'incomplete') {
          return (
            label: "Incomplete (50%)",
            color: const Color(0xFFD97706),
            bg: const Color(0xFFFFFBEB),
            icon: Icons.timelapse_rounded,
            remark: "Teacher Marked: Homework is Incomplete",
            isTeacherVerified: true,
          );
        } else if (s == 'not_done' || s == 'notdone') {
          return (
            label: "Not Done (0%)",
            color: const Color(0xFFDC2626),
            bg: const Color(0xFFFEF2F2),
            icon: Icons.cancel_rounded,
            remark: "Teacher Marked: Homework was Not Done",
            isTeacherVerified: true,
          );
        }
      }
    }

    // 2. Check student's homeworkScores array (fallback)
    if (kid.homeworkScores.isNotEmpty) {
      Map<String, dynamic>? match = kid.homeworkScores.firstWhere(
        (h) => h['homeworkId'] != null && h['homeworkId'].toString() == item.id,
        orElse: () => <String, dynamic>{},
      );

      if (match.isEmpty && item.assignedDate.isNotEmpty) {
        final hwDate = item.assignedDate.length >= 10 ? item.assignedDate.substring(0, 10) : item.assignedDate;
        match = kid.homeworkScores.firstWhere(
          (h) =>
              h['subject'] != null &&
              h['subject'].toString().toLowerCase() == item.subject.toLowerCase() &&
              (h['date']?.toString() == hwDate),
          orElse: () => <String, dynamic>{},
        );
      }

      if (match.isNotEmpty) {
        final statusStr = match['status']?.toString().toLowerCase().trim() ?? '';
        final score = match['score'];
        final num? scoreNum = score is num ? score : num.tryParse(score?.toString() ?? '');

        if (statusStr == 'done' || (scoreNum != null && scoreNum >= 75)) {
          return (
            label: "Done (100%)",
            color: const Color(0xFF059669),
            bg: const Color(0xFFECFDF5),
            icon: Icons.check_circle_rounded,
            remark: "Teacher Checked: Completed & Verified",
            isTeacherVerified: true,
          );
        } else if (statusStr == 'incomplete' || (scoreNum != null && scoreNum >= 25 && scoreNum < 75)) {
          return (
            label: "Incomplete (50%)",
            color: const Color(0xFFD97706),
            bg: const Color(0xFFFFFBEB),
            icon: Icons.timelapse_rounded,
            remark: "Teacher Marked: Homework is Incomplete",
            isTeacherVerified: true,
          );
        } else if (statusStr == 'not_done' || statusStr == 'notdone' || (scoreNum != null && scoreNum < 25)) {
          return (
            label: "Not Done (0%)",
            color: const Color(0xFFDC2626),
            bg: const Color(0xFFFEF2F2),
            icon: Icons.cancel_rounded,
            remark: "Teacher Marked: Homework was Not Done",
            isTeacherVerified: true,
          );
        }
      }
    }

    // 3. Fallback to Due Date Status if Teacher hasn't marked yet
    final due = _getDueStatus(item);
    return (
      label: due.label,
      color: due.color,
      bg: due.bg,
      icon: Icons.schedule_rounded,
      remark: null,
      isTeacherVerified: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeworkAsync = ref.watch(classHomeworkProvider((
      classId: widget.kid.classId,
      className: widget.kid.className,
    )));
    final lang = ref.watch(languageProvider);

    return homeworkAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: ThemeColors.primaryPurple),
        ),
      ),
      error: (e, st) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              const Text(
                "Failed to load homework.",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text("$e", style: const TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
      data: (homeworkList) {
        final List<HomeworkItem> activeItems = _getActiveSubjectHomework(homeworkList);

        if (activeItems.isEmpty) {
          return _buildEmptyState(lang);
        }

        // Extract subjects for filter
        final subjects = ['All', ...activeItems.map((h) => h.subject).toSet().toList()];

        final filteredItems = _selectedSubject == 'All'
            ? activeItems
            : activeItems.where((h) => h.subject.toLowerCase() == _selectedSubject.toLowerCase()).toList();

        return Column(
          children: [
            // Filter Pills (only if more than 1 subject has active homework)
            if (subjects.length > 2)
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: subjects.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final subj = subjects[index];
                    final isSelected = _selectedSubject == subj;
                    final subjColor = subj == 'All' ? ThemeColors.primaryPurple : _getSubjectColor(subj);

                    return ChoiceChip(
                      label: Text(subj),
                      selected: isSelected,
                      selectedColor: subjColor,
                      backgroundColor: Colors.grey[100],
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[800],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      side: BorderSide(color: isSelected ? subjColor : Colors.grey[300]!),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedSubject = subj);
                        }
                      },
                    );
                  },
                ),
              ),

            // 1 Card per Active Subject
            Expanded(
              child: filteredItems.isEmpty
                  ? Center(
                      child: Text(
                        "No homework found for $_selectedSubject",
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final isExpanded = _expandedIds.contains(item.id);
                        return _buildExpandableHomeworkCard(
                          item: item,
                          isExpanded: isExpanded,
                          lang: lang,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  List<HomeworkItem> _getActiveSubjectHomework(List<HomeworkItem> allHomework) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final todayStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    final yesterday = todayDate.subtract(const Duration(days: 1));
    final yesterdayStr = "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";

    // Group by subject (case-insensitive)
    final Map<String, List<HomeworkItem>> subjectMap = {};
    for (final hw in allHomework) {
      final subj = hw.subject.trim();
      if (subj.isEmpty) continue;
      final key = subj.toLowerCase();
      subjectMap.putIfAbsent(key, () => []).add(hw);
    }

    final List<HomeworkItem> result = [];

    for (final entry in subjectMap.entries) {
      final items = entry.value;
      // Sort newest assignedDate / createdAt descending
      items.sort((a, b) {
        if (a.createdAt != null && b.createdAt != null) {
          return b.createdAt!.compareTo(a.createdAt!);
        }
        return b.assignedDate.compareTo(a.assignedDate);
      });

      final latest = items.first;

      // Card appears ONLY IF assigned today OR assigned yesterday OR due today/future!
      // If older, it DISAPPEARS!
      bool isActive = false;
      if (latest.assignedDate == todayStr || latest.assignedDate == yesterdayStr) {
        isActive = true;
      } else if (latest.dueDate.isNotEmpty) {
        try {
          final due = DateTime.parse(latest.dueDate);
          if (!due.isBefore(yesterday)) {
            isActive = true;
          }
        } catch (_) {}
      }

      if (isActive) {
        result.add(latest);
      }
    }

    return result;
  }

  Widget _buildExpandableHomeworkCard({
    required HomeworkItem item,
    required bool isExpanded,
    required String lang,
  }) {
    final subjColor = _getSubjectColor(item.subject);
    final subjIcon = _getSubjectIcon(item.subject);
    final status = _getStudentHomeworkStatus(item, widget.kid);

    final titleText = [
      if (item.chapter.isNotEmpty) item.chapter,
      if (item.topic.isNotEmpty) item.topic,
    ].join(' • ');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isExpanded
              ? (status.isTeacherVerified ? status.color.withOpacity(0.4) : subjColor.withOpacity(0.35))
              : (status.isTeacherVerified && status.label.startsWith('Not')
                  ? status.color.withOpacity(0.35)
                  : Colors.grey[200]!),
          width: isExpanded ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isExpanded 
                ? subjColor.withOpacity(0.08) 
                : Colors.black.withOpacity(0.03),
            blurRadius: isExpanded ? 14 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _toggleExpand(item.id),
            splashColor: subjColor.withOpacity(0.08),
            highlightColor: subjColor.withOpacity(0.04),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: subjColor, width: 6),
                ),
              ),
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header: Subject Badge on Left + Status Pill & Chevron on Right
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Subject Tag
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: subjColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(subjIcon, color: subjColor, size: 14),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  item.subject,
                                  style: TextStyle(
                                    color: subjColor,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Status Pill (Teacher Verification or Due Status)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: status.bg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: status.color.withOpacity(0.35)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(status.icon, size: 12, color: status.color),
                            const SizedBox(width: 4),
                            Text(
                              status.label,
                              style: TextStyle(
                                color: status.color,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Expand / Collapse Chevron Button
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: isExpanded ? subjColor.withOpacity(0.1) : Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: isExpanded ? subjColor : Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Chapter & Topic Headline
                  Text(
                    titleText.isNotEmpty ? titleText : "Homework Task",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: ThemeColors.primaryText,
                    ),
                    maxLines: isExpanded ? null : 1,
                    overflow: isExpanded ? null : TextOverflow.ellipsis,
                  ),

                  // Smooth Transition Area
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 220),
                    firstCurve: Curves.easeInOut,
                    secondCurve: Curves.easeInOut,
                    sizeCurve: Curves.easeInOut,
                    crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    
                    // First Child: Compact Collapsed Row (Dates only, clean)
                    firstChild: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(item.assignedDate),
                                style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          if (item.dueDate.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.alarm_rounded, size: 12, color: Colors.redAccent.shade400),
                                const SizedBox(width: 4),
                                Text(
                                  "Due: ${_formatDate(item.dueDate)}",
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.redAccent.shade400,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),

                    // Second Child: Expanded Details (Clean & Minimal)
                    secondChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),

                        // Teacher Verification Notice if checked
                        if (status.isTeacherVerified && status.remark != null) ...[
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: status.bg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: status.color.withOpacity(0.35)),
                            ),
                            child: Row(
                              children: [
                                Icon(status.icon, size: 18, color: status.color),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    status.remark!,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: status.color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Full Description Box
                        if (item.description.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.notes_rounded, size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Task Instructions:",
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.description,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF374151),
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        const Divider(height: 1, color: Color(0xFFF3F4F6)),
                        const SizedBox(height: 10),

                        // Full Details Footer Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Assigned Date
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Assigned Date",
                                  style: TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDate(item.assignedDate),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // Due Date
                            if (item.dueDate.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    "Submission Due",
                                    style: TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(Icons.alarm_rounded, size: 13, color: Colors.redAccent.shade400),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDate(item.dueDate),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.redAccent.shade400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- AI Study & Homework Tips Card ---
  Widget _buildAiTipsCard(List<HomeworkItem> homeworkList, String lang) {
    final today = DateTime.now();
    final todayStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    final dueTodayCount = homeworkList.where((h) => h.dueDate == todayStr || h.assignedDate == todayStr).length;

    String primaryAdvice;
    if (dueTodayCount > 1) {
      primaryAdvice = "Priority Advice: Multiple tasks are active today. Encourage starting with the hardest subject first while energy is highest, followed by quick revision.";
    } else if (dueTodayCount == 1) {
      primaryAdvice = "Focus Tip: Set aside a dedicated 30-minute quiet study block today. Consistent daily completion builds strong academic confidence.";
    } else {
      primaryAdvice = "Habit Builder: Use light homework days for 15-minute concept review and reading to stay ahead of upcoming class lessons.";
    }

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 24),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7C3AED).withOpacity(0.06),
            const Color(0xFF6366F1).withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ThemeColors.primaryPurple.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: ThemeColors.primaryPurple, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "AI Study & Homework Guide",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: ThemeColors.primaryPurple,
                      ),
                    ),
                    const Text(
                      "Smart tips for effective home learning",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded, size: 13, color: Colors.green.shade700),
                    const SizedBox(width: 2),
                    Text(
                      "Daily Tip",
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Primary Dynamic Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.12)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFF59E0B), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    primaryAdvice,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey.shade800,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 3 Actionable Bullet Points
          _buildTipBullet(
            icon: Icons.timer_outlined,
            iconColor: const Color(0xFF6366F1),
            title: "25-Minute Focus Rule",
            description: "Study in 25-minute intervals followed by a 5-minute break for peak concentration.",
          ),
          const SizedBox(height: 8),
          _buildTipBullet(
            icon: Icons.phonelink_erase_rounded,
            iconColor: const Color(0xFFEC4899),
            title: "Distraction-Free Zone",
            description: "Keep smartphones, TVs, and toys away from the study desk during homework hours.",
          ),
          const SizedBox(height: 8),
          _buildTipBullet(
            icon: Icons.backpack_outlined,
            iconColor: const Color(0xFF10B981),
            title: "Pack Immediately",
            description: "Place completed notebooks right into the school bag to ensure on-time submission.",
          ),
        ],
      ),
    );
  }

  Widget _buildTipBullet({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: iconColor, size: 13),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563), height: 1.35),
              children: [
                TextSpan(
                  text: "$title: ",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                ),
                TextSpan(text: description),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String lang) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: ThemeColors.primaryPurple.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.task_alt_rounded, size: 64, color: ThemeColors.primaryPurple),
                ),
                const SizedBox(height: 20),
                const Text(
                  "No Homework Assigned 🎉",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ThemeColors.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "There is no active homework for this class right now. Check back when teachers assign new tasks.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, height: 1.4, fontSize: 13),
                ),
              ],
            ),
          ),
          _buildAiTipsCard([], lang),
        ],
      ),
    );
  }
}
