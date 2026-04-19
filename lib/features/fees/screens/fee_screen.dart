import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_colors.dart';
import '../widgets/reliability_score_chart.dart';
import '../widgets/yearly_fee_calendar.dart';
import '../../kids/providers/kids_provider.dart';

class FeeScreen extends StatelessWidget {
  final KidData kid;
  const FeeScreen({super.key, required this.kid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: ThemeColors.primaryPurple,
        elevation: 0,
        title: Text('${kid.name}\'s Fees', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                // Reliability Score Gauge
                const ReliabilityScoreChart(paymentHistoryDays: [1, 5, 2, 8, 4, 12]),

                const SizedBox(height: 10),

                // Yearly Fee Grid
                YearlyFeeCalendar(),

                const SizedBox(height: 100), // padding for scrolling
              ],
            ),
          ),
        ],
      ),
    );
  }
}
