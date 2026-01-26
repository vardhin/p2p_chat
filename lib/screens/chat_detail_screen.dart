import 'package:flutter/material.dart';
import 'package:p2p_chat/utils/identity_manager.dart';
import 'package:p2p_chat/utils/peer_manager.dart';
import 'package:p2p_chat/utils/p2p_messaging_service.dart';
import 'package:p2p_chat/models/message.dart';
import 'package:p2p_chat/screens/p2p_diagnostics_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  final Peer peer;
  final Identity currentIdentity;

  const ChatDetailScreen({
    super.key,
    required this.peer,
    required this.currentIdentity,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messagingService = P2PMessagingService();
  final _messageController = TextEditingController();
  late List<ChatMessage> _messages = [];
  bool _isConnected = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    // Load messages from database
    final messages = await _messagingService.getConversationMessages(widget.peer.id);
    setState(() {
      _messages = messages.reversed.toList();
    });

    // Connect to peer
    final connected = await _messagingService.connectToPeer(
      peerId: widget.peer.id,
      peerIp: widget.peer.ipAddress,
      peerPort: widget.peer.port,
      localIdentityId: widget.currentIdentity.id,
    );

    setState(() {
      _isConnected = connected;
    });

    // Listen for new messages
    _messagingService.onMessageReceived.listen((message) {
      if (mounted && message.conversationId.contains(widget.peer.id)) {
        setState(() {
          _messages.insert(0, message);
        });
      }
    });

    // Listen for connection status changes
    _messagingService.onConnectionStatusChanged.listen((event) {
      if (mounted && event.$1 == widget.peer.id) {
        setState(() {
          _isConnected = event.$2;
        });
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || !_isConnected) return;

    final text = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _isSending = true;
    });

    final success = await _messagingService.sendMessage(
      peerId: widget.peer.id,
      content: text,
      localIdentityId: widget.currentIdentity.id,
    );

    setState(() {
      _isSending = false;
    });

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send message'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.peer.name),
            Text(
              _isConnected ? 'Connected' : 'Disconnected',
              style: TextStyle(
                fontSize: 12,
                color: _isConnected ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        actions: [
          // Diagnostics button
          IconButton(
            icon: const Icon(Icons.settings_remote),
            tooltip: 'Connection Diagnostics',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => P2PConnectionDiagnosticsScreen(
                    peer: widget.peer,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      'No messages yet. Start a conversation!',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isOwn = message.senderId == widget.currentIdentity.id;

                      return Align(
                        alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isOwn
                                ? Colors.deepPurple
                                : Colors.grey[800],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.content,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border(
                top: BorderSide(color: Colors.grey[800]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: _isConnected && !_isSending,
                    decoration: InputDecoration(
                      hintText: _isConnected
                          ? 'Type a message...'
                          : 'Connecting...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isConnected && !_isSending ? _sendMessage : null,
                  icon: _isSending
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send),
                  color: Colors.deepPurple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
