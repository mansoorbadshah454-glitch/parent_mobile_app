import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../kids/providers/kids_provider.dart';
import '../../kids/widgets/shining_profile_avatar.dart';
import '../widgets/pay_family_fee_bottom_sheet.dart';
import '../services/fee_calculator_service.dart';
import 'fee_screen.dart';

class FeesDashboardScreen extends ConsumerWidget {
  const FeesDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kidsAsyncValue = ref.watch(kidsProvider);

    return Scaffold(
      backgroundColor: ThemeColors.backgroundColor,
      body: Builder(
        builder: (context) {
          try {
            if (kidsAsyncValue.hasValue) {
              final kids = kidsAsyncValue.value ?? [];
              if (kids.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.family_restroom, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        const Text(
                          'No kids linked to this account.',
                          style: TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final int totalKids = kids.length;
              final int paidKids = kids.where((k) {
                final status = k.monthlyFeeStatus.trim().toLowerCase();
                return status == 'paid';
              }).length;
              final int unpaidKids = totalKids - paidKids;

              double totalUnpaidAmount = 0.0;
              for (final kid in kids) {
                final status = kid.monthlyFeeStatus.trim().toLowerCase();
                if (status != 'paid') {
                  double kidDue = 0.0;
                  for (var fee in kid.feeStructure) {
                    kidDue += FeeCalculatorService.parseDouble(fee['amount']);
                  }
                  for (var act in kid.individualActions) {
                    final actStatus = (act['status'] ?? '').toString().trim().toLowerCase();
                    if (actStatus != 'paid') {
                      kidDue += FeeCalculatorService.parseDouble(act['amount']);
                    }
                  }
                  if (kidDue <= 0) kidDue = 1000.0;
                  totalUnpaidAmount += kidDue;
                }
              }

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                children: [
                  // 1. Stats Summary Card
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn('Total Kids', totalKids.toString(), ThemeColors.primaryPurple),
                        Container(width: 1, height: 40, color: Colors.grey[200]),
                        _buildStatColumn('Fee Paid', paidKids.toString(), Colors.green),
                        Container(width: 1, height: 40, color: Colors.grey[200]),
                        _buildStatColumn('Unpaid', unpaidKids.toString(), Colors.redAccent),
                      ],
                    ),
                  ),

                  // 2. Multi-Child "Pay All" Action Banner
                  if (unpaidKids > 0) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6B21A8), Color(0xFF9333EA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF9333EA).withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.diversity_3_rounded, color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  unpaidKids > 1 ? 'Pay All Dues ($unpaidKids Children)' : 'Pay School Fee',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Total: Rs. ${totalUnpaidAmount.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () => PayFamilyFeeBottomSheet.show(context, kids),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                unpaidKids > 1 ? 'Pay All' : 'Pay Now',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF6B21A8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // 3. Children Cards List
                  ...kids.map((kid) {
                    final isPaid = kid.monthlyFeeStatus.trim().toLowerCase() == 'paid';
                    final isPending = kid.pendingPaymentSubmission != null &&
                        (kid.pendingPaymentSubmission!['status'] ?? '').toString().trim().toLowerCase() == 'pending';
                    final isRejected = kid.pendingPaymentSubmission != null &&
                        (kid.pendingPaymentSubmission!['status'] ?? '').toString().trim().toLowerCase() == 'rejected';

                    final dueBadgeColor = isPaid
                        ? Colors.green
                        : (isRejected
                            ? Colors.red.shade700
                            : (isPending ? Colors.amber.shade800 : Colors.redAccent));
                    final dueBadgeText = isPaid
                        ? 'Fee Paid'
                        : (isRejected
                            ? 'Payment Rejected'
                            : (isPending ? 'Under Review' : 'Unpaid'));

                    return Card(
                      color: Colors.white,
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 12.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FeeScreen(kid: kid),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              ShiningProfileAvatar(
                                imageUrl: kid.imageUrl,
                                radius: 28,
                                strokeWidth: 2.5,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      kid.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: ThemeColors.primaryText,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Roll: ${kid.rollNo}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Class: ${kid.className}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: dueBadgeColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: dueBadgeColor.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      dueBadgeText,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: dueBadgeColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 20),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 80),
                ],
              );
            }

            if (kidsAsyncValue.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: ThemeColors.primaryPurple),
              );
            }

            if (kidsAsyncValue.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Error loading fee data:\n${kidsAsyncValue.error}',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return const Center(
              child: CircularProgressIndicator(color: ThemeColors.primaryPurple),
            );
          } catch (e, stack) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: SelectableText(
                  'Crash caught in FeesDashboardScreen:\n$e\n\nStack:\n$stack',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
