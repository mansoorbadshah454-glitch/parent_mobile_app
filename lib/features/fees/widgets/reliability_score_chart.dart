import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_colors.dart';
import '../services/fee_calculator_service.dart';

class ReliabilityScoreChart extends StatefulWidget {
  final List<int> paymentHistoryDays; // Replaced static score with historic days array

  const ReliabilityScoreChart({super.key, required this.paymentHistoryDays});

  @override
  State<ReliabilityScoreChart> createState() => _ReliabilityScoreChartState();
}

class _ReliabilityScoreChartState extends State<ReliabilityScoreChart> {
  // Start with 0s for animation
  List<FlSpot> _spots = [
    FlSpot(0, 0),
    FlSpot(1, 0),
    FlSpot(2, 0),
    FlSpot(3, 0),
    FlSpot(4, 0),
    FlSpot(5, 0),
  ];

  double _overallScore = 0.0;

  @override
  void initState() {
    super.initState();
    // Trigger the animation shortly after mounting
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _overallScore = FeeCalculatorService.calculateAggregateScore(widget.paymentHistoryDays);

          List<FlSpot> calculatedSpots = [];
          for (int i = 0; i < widget.paymentHistoryDays.length; i++) {
            double monthlyScore = FeeCalculatorService.calculateMonthlyScore(widget.paymentHistoryDays[i]);
            calculatedSpots.add(FlSpot(i.toDouble(), monthlyScore));
          }
          _spots = calculatedSpots;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double targetScore = FeeCalculatorService.calculateAggregateScore(widget.paymentHistoryDays);
    Color badgeColor = FeeCalculatorService.getReliabilityColor(targetScore);
    String badgeText = FeeCalculatorService.getReliabilityLabel(targetScore);

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.primaryPurple.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment Reliability',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ThemeColors.primaryText,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Circular Gauge
              SizedBox(
                width: 100,
                height: 100,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: _overallScore), // Driven by pure interpolation
                  duration: const Duration(seconds: 2),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator(
                            value: value / 100,
                            strokeWidth: 10,
                            backgroundColor: Colors.grey[200],
                            color: ThemeColors.primaryPurple,
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${value.toInt()}%',
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: ThemeColors.primaryPurple,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 20),
              // Mini Line Chart (fl_chart)
              Expanded(
                child: SizedBox(
                  height: 80,
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: 100,
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (touchedSpot) => ThemeColors.primaryPurple,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) => LineTooltipItem(
                              spot.y.toInt().toString(), // Clean integer representation
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            )).toList();
                          },
                        ),
                      ),
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _spots,
                          isCurved: true,
                          color: ThemeColors.primaryPurple,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: ThemeColors.primaryPurple.withOpacity(0.15),
                          ),
                        ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Based on past 6 months of fee payments.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
