import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/kids_provider.dart';
import '../widgets/shining_profile_avatar.dart';
import 'kid_details_screen.dart';

class KidsScreen extends ConsumerWidget {
  const KidsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kidsAsyncValue = ref.watch(kidsProvider);

    return Scaffold(
      body: Builder(
        builder: (context) {
          if (kidsAsyncValue.hasValue) {
            final kids = kidsAsyncValue.value!;
            if (kids.isEmpty) {
              return const Center(child: Text('No kids linked to this account.'));
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
              itemCount: kids.length,
              itemBuilder: (context, index) {
                final kid = kids[index];
                final now = DateTime.now();
                final todayStr =
                    '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                final todayGate = kid.gateLogs[todayStr];
                final String? inTime = (kid.gateInDate == todayStr &&
                        (kid.gateInTime?.isNotEmpty ?? false))
                    ? kid.gateInTime
                    : todayGate?['inTime'];
                final String? outTime = (kid.gateOutDate == todayStr &&
                        (kid.gateOutTime?.isNotEmpty ?? false))
                    ? kid.gateOutTime
                    : todayGate?['outTime'];

                return Card(
                  color: Colors.white,
                  elevation: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => KidDetailsScreen(kid: kid),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                      child: Row(
                        children: [
                          ShiningProfileAvatar(
                            imageUrl: kid.imageUrl,
                            radius: 28, // Scaled for standard vertical list
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
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Class: ${kid.className}  |  Roll: ${kid.rollNo}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    // In School Time Badge (always visible on Kid Card)
                                    Builder(builder: (_) {
                                      final hasIn = inTime != null && inTime.isNotEmpty;
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: hasIn
                                              ? const Color(0xFFECFDF5)
                                              : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: hasIn
                                                ? const Color(0xFFA7F3D0)
                                                : const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.login_rounded,
                                              size: 13,
                                              color: hasIn
                                                  ? const Color(0xFF047857)
                                                  : const Color(0xFF64748B),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              hasIn ? 'In School: $inTime' : 'In School: --:--',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: hasIn
                                                    ? const Color(0xFF047857)
                                                    : const Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                    // Out From School Time Badge (always visible on Kid Card)
                                    Builder(builder: (_) {
                                      final hasOut = outTime != null && outTime.isNotEmpty;
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: hasOut
                                              ? const Color(0xFFFFF7ED)
                                              : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: hasOut
                                                ? const Color(0xFFFED7AA)
                                                : const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.logout_rounded,
                                              size: 13,
                                              color: hasOut
                                                  ? const Color(0xFFC2410C)
                                                  : const Color(0xFF64748B),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              hasOut ? 'Out: $outTime' : 'Out: --:--',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: hasOut
                                                    ? const Color(0xFFC2410C)
                                                    : const Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
          if (kidsAsyncValue.hasError) {
            return Center(child: Text('Error: ${kidsAsyncValue.error}'));
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
