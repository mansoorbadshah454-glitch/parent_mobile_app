import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_colors.dart';
import '../widgets/reliability_score_chart.dart';
import '../widgets/yearly_fee_calendar.dart';
import '../services/fee_calculator_service.dart';
import '../../kids/providers/kids_provider.dart';
import '../providers/fee_settings_provider.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/utils/translation_helper.dart';
import '../../../core/providers/parent_data_provider.dart';

class FeeScreen extends ConsumerWidget {
  final KidData kid;
  const FeeScreen({super.key, required this.kid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kidsAsyncValue = ref.watch(kidsProvider);
    final kidsList = kidsAsyncValue.value ?? [];
    final currentKid = kidsList.firstWhere((k) => k.id == kid.id, orElse: () => kid);
    
    final parentDataAsync = ref.watch(parentDataProvider);
    final String schoolName = parentDataAsync.value?.schoolName ?? 'School';

    final feeSettingsAsync = ref.watch(feeSettingsProvider);
    final feeSettings = feeSettingsAsync.value ?? {};
    final String dueDate = feeSettings['dueDate']?.toString().isNotEmpty == true ? feeSettings['dueDate'].toString() : '10th';
    final String penaltyAmount = feeSettings['penaltyAmount']?.toString().isNotEmpty == true ? feeSettings['penaltyAmount'].toString() : '500';
    final String calendarInfoMessage = "Kindly ensure fee submissions are completed by the $dueDate to avoid a late penalty of Rs. $penaltyAmount.";
    final lang = ref.watch(languageProvider);

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
          title: Text('${currentKid.name}\'s Fees', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
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
                  labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                  unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
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
                      ReliabilityScoreChart(paymentHistoryDays: paymentHistory, lang: lang),
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
                                  TranslationHelper.translate(badgeMessage, lang),
                                  style: lang == 'en' 
                                    ? GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: badgeColor,
                                      )
                                    : TranslationHelper.getTextStyle(
                                        lang,
                                        fontSize: 13,
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
                                  TranslationHelper.translate(calendarInfoMessage, lang),
                                  style: lang == 'en'
                                    ? GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: ThemeColors.primaryPurple,
                                      )
                                    : TranslationHelper.getTextStyle(
                                        lang,
                                        fontSize: 13,
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
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  FeeReceiptWidget(kid: currentKid, schoolName: schoolName),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {}, // locked, does nothing yet
                    icon: const Icon(Icons.lock_rounded, color: Colors.white, size: 20),
                    label: Text(
                      'Pay Now',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
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
                    style: GoogleFonts.inter(
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

class _ZigZagClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    double notchSize = 6.0;

    // Top ZigZag
    path.moveTo(0, notchSize);
    for (double i = 0; i < size.width; i += notchSize * 2) {
      path.lineTo(i + notchSize, 0);
      path.lineTo(i + notchSize * 2, notchSize);
    }
    
    // Right edge
    path.lineTo(size.width, size.height - notchSize);

    // Bottom ZigZag
    for (double i = size.width; i > 0; i -= notchSize * 2) {
      path.lineTo(i - notchSize, size.height);
      path.lineTo(i - notchSize * 2, size.height - notchSize);
    }

    // Left edge
    path.lineTo(0, notchSize);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class FeeReceiptWidget extends StatelessWidget {
  final KidData kid;
  final String schoolName;
  const FeeReceiptWidget({super.key, required this.kid, required this.schoolName});

  @override
  Widget build(BuildContext context) {
    bool isPaid = kid.monthlyFeeStatus.toLowerCase() == 'paid';
    double totalRecurring = 0;
    for (var fee in kid.feeStructure) {
      totalRecurring += (fee['amount'] as num?)?.toDouble() ?? 0.0;
    }

    double totalActions = 0;
    double paidActions = 0;
    for (var action in kid.individualActions) {
      totalActions += (action['amount'] as num?)?.toDouble() ?? 0.0;
      if (action['status'] == 'paid') {
        paidActions += (action['amount'] as num?)?.toDouble() ?? 0.0;
      }
    }

    double grandTotal = totalRecurring + totalActions;
    double totalPaid = (isPaid ? totalRecurring : 0) + paidActions;
    double totalDue = grandTotal - totalPaid;

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipPath(
        clipper: _ZigZagClipper(),
        child: Container(
          width: double.infinity,
          color: const Color(0xFFFDFBF7), // receipt paper color
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      schoolName.toUpperCase(),
                      style: GoogleFonts.spaceMono(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: ThemeColors.primaryPurple,
                        letterSpacing: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'FEE RECEIPT',
                      style: GoogleFonts.spaceMono(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Date: ${DateTime.now().toIso8601String().substring(0, 10)}',
                      style: GoogleFonts.spaceMono(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDashedLine(),
              const SizedBox(height: 16),
              Text('RECURRING FEES', style: GoogleFonts.spaceMono(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 8),
              if (kid.feeStructure.isEmpty)
                Text('  None', style: GoogleFonts.spaceMono(fontSize: 14, color: Colors.black54)),
              ...kid.feeStructure.map((f) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(f['name']?.toString() ?? 'Fee', style: GoogleFonts.spaceMono(fontSize: 14, color: Colors.black87)),
                        Text('Rs ${f['amount']}', style: GoogleFonts.spaceMono(fontSize: 14, color: Colors.black87)),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
              Text('INDIVIDUAL ACTIONS', style: GoogleFonts.spaceMono(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 8),
              if (kid.individualActions.isEmpty)
                Text('  None', style: GoogleFonts.spaceMono(fontSize: 14, color: Colors.black54)),
              ...kid.individualActions.map((a) {
                bool actionPaid = a['status'] == 'paid';
                return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text('${a['name']}\n(${actionPaid ? 'paid' : 'unpaid'})', style: GoogleFonts.spaceMono(fontSize: 14, color: actionPaid ? Colors.green[700] : Colors.black87, height: 1.2))),
                        Text('Rs ${a['amount']}', style: GoogleFonts.spaceMono(fontSize: 14, color: actionPaid ? Colors.green[700] : Colors.black87)),
                      ],
                    ),
                  );
              }),
              const SizedBox(height: 16),
              _buildDashedLine(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TOTAL BILL', style: GoogleFonts.spaceMono(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
                  Text('Rs $grandTotal', style: GoogleFonts.spaceMono(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('PAID AMOUNT', style: GoogleFonts.spaceMono(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green[700])),
                  Text('- Rs $totalPaid', style: GoogleFonts.spaceMono(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green[700])),
                ],
              ),
              const SizedBox(height: 8),
              _buildDashedLine(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('AMOUNT DUE', style: GoogleFonts.spaceMono(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  Text('Rs $totalDue', style: GoogleFonts.spaceMono(fontSize: 16, fontWeight: FontWeight.bold, color: totalDue > 0 ? Colors.red[700] : Colors.green[700])),
                ],
              ),
            ],
          ),
          Positioned(
                top: 25,
                left: 12,
                child: Transform.rotate(
                  angle: -0.25, // classic stamp tilt
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPaid ? Colors.green.withOpacity(0.05) : Colors.red.withOpacity(0.05),
                      border: Border.all(color: isPaid ? Colors.green : Colors.red, width: 3),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: isPaid ? Colors.green : Colors.red, width: 1),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isPaid ? Icons.verified : Icons.do_not_disturb_alt, 
                              color: isPaid ? Colors.green : Colors.red, 
                              size: 24
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isPaid ? 'PAID' : 'UNPAID',
                              style: GoogleFonts.spaceMono(
                                color: isPaid ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(decoration: BoxDecoration(color: Colors.black38)),
            );
          }),
        );
      },
    );
  }
}
