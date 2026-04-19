import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_colors.dart';

enum FeeStatus { paid, pending, overdue, upcoming }

class MonthFee {
  final String monthName;
  final FeeStatus status;
  final double amount;

  MonthFee({required this.monthName, required this.status, required this.amount});
}

class YearlyFeeCalendar extends StatelessWidget {
  YearlyFeeCalendar({super.key});

  final List<MonthFee> months = [
    MonthFee(monthName: 'Jan', status: FeeStatus.paid, amount: 150),
    MonthFee(monthName: 'Feb', status: FeeStatus.paid, amount: 150),
    MonthFee(monthName: 'Mar', status: FeeStatus.paid, amount: 150),
    MonthFee(monthName: 'Apr', status: FeeStatus.paid, amount: 150),
    MonthFee(monthName: 'May', status: FeeStatus.pending, amount: 150),
    MonthFee(monthName: 'Jun', status: FeeStatus.upcoming, amount: 0),
    MonthFee(monthName: 'Jul', status: FeeStatus.upcoming, amount: 0),
    MonthFee(monthName: 'Aug', status: FeeStatus.upcoming, amount: 0),
    MonthFee(monthName: 'Sep', status: FeeStatus.upcoming, amount: 0),
    MonthFee(monthName: 'Oct', status: FeeStatus.upcoming, amount: 0),
    MonthFee(monthName: 'Nov', status: FeeStatus.upcoming, amount: 0),
    MonthFee(monthName: 'Dec', status: FeeStatus.upcoming, amount: 0),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fee Calendar 2026',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ThemeColors.primaryText,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: ThemeColors.primaryPurple.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1, // Adjusted since we remove text
              ),
              itemCount: months.length,
              itemBuilder: (context, index) {
                final month = months[index];
                return _buildMonthCard(month);
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildMonthCard(MonthFee month) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (month.status) {
      case FeeStatus.paid:
        bgColor = Colors.green;
        textColor = Colors.white;
        icon = Icons.check_circle_rounded;
        break;
      case FeeStatus.pending:
        bgColor = Colors.orange;
        textColor = Colors.white;
        icon = Icons.access_time_filled_rounded;
        break;
      case FeeStatus.overdue:
        bgColor = Colors.red;
        textColor = Colors.white;
        icon = Icons.error_rounded;
        break;
      case FeeStatus.upcoming:
        bgColor = Colors.grey[300]!;
        textColor = Colors.grey[600]!;
        icon = Icons.lock_clock_rounded;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withOpacity(0.2), width: 1),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 8,
            right: 8,
            child: Icon(icon, color: textColor, size: 16),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  month.monthName,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor == Colors.white ? Colors.white : ThemeColors.primaryText,
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
