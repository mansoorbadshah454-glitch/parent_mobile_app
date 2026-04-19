import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../providers/chat_provider.dart';
import '../../kids/providers/kids_provider.dart';
import '../../kids/screens/kid_details_screen.dart';
import '../../../core/theme/theme_colors.dart';import '../../../core/providers/parent_data_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  bool isSelectionMode = false;
  Set<String> selectedMessageIds = {};

  void _toggleSelection(String id) {
    setState(() {
      if (selectedMessageIds.contains(id)) {
        selectedMessageIds.remove(id);
      } else {
        selectedMessageIds.add(id);
      }
      if (selectedMessageIds.isEmpty) {
        isSelectionMode = false;
      }
    });
  }

  void _toggleGroupSelection(List<MessageModel> msgs) {
    setState(() {
      final allIds = msgs.map((m) => m.id).toSet();
      final isAllSelected = selectedMessageIds.containsAll(allIds);
      if (isAllSelected) {
        selectedMessageIds.removeAll(allIds);
      } else {
        selectedMessageIds.addAll(allIds);
      }
      if (selectedMessageIds.isEmpty) {
        isSelectionMode = false;
      }
    });
  }

  Future<void> _deleteSelected() async {
    final parentData = ref.read(parentDataProvider).value;
    if (parentData == null) return;
    
    await ChatService.deleteMessages(parentData.schoolId, selectedMessageIds.toList());
    
    setState(() {
      selectedMessageIds.clear();
      isSelectionMode = false;
    });
  }

  Future<void> _clearAllChats() async {
    final parentData = ref.read(parentDataProvider).value;
    if (parentData == null) return;
    
    await ChatService.clearAllChats(parentData.schoolId, parentData.uid);
    
    setState(() {
      selectedMessageIds.clear();
      isSelectionMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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

          // Top Header & Selection Bar
          if (isSelectionMode) {
            listItems.add(Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: ThemeColors.primaryPurple.withOpacity(0.1),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: ThemeColors.primaryPurple),
                    onPressed: () {
                      setState(() {
                        isSelectionMode = false;
                        selectedMessageIds.clear();
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  Text('${selectedMessageIds.length} Selected',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: ThemeColors.primaryPurple),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: _deleteSelected,
                  ),
                ],
              ),
            ));
          }

          final topPopupMenu = PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onSelected: (value) {
              if (value == 'select') {
                setState(() {
                  isSelectionMode = true;
                });
              } else if (value == 'clear') {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear Chat'),
                    content: const Text('Are you sure you want to clear all chat history? This action cannot be undone.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _clearAllChats();
                        }, 
                        child: const Text('Clear', style: TextStyle(color: Colors.red))
                      ),
                    ],
                  )
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'select', child: Text('Select to Delete')),
              const PopupMenuItem(value: 'clear', child: Text('Clear All Chats')),
            ],
          );

          // Teacher notification cards at the top
          if (teacherMsgsByStudent.isNotEmpty) {
            listItems.add(Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("CLASS TEACHER MESSAGES", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                  if (!isSelectionMode) topPopupMenu,
                ],
              ),
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
              final allIds = msgs.map((m) => m.id).toSet();
              final isSelected = selectedMessageIds.containsAll(allIds) && allIds.isNotEmpty;
              
              listItems.add(
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Material(
                    color: isSelected ? ThemeColors.primaryPurple.withOpacity(0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    elevation: 1,
                    shadowColor: Colors.black.withOpacity(0.05),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onLongPress: () {
                        setState(() {
                          isSelectionMode = true;
                          _toggleGroupSelection(msgs);
                        });
                      },
                      onTap: () {
                         if (isSelectionMode) {
                           _toggleGroupSelection(msgs);
                         } else {
                           Navigator.push(context, MaterialPageRoute(builder: (_) => KidDetailsScreen(kid: kid, initialTabIndex: 3)));
                         }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSelected ? ThemeColors.primaryPurple : Colors.grey.shade100),
                        ),
                        child: Row(
                          children: [
                            if (isSelectionMode) ...[
                              Icon(
                                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                color: isSelected ? ThemeColors.primaryPurple : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                            ],
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: unreadCount > 0 ? ThemeColors.primaryPurple.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.chat_bubble_outline, color: unreadCount > 0 ? ThemeColors.primaryPurple : Colors.grey),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msgs.first.senderRole != null && msgs.first.senderRole!.trim().isNotEmpty
                                        ? '${msgs.first.teacherName} (${msgs.first.senderRole})'
                                        : msgs.first.teacherName,
                                    style: TextStyle(
                                      fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w500, 
                                      fontSize: 16,
                                      color: unreadCount > 0 ? Colors.black87 : Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    unreadCount > 0 
                                      ? 'You have $unreadCount new message${unreadCount > 1 ? 's' : ''} regarding ${kid.name}'
                                      : 'View conversation regarding ${kid.name}',
                                    style: TextStyle(
                                      fontSize: 14, 
                                      color: unreadCount > 0 ? ThemeColors.primaryPurple : Colors.grey[500],
                                      fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal
                                    ),
                                  )
                                ],
                              ),
                            ),
                            if (!isSelectionMode)
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
            listItems.add(Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("SCHOOL NOTIFICATIONS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                  if (!isSelectionMode && teacherMsgsByStudent.isEmpty) topPopupMenu,
                ],
              ),
            ));

            listItems.addAll(adminMessages.map((msg) {
               final isSelected = selectedMessageIds.contains(msg.id);
               return Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                 child: GestureDetector(
                   onLongPress: () {
                     setState(() {
                       isSelectionMode = true;
                       _toggleSelection(msg.id);
                     });
                   },
                   onTap: isSelectionMode ? () => _toggleSelection(msg.id) : null,
                   child: Stack(
                     children: [
                       AdminMessageCard(msg: msg),
                       if (isSelectionMode)
                         Positioned(
                           top: 16,
                           right: 16,
                           child: Icon(
                             isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                             color: isSelected ? ThemeColors.primaryPurple : Colors.grey,
                           ),
                         ),
                       if (isSelected)
                         Positioned.fill(
                           child: Container(
                             decoration: BoxDecoration(
                               color: ThemeColors.primaryPurple.withOpacity(0.1),
                               borderRadius: BorderRadius.circular(16),
                               border: Border.all(color: ThemeColors.primaryPurple, width: 2),
                             ),
                           ),
                         ),
                     ],
                   ),
                 ),
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
