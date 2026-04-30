import 'package:flutter/material.dart';
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
        
        if (date.weekday == 6 || date.weekday == 7) {
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
  
  double get _attendancePercentage {
    final total = totalPresent + totalAbsent;
    if (total == 0) return 100.0; // Avoid division by zero if all days are future/weekends
    return (totalPresent / total) * 100;
  }

  ({String msg, Color color, IconData icon, String title}) _getAttendanceData(double percentage) {
    if (percentage >= 95) {
      return (
        msg: "Exceptional! 🌟 Your child is highly punctual and rarely misses a class. Great consistency!",
        color: Colors.green.shade600,
        icon: Icons.verified_rounded,
        title: "Excellent Attendance",
      );
    } else if (percentage >= 80) {
      return (
        msg: "Good Attendance! 😊 Your child maintains a very healthy attendance record.",
        color: Colors.teal.shade500,
        icon: Icons.thumb_up_rounded,
        title: "Very Good",
      );
    } else if (percentage >= 60) {
      return (
        msg: "Fair. 🌱 Frequent absences can impact learning flow. Let's aim for better consistency.",
        color: Colors.orange.shade500,
        icon: Icons.info_outline_rounded,
        title: "Needs Improvement",
      );
    } else {
      // User specified red for poor attendance
      return (
        msg: "Needs Attention. 🚨 Significant absences have been recorded. Punctuality is key to success.",
        color: Colors.red.shade600,
        icon: Icons.warning_amber_rounded,
        title: "Low Attendance",
      );
    }
  }

  Color _getColorForStatus(String status) {
    switch (status) {
      case 'present':
        return Colors.green.shade500;
      case 'absent':
        return Colors.red.shade500; // User explicitly requested red
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
    if (status == 'present' || status == 'absent' || status == 'holiday') {
      return Colors.white;
    }
    return ThemeColors.secondaryText;
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final badgeData = _getAttendanceData(_attendancePercentage);
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

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: _getColorForStatus(status),
                        shape: BoxShape.circle,
                        border: isToday 
                            ? Border.all(color: ThemeColors.primaryPurple, width: 2.5) 
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '$dayNumber',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                            color: _getTextColorForStatus(status),
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
                    _buildLegendItem("Holiday", Colors.blue.shade400),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Apply Leave Banner
          if (widget.kid.activeLeave != null && widget.kid.activeLeave!['status'] == 'pending')
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Leave Pending Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 4),
                        Text('Your recent leave application is being reviewed by the teacher.', style: TextStyle(fontSize: 13, color: Colors.black87)),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ApplyLeaveScreen(kid: widget.kid)
                ));
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [ThemeColors.primaryPurple, ThemeColors.deepPurple]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: ThemeColors.primaryPurple.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.edit_document, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Apply for Leave', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(height: 4),
                          Text('Submit a sick leave or emergency application', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
            ),

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
