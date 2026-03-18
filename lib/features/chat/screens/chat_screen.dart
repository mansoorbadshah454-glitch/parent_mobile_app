import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatAsyncValue = ref.watch(chatProvider);

    return Scaffold(
      body: chatAsyncValue.when(
        data: (messages) {
          if (messages.isEmpty) {
            return const Center(child: Text('No messages received.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final msg = messages[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              msg.teacherName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          if (msg.timestamp != null)
                            Text(
                              DateFormat.yMMMd().add_jm().format(msg.timestamp!),
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Regarding: ${msg.studentName}',
                        style: TextStyle(color: Colors.grey[700], fontSize: 13, fontStyle: FontStyle.italic),
                      ),
                      const Divider(),
                      const SizedBox(height: 4),
                      Text(
                        msg.message,
                        style: const TextStyle(fontSize: 15),
                      ),
                      if (msg.attachmentUrl != null && msg.attachmentUrl!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: msg.attachmentType == 'image'
                              ? Image.network(msg.attachmentUrl!, fit: BoxFit.cover, height: 150, width: double.infinity)
                              : Container(
                                  padding: const EdgeInsets.all(12),
                                  color: Colors.grey[200],
                                  child: Row(
                                    children: [
                                      Icon(msg.attachmentType == 'audio' ? Icons.audiotrack : Icons.attach_file),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text('Attachment: ${msg.attachmentType}', overflow: TextOverflow.ellipsis)),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ],
                  ),
                ),
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
