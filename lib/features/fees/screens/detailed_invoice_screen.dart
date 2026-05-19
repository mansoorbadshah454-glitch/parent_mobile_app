import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../kids/providers/kids_provider.dart';
import '../../../core/providers/parent_data_provider.dart';
import '../widgets/downloadable_invoice.dart';
import '../widgets/yearly_fee_calendar.dart';

class DetailedInvoiceScreen extends ConsumerWidget {
  final KidData kid;
  final MonthFee month;

  const DetailedInvoiceScreen({super.key, required this.kid, required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentDataAsync = ref.watch(parentDataProvider);
    final String schoolName = parentDataAsync.value?.schoolName ?? 'School';

    return Scaffold(
      backgroundColor: ThemeColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: ThemeColors.primaryPurple,
        elevation: 0,
        title: Text('${month.monthName} Invoice', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DownloadableInvoice(
              kid: kid,
              schoolName: schoolName,
              monthName: month.monthName,
            ),
          ],
        ),
      ),
    );
  }
}
