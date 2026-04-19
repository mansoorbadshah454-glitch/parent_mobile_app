import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_colors.dart';
import '../widgets/reliability_score_chart.dart';
import '../widgets/yearly_fee_calendar.dart';
import '../services/fee_calculator_service.dart';
import '../../kids/providers/kids_provider.dart';
import '../providers/fee_settings_provider.dart';

class FeeScreen extends ConsumerWidget {
  final KidData kid;
  const FeeScreen({super.key, required this.kid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kidsAsyncValue = ref.watch(kidsProvider);
    final kidsList = kidsAsyncValue.value ?? [];
    final currentKid = kidsList.firstWhere((k) => k.id == kid.id, orElse: () => kid);

    final feeSettingsAsync = ref.watch(feeSettingsProvider);
    final feeSettings = feeSettingsAsync.value ?? {};
    final String dueDate = feeSettings['dueDate']?.toString().isNotEmpty == true ? feeSettings['dueDate'].toString() : '10th';
    final String penaltyAmount = feeSettings['penaltyAmount']?.toString().isNotEmpty == true ? feeSettings['penaltyAmount'].toString() : '500';
    final String calendarInfoMessage = "Kindly ensure fee submissions are completed by the $dueDate to avoid a late penalty of Rs. $penaltyAmount.";

    List<int> paymentHistory = [1, 5, 2, 8, 4]; // Dummy history for past months
    if (currentKid.monthlyFeeStatus.toLowerCase() == 'paid' && currentKid.monthlyFeeDate != null) {
      final date = DateTime.tryParse(currentKid.monthlyFeeDate!)?.toLocal();
      if (date != null) {
        paymentHistory.add(date.day);
      }
    }

    double score = FeeCalculatorService.calculateAggregateScore(paymentHistory);
    String badgeMessage = FeeCalculatorService.getReliabilityMessage(score);
    Color badgeColor = FeeCalculatorService.getReliabilityColor(score);
    IconData badgeIcon = FeeCalculatorService.getReliabilityIcon(score);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: ThemeColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: ThemeColors.primaryPurple,
          elevation: 0,
          title: Text('${currentKid.name}\'s Fees', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(68.0), // Extra padding for fancy look
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24.0),
                ),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4.0), // minimizes default horizontal padding to prevent squishing
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: ThemeColors.primaryPurple,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 13),
                  unselectedLabelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 13),
                  splashBorderRadius: BorderRadius.circular(24.0),
                  tabs: const [
                    Tab(text: "Overview"),
                    Tab(text: "Calendar"),
                    Tab(text: "Payment"),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Overview
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      // Reliability Score Gauge
                      ReliabilityScoreChart(paymentHistoryDays: paymentHistory),
                      const SizedBox(height: 20),
                      // Info Badge
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: badgeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: badgeColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(badgeIcon, color: badgeColor),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  badgeMessage,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: badgeColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 100), // padding for scrolling
                    ],
                  ),
                ),
              ],
            ),
            
            // Tab 2: Fee Calendar
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      // Yearly Fee Grid
                      YearlyFeeCalendar(kid: currentKid),
                      const SizedBox(height: 20),
                      // Info Badge Restored
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: ThemeColors.primaryPurple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: ThemeColors.primaryPurple.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, color: ThemeColors.primaryPurple),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  calendarInfoMessage,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: ThemeColors.primaryPurple,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 100), // padding for scrolling
                    ],
                  ),
                ),
              ],
            ),

            // Tab 3: Fee Payment
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {}, // locked, does nothing yet
                    icon: const Icon(Icons.lock_rounded, color: Colors.white, size: 20),
                    label: Text(
                      'Pay Now',
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeColors.primaryPurple.withOpacity(0.5), // Dimmed to indicate locked
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Coming Soon',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
