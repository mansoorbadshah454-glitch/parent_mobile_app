import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/alerts_provider.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsyncValue = ref.watch(alertsProvider);

    return Scaffold(
      body: alertsAsyncValue.when(
        data: (alerts) {
          if (alerts.isEmpty) {
            return const Center(child: Text('No new alerts.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: alert.read ? Colors.grey[200] : Colors.redAccent.withOpacity(0.1),
                  child: Icon(
                    alert.type == 'attendance' ? Icons.check_circle_outline : Icons.notifications,
                    color: alert.read ? Colors.grey : Colors.redAccent,
                  ),
                ),
                title: Text(
                  alert.title,
                  style: TextStyle(
                    fontWeight: alert.read ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(alert.message),
                    if (alert.createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        DateFormat.yMMMd().add_jm().format(alert.createdAt!),
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ]
                  ],
                ),
                isThreeLine: true,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
