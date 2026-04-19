import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/providers/parent_data_provider.dart';

class BankDetailsScreen extends ConsumerWidget {
  const BankDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentDataAsync = ref.watch(parentDataProvider);

    return Scaffold(
      backgroundColor: ThemeColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: ThemeColors.primaryPurple,
        title: const Text("School's Bank Accounts", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: parentDataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => const Center(child: Text('Error loading parent data.')),
        data: (parentData) {
          if (parentData == null || parentData.schoolId.isEmpty) {
            return const Center(child: Text('School info not found.'));
          }
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('schools').doc(parentData.schoolId).collection('settings').doc('banking').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Error loading banking details.'));
              }

              final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
              final accounts = data['accounts'] as List<dynamic>? ?? [];

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Info Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Note: These are the official School's bank account details for fee submissions.",
                                style: TextStyle(
                                  color: Colors.blue.shade900,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      if (accounts.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              "No bank accounts found.",
                              style: TextStyle(color: ThemeColors.secondaryText),
                            ),
                          ),
                        ),

                      ...accounts.map((acc) {
                        final map = acc as Map<String, dynamic>? ?? {};
                        final bankName = map['bankName'] as String? ?? 'Unknown Bank';
                        final accountTitle = map['accountTitle'] as String? ?? 'Unknown Title';
                        final accountNumber = map['accountNumber'] as String? ?? 'Unknown Number';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _buildBankCard(bankName, accountNumber, accountTitle),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              );
            }
          );
        }
      ),
    );
  }

  Widget _buildBankCard(String bankName, String accountNumber, String accountTitle) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ThemeColors.lightPurple.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.account_balance, size: 32, color: ThemeColors.primaryPurple),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    bankName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ThemeColors.primaryText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDetailRow("Account Title", accountTitle),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(),
            ),
            _buildDetailRow("Account Number", accountNumber),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: ThemeColors.secondaryText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ThemeColors.primaryText,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}
