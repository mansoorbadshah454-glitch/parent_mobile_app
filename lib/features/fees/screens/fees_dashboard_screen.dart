import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../kids/providers/kids_provider.dart';
import '../../kids/widgets/shining_profile_avatar.dart';
import 'fee_screen.dart';

class FeesDashboardScreen extends ConsumerWidget {
  const FeesDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kidsAsyncValue = ref.watch(kidsProvider);

    return Scaffold(
      backgroundColor: ThemeColors.backgroundColor,
      body: kidsAsyncValue.when(
        data: (kids) {
          if (kids.isEmpty) {
            return const Center(child: Text('No kids linked to this account.'));
          }
          
          final int totalKids = kids.length;
          final int paidKids = kids.where((k) => k.monthlyFeeStatus.toLowerCase() == 'paid').length; 
          final int unpaidKids = totalKids - paidKids;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
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
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final kid = kids[index];
                    
                    final isPaid = kid.monthlyFeeStatus.toLowerCase() == 'paid';
                    final dueBadgeColor = isPaid ? Colors.green : Colors.redAccent;
                    final dueBadgeText = isPaid ? 'Fee Paid' : 'Unpaid';

                    return Card(
                      color: Colors.white,
                      elevation: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                                      style: GoogleFonts.montserrat(
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
                                      style: GoogleFonts.montserrat(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Class: ${kid.className}',
                                      style: GoogleFonts.montserrat(
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
                                      color: dueBadgeColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: dueBadgeColor.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      dueBadgeText,
                                      style: GoogleFonts.montserrat(
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
                  },
                  childCount: kids.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
