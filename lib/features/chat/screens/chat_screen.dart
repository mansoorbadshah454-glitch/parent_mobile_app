import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../providers/chat_provider.dart';
import '../../kids/providers/kids_provider.dart';
import '../../kids/screens/kid_details_screen.dart';
import '../../../core/theme/theme_colors.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatAsyncValue = ref.watch(chatProvider);
    final kidsAsyncValue = ref.watch(kidsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: chatAsyncValue.when(
        data: (messages) {
          if (messages.isEmpty) {
            return const Center(child: Text('No messages received.'));
          }

          // 1. Separate Teacher messages vs Admin messages
          final teacherMessages = messages.where((m) => !m.isAdminMessage).toList();
          final adminMessages = messages.where((m) => m.isAdminMessage).toList();

          // 2. Group Teacher messages by studentId
          final Map<String, List<MessageModel>> teacherMsgsByStudent = {};
          for (var msg in teacherMessages) {
            if (msg.studentId.isNotEmpty) {
               teacherMsgsByStudent.putIfAbsent(msg.studentId, () => []).add(msg);
            }
          }

          // 3. Prepare Kids list
          final kids = kidsAsyncValue.value ?? [];

          // 4. Build custom list of widgets
          List<Widget> listItems = [];

          // Teacher notification cards at the top
          if (teacherMsgsByStudent.isNotEmpty) {
            listItems.add(const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text("CLASS TEACHER MESSAGES", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
            ));

            teacherMsgsByStudent.forEach((studentId, msgs) {
              final kid = kids.firstWhere((k) => k.id == studentId, orElse: () => KidData(
                id: studentId, 
                name: msgs.first.studentName, 
                imageUrl: '', 
                className: '', 
                classId: '',
                rollNo: '',
                wellness: {},
                attendanceHistory: {},
              ));
              
              final unreadCount = msgs.where((m) => !m.read).length;
              
              listItems.add(
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    elevation: 1,
                    shadowColor: Colors.black.withOpacity(0.05),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => KidDetailsScreen(kid: kid, initialTabIndex: 3)));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: ThemeColors.primaryPurple.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.chat_bubble_outline, color: ThemeColors.primaryPurple),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msgs.first.teacherName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    unreadCount > 0 
                                      ? 'You have $unreadCount new message${unreadCount > 1 ? 's' : ''} regarding ${kid.name}'
                                      : 'View conversation regarding ${kid.name}',
                                    style: TextStyle(
                                      fontSize: 14, 
                                      color: unreadCount > 0 ? ThemeColors.primaryPurple : Colors.grey[600],
                                      fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal
                                    ),
                                  )
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              );
            });
            listItems.add(const SizedBox(height: 12));
          }

          if (adminMessages.isNotEmpty) {
            listItems.add(const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text("SCHOOL NOTIFICATIONS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
            ));

            listItems.addAll(adminMessages.map((msg) {
               return Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                 child: AdminMessageCard(msg: msg),
               );
            }));
          }

          if (listItems.isEmpty) {
            return const Center(child: Text('No messages to display.'));
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: listItems,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class AdminMessageCard extends StatefulWidget {
  final MessageModel msg;
  const AdminMessageCard({super.key, required this.msg});

  @override
  State<AdminMessageCard> createState() => _AdminMessageCardState();
}

class _AdminMessageCardState extends State<AdminMessageCard> {
  bool isExpanded = false;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.blue.shade50.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blue.shade100, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.campaign, color: Colors.blue, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.msg.teacherName.isEmpty ? 'Administration' : widget.msg.teacherName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueAccent),
                      ),
                      if (widget.msg.timestamp != null)
                        Text(
                          DateFormat.yMMMd().add_jm().format(widget.msg.timestamp!),
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                     widget.msg.senderRole?.toUpperCase() ?? 'ADMIN',
                     style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, size) {
                final span = TextSpan(text: widget.msg.message, style: const TextStyle(fontSize: 15, height: 1.4));
                final tp = TextPainter(text: span, maxLines: 4, textDirection: TextDirection.ltr);
                tp.layout(maxWidth: size.maxWidth);
                
                final bool isLongText = tp.didExceedMaxLines;

                return AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.msg.message,
                        style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.black87),
                        maxLines: isExpanded ? null : 4,
                        overflow: isExpanded ? TextOverflow.visible : TextOverflow.fade,
                      ),
                      if (isLongText)
                         GestureDetector(
                           onTap: () {
                             setState(() {
                               isExpanded = !isExpanded;
                             });
                           },
                           child: Padding(
                             padding: const EdgeInsets.only(top: 8.0),
                             child: Text(
                               isExpanded ? 'Show less' : 'See more',
                               style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 14),
                             ),
                           ),
                         )
                     ],
                  ),
                );
              }
            ),
            if (widget.msg.attachmentUrl != null && widget.msg.attachmentUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: widget.msg.attachmentType == 'image'
                    ? Image.network(widget.msg.attachmentUrl!, fit: BoxFit.cover, height: 180, width: double.infinity)
                    : Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200)
                        ),
                        child: Row(
                          children: [
                            Icon(widget.msg.attachmentType == 'audio' ? Icons.audiotrack : Icons.attach_file, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Attachment: ${widget.msg.attachmentType}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500))),
                          ],
                        ),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
