import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/socket_service.dart';

class RoomChatOverlay extends StatefulWidget {
  final Widget child;

  const RoomChatOverlay({super.key, required this.child});

  @override
  State<RoomChatOverlay> createState() => _RoomChatOverlayState();
}

class _RoomChatOverlayState extends State<RoomChatOverlay> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isOpen = false;

  void _toggleChat(SocketService socket) {
    setState(() {
      _isOpen = !_isOpen;
    });
    socket.setChatOpen(_isOpen);
    if (_isOpen) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(SocketService socket) {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    socket.sendChatMessage(text);
    _msgController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final socket = context.watch<SocketService>();
    final messages = socket.chatMessages;
    final unread = socket.unreadChatCount;

    return Stack(
      children: [
        // Main Screen Body
        widget.child,

        // Pinned Right-Side Floating Chat Icon (Picture 3 style)
        Positioned(
          right: 0,
          top: MediaQuery.of(context).size.height * 0.28,
          child: GestureDetector(
            onTap: () => _toggleChat(socket),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32), // Casino Emerald Green
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(-2, 2),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.chat_bubble, color: Colors.white, size: 20),
                  if (unread > 0)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$unread',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Slide-out Chat Panel on the Right
        if (_isOpen)
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            width: 320,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1B0727).withOpacity(0.96),
                border: const Border(
                  left: BorderSide(color: Color(0xFFD4AF37), width: 1.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 18,
                  )
                ],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      color: const Color(0xFF2F0F44),
                      child: Row(
                        children: [
                          const Icon(Icons.forum, color: Color(0xFFD4AF37), size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'Room Chat',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _toggleChat(socket),
                          ),
                        ],
                      ),
                    ),

                    // Chat Messages List
                    Expanded(
                      child: messages.isEmpty
                          ? const Center(
                              child: Text(
                                'No messages yet.\nSay hello to your opponents!',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white30, fontSize: 12),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              itemCount: messages.length,
                              itemBuilder: (context, idx) {
                                final msg = messages[idx];
                                final bool isMe = msg['sender_id'] == socket.myPlayerId;

                                return Align(
                                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    constraints: const BoxConstraints(maxWidth: 240),
                                    decoration: BoxDecoration(
                                      color: isMe ? const Color(0xFF4A148C) : const Color(0xFF281335),
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(10),
                                        topRight: const Radius.circular(10),
                                        bottomLeft: Radius.circular(isMe ? 10 : 2),
                                        bottomRight: Radius.circular(isMe ? 2 : 10),
                                      ),
                                      border: Border.all(
                                        color: isMe ? const Color(0xFFD4AF37).withOpacity(0.5) : Colors.white12,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (!isMe)
                                          Text(
                                            msg['sender_name'] ?? 'Player',
                                            style: const TextStyle(
                                              color: Color(0xFFD4AF37),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10,
                                            ),
                                          ),
                                        Text(
                                          msg['text'] ?? '',
                                          style: const TextStyle(color: Colors.white, fontSize: 13),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          msg['timestamp'] ?? '',
                                          style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 9),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),

                    // Input Field & Send Button
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      color: Colors.black26,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _msgController,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                filled: true,
                                fillColor: const Color(0xFF281138),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onSubmitted: (_) => _sendMessage(socket),
                            ),
                          ),
                          const SizedBox(width: 6),
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFFD4AF37),
                            child: IconButton(
                              icon: const Icon(Icons.send, color: Colors.black, size: 16),
                              onPressed: () => _sendMessage(socket),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}