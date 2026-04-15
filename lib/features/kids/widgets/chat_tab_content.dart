import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../providers/kids_provider.dart';
import '../../../core/theme/theme_colors.dart';

enum MessageType { text, image, voice }

class MockMessage {
  final String id;
  final MessageType type;
  final String content;
  final DateTime timestamp;
  final String duration; // For voice

  MockMessage({
    required this.id,
    required this.type,
    required this.content,
    required this.timestamp,
    this.duration = "",
  });
}

class ChatTabContent extends StatefulWidget {
  final KidData kid;
  
  const ChatTabContent({Key? key, required this.kid}) : super(key: key);

  @override
  State<ChatTabContent> createState() => _ChatTabContentState();
}

class _ChatTabContentState extends State<ChatTabContent> {
  bool _isSelectionMode = false;
  final Set<String> _selectedMessageIds = {};
  
  List<MockMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadMockMessages();
  }

  void _loadMockMessages() {
    _messages = [
      MockMessage(
        id: '1',
        type: MessageType.text,
        content: "Dear Parents, welcome to our direct class channel. You'll receive important updates here.",
        timestamp: DateTime.now().subtract(const Duration(days: 3, hours: 4)),
      ),
      MockMessage(
        id: '2',
        type: MessageType.voice,
        content: "Voice note", 
        duration: "0:45",
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      ),
      MockMessage(
        id: '3',
        type: MessageType.image,
        content: "mock", 
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      MockMessage(
        id: '4',
        type: MessageType.text,
        content: "Just a friendly reminder about the science project deadline coming up this Friday!",
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
    ];
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedMessageIds.clear();
      }
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedMessageIds.contains(id)) {
        _selectedMessageIds.remove(id);
      } else {
        _selectedMessageIds.add(id);
      }
    });
  }

  void _deleteSelected() {
    setState(() {
      _messages.removeWhere((msg) => _selectedMessageIds.contains(msg.id));
      _isSelectionMode = false;
      _selectedMessageIds.clear();
    });
  }

  void _clearHistory() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Clear History"),
        content: const Text("Are you sure you want to clear all messages on this device?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _messages.clear();
              });
              Navigator.pop(ctx);
            },
            child: const Text("Clear All", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top Action Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: ThemeColors.primaryPurple.withOpacity(0.1),
                child: const Icon(Icons.person, color: ThemeColors.primaryPurple),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Class Teacher (${widget.kid.className})",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ThemeColors.primaryText,
                      ),
                    ),
                    const Text(
                      "Official Channel",
                      style: TextStyle(
                        fontSize: 12,
                        color: ThemeColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isSelectionMode)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: _selectedMessageIds.isEmpty ? null : _deleteSelected,
                )
              else
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: ThemeColors.secondaryText),
                  onSelected: (value) {
                    if (value == 'select') {
                      _toggleSelectionMode();
                    } else if (value == 'clear') {
                      _clearHistory();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'select',
                      child: Row(
                        children: [
                          Icon(Icons.check_box_outlined, size: 20, color: ThemeColors.secondaryText),
                          SizedBox(width: 8),
                          Text("Select to Delete"),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'clear',
                      child: Row(
                        children: [
                          Icon(Icons.delete_sweep_outlined, size: 20, color: ThemeColors.secondaryText),
                          SizedBox(width: 8),
                          Text("Clear History"),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),


        // Chat View
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/school_pattern.png'),
                fit: BoxFit.cover,
                opacity: 0.05, // WhatsApp style subtle background
              ),
              color: Color(0xFFF7F7F9),
            ),
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      "No messages found.",
                      style: TextStyle(color: ThemeColors.secondaryText),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return _buildInfoBadge();
                      }
                      final msg = _messages[index];
                      return _buildMessageRow(msg);
                    },
                  ),
          ),
        ),
        
        // Cancel Action (if in selection mode)
        if (_isSelectionMode)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: ThemeColors.primaryText,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _toggleSelectionMode,
                  child: const Text("Cancel Selection"),
                ),
              ),
            ),
          )
      ],
    );
  }

  Widget _buildInfoBadge() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 24),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: Colors.amber.shade800),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Welcome to Class Interactions! 🎓 This is a read-only channel where you will securely receive important announcements, media, and voice notes directly from your child's class teacher.",
              style: TextStyle(
                fontSize: 13,
                color: Colors.amber.shade900,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageRow(MockMessage msg) {
    bool isSelected = _selectedMessageIds.contains(msg.id);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Select Checkbox
          if (_isSelectionMode)
            GestureDetector(
              onTap: () => _toggleSelection(msg.id),
              child: Container(
                margin: const EdgeInsets.only(right: 12, bottom: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? ThemeColors.primaryPurple : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? ThemeColors.primaryPurple : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.check,
                    size: 16,
                    color: isSelected ? Colors.white : Colors.transparent,
                  ),
                ),
              ),
            ),
            
          // Bubble
          Expanded(
            child: GestureDetector(
              onTap: _isSelectionMode ? () => _toggleSelection(msg.id) : null,
              onLongPress: () {
                if (!_isSelectionMode) {
                  _toggleSelectionMode();
                  _toggleSelection(msg.id);
                }
              },
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                      bottomLeft: Radius.circular(4), // Teacher sending point
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                      bottomLeft: Radius.circular(4),
                    ),
                    child: _buildBubbleContent(msg),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubbleContent(MockMessage msg) {
    if (msg.type == MessageType.text) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              msg.content,
              style: const TextStyle(
                fontSize: 15,
                color: ThemeColors.primaryText,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            _buildTimestampOffset(msg.timestamp),
          ],
        ),
      );
    } 
    else if (msg.type == MessageType.image) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mock Image Area
          Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey.shade300,
            child: Stack(
              children: [
                const Center(
                  child: Icon(Icons.image_outlined, size: 48, color: Colors.grey),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.download_rounded, color: Colors.white, size: 20),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Downloading to device...')),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
            child: _buildTimestampOffset(msg.timestamp),
          )
        ],
      );
    } 
    else if (msg.type == MessageType.voice) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: ThemeColors.primaryPurple,
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                // Mock WA Waveform Using lines
                Expanded(
                  child: Row(
                    children: List.generate(20, (index) {
                      final height = (index % 3 == 0) ? 18.0 : ((index % 2 == 0) ? 8.0 : 12.0);
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        width: 3,
                        height: height,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  msg.duration,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildTimestampOffset(msg.timestamp),
              ],
            )
          ],
        ),
      );
    }
    return const SizedBox();
  }

  Widget _buildTimestampOffset(DateTime t) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          DateFormat('hh:mm a').format(t),
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}
