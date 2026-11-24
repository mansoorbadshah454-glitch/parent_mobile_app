import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../providers/kids_provider.dart';
import '../../../core/theme/theme_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/utils/translation_helper.dart';
import '../screens/apply_leave_screen.dart';

class AttendanceTabContent extends ConsumerStatefulWidget {
  final KidData kid;
  
  const AttendanceTabContent({Key? key, required this.kid}) : super(key: key);

  @override
  ConsumerState<AttendanceTabContent> createState() => _AttendanceTabContentState();
}

class _AttendanceTabContentState extends ConsumerState<AttendanceTabContent> {
  late DateTime _currentDate;
  late DateTime _displayedMonth;
  DateTime? _selectedDate;
  Map<DateTime, String> _mockAttendanceData = {};
  
  // Stats
  int totalPresent = 0;
  int totalAbsent = 0;

  final List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  
  final List<String> _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime.now();
    _selectedDate = DateTime(_currentDate.year, _currentDate.month, _currentDate.day);
    _displayedMonth = DateTime(_currentDate.year, _currentDate.month, 1);
    _loadRealAttendanceDataForMonth();
  }

  @override
  void didUpdateWidget(AttendanceTabContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Force a data reload and re-render on any widget update (which happens when Provider emits a new KidData)
    _loadRealAttendanceDataForMonth();
  }

  void _loadRealAttendanceDataForMonth() {
    // Reset stats
    totalPresent = 0;
    totalAbsent = 0;
    _mockAttendanceData.clear();

    final int daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;

    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(_displayedMonth.year, _displayedMonth.month, i);
      
      String dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      if (widget.kid.attendanceHistory.containsKey(dateStr)) {
        // Teacher marked attendance manually! PRIORITIZE THIS over everything else.
        String status = widget.kid.attendanceHistory[dateStr]!;
        _mockAttendanceData[date] = status;
        
        if (status == 'present') {
           totalPresent++;
        } else if (status == 'absent') {
           totalAbsent++;
        }
      } else {
        // Compute default fallback (weekend, upcoming, or unmarked)
        final todayOnlyDate = DateTime(_currentDate.year, _currentDate.month, _currentDate.day);
        
        if (date.weekday == 7) {
          // Sunday is official weekly Holiday -> Blue
          _mockAttendanceData[date] = 'holiday';
        } else if (date.weekday == 6) {
          _mockAttendanceData[date] = 'weekend';
        } else if (date.isAfter(todayOnlyDate)) {
          _mockAttendanceData[date] = 'upcoming';
        } else {
          _mockAttendanceData[date] = 'unmarked';
        }
      }
    }
    setState(() {});
  }

  void _previousMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
      _loadRealAttendanceDataForMonth();
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
      _loadRealAttendanceDataForMonth();
    });
  }

  int get _firstDayOffset {
    // Weekday returns 1 (Mon) to 7 (Sun)
    // We want Monday to be index 0
    return _displayedMonth.weekday - 1;
  }
  

  ({String msg, Color color, IconData icon, String title}) _getAttendanceData(int presents, int absents) {
    if (presents == 0 && absents == 0) {
      return (
        msg: "No attendance recorded yet. 📅 Attendance data for this month will appear here once marked by the teacher.",
        color: Colors.blue.shade500,
        icon: Icons.calendar_month_rounded,
        title: "No Data",
      );
    } else if (absents > 4) {
      return (
        msg: "Action Required. 🚨 Your child has been absent for $absents days this month. This level of absenteeism critically impacts their learning. Please contact the administration.",
        color: Colors.red.shade600,
        icon: Icons.warning_amber_rounded,
        title: "Critical Attendance",
      );
    } else if (absents > 3) {
      return (
        msg: "Needs Attention. ⚠️ Your child has accumulated $absents absences against $presents presents. Please ensure they attend classes regularly to avoid falling behind.",
        color: Colors.deepOrange.shade500,
        icon: Icons.error_outline_rounded,
        title: "High Absenteeism",
      );
    } else if (absents > 1) {
      return (
        msg: "Fair. 🌱 Your child has $absents absences this month. While $presents days of attendance is good, reducing absences will help maintain their academic flow.",
        color: Colors.orange.shade500,
        icon: Icons.info_outline_rounded,
        title: "Needs Improvement",
      );
    } else if (absents == 1) {
      return (
        msg: "Good Attendance! 😊 Your child has only missed 1 day out of ${presents + absents} tracked days. Keep up the good consistency.",
        color: Colors.teal.shade500,
        icon: Icons.thumb_up_rounded,
        title: "Very Good",
      );
    } else {
      return (
        msg: "Exceptional! 🌟 Your child has perfect attendance with $presents presents so far this month. We highly appreciate this dedication!",
        color: Colors.green.shade600,
        icon: Icons.verified_rounded,
        title: "Excellent Attendance",
      );
    }
  }

  Color _getColorForStatus(String status) {
    switch (status) {
      case 'present':
        return Colors.green.shade500;
      case 'absent':
        return Colors.red.shade500; // User explicitly requested red
      case 'leave_granted':
        return Colors.amber.shade600; // Distinct Amber color for Approved Leave
      case 'holiday':
        return Colors.blue.shade400;
      case 'unmarked':
        return Colors.grey.shade400; // Grey color for unmarked days as specifically requested
      case 'weekend':
      case 'upcoming':
      default:
        return Colors.grey.shade200;
    }
  }

  Color _getTextColorForStatus(String status) {
    if (status == 'present' || status == 'absent' || status == 'holiday' || status == 'leave_granted') {
      return Colors.white;
    }
    return ThemeColors.secondaryText;
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final badgeData = _getAttendanceData(totalPresent, totalAbsent);
    final daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final totalCells = _firstDayOffset + daysInMonth;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Selector and Calendar Card
          Container(
            padding: const EdgeInsets.all(16),
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
            child: Column(
              children: [
                // Month Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: _previousMonth,
                      color: ThemeColors.primaryPurple,
                    ),
                    Text(
                      '${TranslationHelper.translate(_monthNames[_displayedMonth.month - 1], lang)} ${_displayedMonth.year}',
                      style: TranslationHelper.getTextStyle(
                        lang,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ThemeColors.primaryText,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: _nextMonth,
                      color: ThemeColors.primaryPurple,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Days of week header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _weekDays.map((day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: (day == 'Sat' || day == 'Sun') 
                              ? Colors.grey.shade400 
                              : ThemeColors.secondaryText,
                        ),
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 12),
                
                // Calendar Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: totalCells,
                  itemBuilder: (context, index) {
                    if (index < _firstDayOffset) {
                      return const SizedBox.shrink(); // Empty slot for offset
                    }
                    
                    final dayNumber = index - _firstDayOffset + 1;
                    final date = DateTime(_displayedMonth.year, _displayedMonth.month, dayNumber);
                    final status = _mockAttendanceData[date] ?? 'upcoming';
                    final isToday = date.year == _currentDate.year && 
                                    date.month == _currentDate.month && 
                                    date.day == _currentDate.day;
                    final isSelected = _selectedDate != null &&
                                    date.year == _selectedDate!.year &&
                                    date.month == _selectedDate!.month &&
                                    date.day == _selectedDate!.day;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDate = date;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        decoration: BoxDecoration(
                          color: _getColorForStatus(status),
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.black87, width: 2.5)
                              : (isToday
                                  ? Border.all(color: ThemeColors.primaryPurple, width: 2.5)
                                  : null),
                        ),
                        child: Center(
                          child: Text(
                            '$dayNumber',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: (isToday || isSelected) ? FontWeight.bold : FontWeight.w600,
                              color: _getTextColorForStatus(status),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(),
                ),
                
                // Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildLegendItem("Present", Colors.green.shade500),
                    _buildLegendItem("Absent", Colors.red.shade500),
                    _buildLegendItem("Leave", Colors.amber.shade600),
                    _buildLegendItem("Holiday", Colors.blue.shade400),
                  ],
                ),

                // Selected Day Gate Check-In / Check-Out Details
                if (_selectedDate != null) ...[
                  const SizedBox(height: 14),
                  Builder(builder: (context) {
                    final sel = _selectedDate!;
                    final selKey =
                        '${sel.year}-${sel.month.toString().padLeft(2, '0')}-${sel.day.toString().padLeft(2, '0')}';
                    final todayKey =
                        '${_currentDate.year}-${_currentDate.month.toString().padLeft(2, '0')}-${_currentDate.day.toString().padLeft(2, '0')}';
                    final dayGate = widget.kid.gateLogs[selKey];
                    final String? inTime = (selKey == todayKey &&
                            widget.kid.gateInDate == todayKey &&
                            (widget.kid.gateInTime?.isNotEmpty ?? false))
                        ? widget.kid.gateInTime
                        : dayGate?['inTime'];
                    final String? outTime = (selKey == todayKey &&
                            widget.kid.gateOutDate == todayKey &&
                            (widget.kid.gateOutTime?.isNotEmpty ?? false))
                        ? widget.kid.gateOutTime
                        : dayGate?['outTime'];
                    final status = _mockAttendanceData[sel] ??
                        widget.kid.attendanceHistory[selKey] ??
                        'unmarked';

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('EEEE, MMM d, yyyy').format(sel),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _getColorForStatus(status),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  status == 'leave_granted'
                                      ? 'LEAVE'
                                      : status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: _getTextColorForStatus(status),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if ((inTime != null && inTime.isNotEmpty) ||
                              (outTime != null && outTime.isNotEmpty))
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                if (inTime != null && inTime.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFFA7F3D0)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.login_rounded, size: 14, color: Color(0xFF047857)),
                                        const SizedBox(width: 5),
                                        Text(
                                          'In School: $inTime',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF047857),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (outTime != null && outTime.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF7ED),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFFFED7AA)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.logout_rounded, size: 14, color: Color(0xFFC2410C)),
                                        const SizedBox(width: 5),
                                        Text(
                                          'Out: $outTime',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFFC2410C),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            )
                          else
                            Text(
                              'No Gate QR Check-In / Check-Out recorded for this date.',
                              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Apply Leave Banner & Feedback
          Builder(builder: (context) {
            final activeLeave = widget.kid.activeLeave;
            final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
            final String? leaveStatus = activeLeave?['status']?.toString();
            final String? endDateStr = activeLeave?['endDate']?.toString();

            final bool isPendingActive = activeLeave != null &&
                leaveStatus == 'pending' &&
                (endDateStr == null ||
                    endDateStr.isEmpty ||
                    endDateStr.compareTo(todayStr) >= 0);

            final bool isGrantedActive = activeLeave != null &&
                leaveStatus == 'granted' &&
                endDateStr != null &&
                endDateStr.isNotEmpty &&
                endDateStr.compareTo(todayStr) >= 0;

            final bool isRejected = activeLeave != null && leaveStatus == 'rejected';
            final bool isApplyDisabled = isPendingActive || isGrantedActive;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPendingActive)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.orange.shade100, shape: BoxShape.circle),
                          child: Icon(Icons.access_time_rounded, color: Colors.orange.shade700),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(TranslationHelper.translate('Leave Pending Review', lang), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(TranslationHelper.translate('Your recent leave application is being reviewed by the teacher.', lang), style: const TextStyle(fontSize: 13, color: Colors.black87)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isGrantedActive)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.green.shade100, shape: BoxShape.circle),
                          child: Icon(Icons.check_circle_outline_rounded, color: Colors.green.shade700),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(TranslationHelper.translate('Leave Granted', lang), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(TranslationHelper.translate('Your leave application has been approved by the teacher.', lang), style: const TextStyle(fontSize: 13, color: Colors.black87)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isRejected)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.red.shade100, shape: BoxShape.circle),
                          child: Icon(Icons.cancel_outlined, color: Colors.red.shade700),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(TranslationHelper.translate('Leave Rejected', lang), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(TranslationHelper.translate('Your recent leave application was not approved.', lang), style: const TextStyle(fontSize: 13, color: Colors.black87)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                InkWell(
                  onTap: isApplyDisabled
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ApplyLeaveScreen(kid: widget.kid),
                            ),
                          );
                        },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: isApplyDisabled ? Colors.grey.shade200 : null,
                      gradient: isApplyDisabled
                          ? null
                          : const LinearGradient(colors: [ThemeColors.primaryPurple, ThemeColors.deepPurple]),
                      borderRadius: BorderRadius.circular(16),
                      border: isApplyDisabled ? Border.all(color: Colors.grey.shade300) : null,
                      boxShadow: isApplyDisabled
                          ? null
                          : [
                              BoxShadow(color: ThemeColors.primaryPurple.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isApplyDisabled ? Colors.grey.shade300 : Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.edit_document,
                            color: isApplyDisabled ? Colors.grey.shade500 : Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                TranslationHelper.translate('Apply for Leave', lang),
                                style: TextStyle(
                                  color: isApplyDisabled ? Colors.grey.shade600 : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isPendingActive
                                    ? TranslationHelper.translate('Disabled while leave request is pending', lang)
                                    : (isGrantedActive
                                        ? TranslationHelper.translate('Disabled while leave is active', lang)
                                        : TranslationHelper.translate('Submit a sick leave or emergency application', lang)),
                                style: TextStyle(
                                  color: isApplyDisabled ? Colors.grey.shade500 : Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isApplyDisabled ? Icons.lock_outline_rounded : Icons.chevron_right,
                          color: isApplyDisabled ? Colors.grey.shade500 : Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),

          Text(
            TranslationHelper.translate("Monthly Summary", lang),
            style: TranslationHelper.getTextStyle(
              lang,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ThemeColors.primaryText,
            ).copyWith(height: 1.2),
          ),
          const SizedBox(height: 16),
          _buildInfoBadge(badgeData, lang),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: ThemeColors.secondaryText,
          ),
        ),
      ],
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
