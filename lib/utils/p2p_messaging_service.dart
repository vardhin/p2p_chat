import 'dart:io';
import 'dart:async';
import 'package:p2p_chat/models/message.dart';
import 'package:p2p_chat/utils/message_database.dart';

class P2PMessagingService {
  static final P2PMessagingService _instance = P2PMessagingService._internal();
  factory P2PMessagingService() => _instance;
  P2PMessagingService._internal();

  final _messageDb = MessageDatabase();
  final _activeConnections = <String, _UDPConnection>{};
  final _messageQueue = <String, List<ChatMessage>>{};
  final _onMessageReceived = StreamController<ChatMessage>.broadcast();
  final _onConnectionStatusChanged = StreamController<(String, bool)>.broadcast();
  final _connectionLogs = <String, List<String>>{};

  /// Stream for incoming messages
  Stream<ChatMessage> get onMessageReceived => _onMessageReceived.stream;

  /// Stream for connection status changes
  Stream<(String, bool)> get onConnectionStatusChanged => _onConnectionStatusChanged.stream;

  /// Get conversation ID from peer ID
  String _getConversationId(String peerId) => 'conv_$peerId';

  /// Log connection events for diagnostics
  void _logConnectionEvent(String peerId, String message) {
    if (!_connectionLogs.containsKey(peerId)) {
      _connectionLogs[peerId] = [];
    }
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] $message';
    _connectionLogs[peerId]!.add(logMessage);
    print('[P2P-$peerId] $message');
  }

  /// Get connection logs for diagnostics
  List<String>? getConnectionLogs(String peerId) => _connectionLogs[peerId];

  /// Connect to a peer with UDP hole punching (supports IPv4 and IPv6)
  Future<bool> connectToPeer({
    required String peerId,
    required String peerIp,
    required int peerPort,
    required String localIdentityId,
  }) async {
    try {
      _logConnectionEvent(peerId, 'Starting connection to $peerIp:$peerPort');
      
      // Create conversation ID
      final conversationId = _getConversationId(peerId);

      // Check if already connected
      if (_activeConnections.containsKey(peerId)) {
        final existing = _activeConnections[peerId]!;
        if (existing.isConnected) {
          _logConnectionEvent(peerId, 'Already connected, reusing socket');
          return true;
        }
      }

      // Determine if it's IPv4 or IPv6
      bool isIPv6 = false;
      try {
        InternetAddress(peerIp);
        final addr = InternetAddress(peerIp);
        isIPv6 = addr.type == InternetAddressType.IPv6;
        _logConnectionEvent(peerId, isIPv6 ? 'Peer IP detected as IPv6' : 'Peer IP detected as IPv4');
      } catch (e) {
        _logConnectionEvent(peerId, 'Error detecting IP type: $e');
      }

      // Create UDP connection with appropriate address family
      final socket = await RawDatagramSocket.bind(
        isIPv6 ? InternetAddress.anyIPv6 : InternetAddress.anyIPv4,
        0, // Use any available port
      );

      _logConnectionEvent(peerId, 'Socket created on local address ${socket.address.address}');

      // Create connection object
      final connection = _UDPConnection(
        peerId: peerId,
        remoteAddress: peerIp,
        remotePort: peerPort,
        socket: socket,
        conversationId: conversationId,
        isIPv6: isIPv6,
      );

      _activeConnections[peerId] = connection;

      // Start hole punching
      await _performHolePunching(connection, localIdentityId);

      // Start listening for messages
      _listenForMessages(connection);

      _logConnectionEvent(peerId, 'Connection established successfully');
      _onConnectionStatusChanged.add((peerId, true));
      return true;
    } catch (e) {
      _logConnectionEvent(peerId, 'Connection failed: $e');
      _onConnectionStatusChanged.add((peerId, false));
      return false;
    }
  }

  /// Perform UDP hole punching with detailed logging
  Future<void> _performHolePunching(_UDPConnection connection, String identityId) async {
    const maxAttempts = 5;
    const delayMs = 100;

    _logConnectionEvent(connection.peerId, 'Starting UDP hole punching...');
    _logConnectionEvent(connection.peerId, 
      'Target: ${connection.remoteAddress}:${connection.remotePort} (${connection.isIPv6 ? "IPv6" : "IPv4"})');

    for (int i = 0; i < maxAttempts; i++) {
      try {
        // Send handshake packets with identity information
        final handshakeData = 'HANDSHAKE:$identityId:attempt${i + 1}'.codeUnits;
        connection.socket.send(
          handshakeData,
          InternetAddress(connection.remoteAddress),
          connection.remotePort,
        );

        _logConnectionEvent(connection.peerId, 'Hole punch attempt ${i + 1}/$maxAttempts sent');

        await Future.delayed(Duration(milliseconds: delayMs));
      } catch (e) {
        _logConnectionEvent(connection.peerId, 'Hole punch attempt ${i + 1} failed: $e');
      }
    }

    // Connection is considered established after hole punching
    connection.isConnected = true;
    _logConnectionEvent(connection.peerId, 'Hole punching phase completed');
  }

  /// Listen for incoming messages from a peer
  void _listenForMessages(_UDPConnection connection) {
    connection.socket.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        try {
          final datagram = connection.socket.receive();
          if (datagram != null) {
            final message = String.fromCharCodes(datagram.data);
            _handleIncomingMessage(connection.peerId, message);
          }
        } catch (e) {
          print('Error receiving message: $e');
        }
      }
    });
  }

  /// Handle incoming message
  void _handleIncomingMessage(String peerId, String message) {
    try {
      final parts = message.split(':');
      if (parts.length < 2) return;

      final messageType = parts[0];
      final content = parts.sublist(1).join(':');

      switch (messageType) {
        case 'HANDSHAKE':
          // Respond to handshake
          break;
        case 'TEXT':
          _processTextMessage(peerId, content);
          break;
        case 'PING':
          // Send pong
          sendPing(peerId);
          break;
      }
    } catch (e) {
      print('Error handling incoming message: $e');
    }
  }

  /// Process incoming text message
  void _processTextMessage(String peerId, String content) {
    final conversationId = _getConversationId(peerId);
    final now = DateTime.now();
    
    final message = ChatMessage(
      id: '${peerId}_${now.millisecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: peerId,
      senderName: peerId,
      content: content,
      timestamp: now,
      isRead: false,
      status: MessageStatus.delivered,
    );

    // Save to database
    _messageDb.insertMessage(message);

    // Emit event
    _onMessageReceived.add(message);
  }

  /// Send a text message to a peer
  Future<bool> sendMessage({
    required String peerId,
    required String content,
    required String localIdentityId,
  }) async {
    try {
      final connection = _activeConnections[peerId];
      if (connection == null || !connection.isConnected) {
        throw Exception('Not connected to peer');
      }

      // Create and store message
      final now = DateTime.now();
      final message = ChatMessage(
        id: '${localIdentityId}_${now.millisecondsSinceEpoch}',
        conversationId: _getConversationId(peerId),
        senderId: localIdentityId,
        senderName: localIdentityId,
        content: content,
        timestamp: now,
        status: MessageStatus.pending,
      );

      // Save to database
      await _messageDb.insertMessage(message);

      // Send over UDP
      final messageData = 'TEXT:$content'.codeUnits;
      connection.socket.send(
        messageData,
        InternetAddress(connection.remoteAddress),
        connection.remotePort,
      );

      // Update status
      await _messageDb.updateMessageStatus(message.id, MessageStatus.sent);

      return true;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  /// Send a ping to keep connection alive
  Future<void> sendPing(String peerId) async {
    try {
      final connection = _activeConnections[peerId];
      if (connection == null || !connection.isConnected) return;

      final pingData = 'PING'.codeUnits;
      connection.socket.send(
        pingData,
        InternetAddress(connection.remoteAddress),
        connection.remotePort,
      );
    } catch (e) {
      print('Error sending ping: $e');
    }
  }

  /// Get conversation messages
  Future<List<ChatMessage>> getConversationMessages(String peerId) async {
    final conversationId = _getConversationId(peerId);
    return await _messageDb.getConversationMessages(conversationId);
  }

  /// Get paginated messages
  Future<List<ChatMessage>> getConversationMessagesPaginated(
    String peerId,
    int limit,
    int offset,
  ) async {
    final conversationId = _getConversationId(peerId);
    return await _messageDb.getConversationMessagesPaginated(conversationId, limit, offset);
  }

  /// Mark message as read
  Future<void> markAsRead(String messageId) async {
    await _messageDb.markAsRead(messageId);
  }

  /// Get unread count
  Future<int> getUnreadCount(String peerId) async {
    final conversationId = _getConversationId(peerId);
    return await _messageDb.getUnreadCount(conversationId);
  }

  /// Disconnect from a peer
  Future<void> disconnectFromPeer(String peerId) async {
    try {
      final connection = _activeConnections.remove(peerId);
      if (connection != null) {
        // Send close message
        final closeData = 'CLOSE'.codeUnits;
        connection.socket.send(
          closeData,
          InternetAddress(connection.remoteAddress),
          connection.remotePort,
        );

        // Close socket
        connection.socket.close();
        connection.isConnected = false;
      }

      _onConnectionStatusChanged.add((peerId, false));
    } catch (e) {
      print('Error disconnecting from peer: $e');
    }
  }

  /// Check if connected to peer
  bool isConnectedToPeer(String peerId) {
    final connection = _activeConnections[peerId];
    return connection != null && connection.isConnected;
  }

  /// Cleanup and close all connections
  Future<void> dispose() async {
    for (var entry in _activeConnections.entries) {
      await disconnectFromPeer(entry.key);
    }
    await _onMessageReceived.close();
    await _onConnectionStatusChanged.close();
  }
}

/// Internal UDP connection representation
class _UDPConnection {
  final String peerId;
  final String remoteAddress;
  final int remotePort;
  final RawDatagramSocket socket;
  final String conversationId;
  final bool isIPv6;
  bool isConnected = false;
  DateTime? connectedAt;

  _UDPConnection({
    required this.peerId,
    required this.remoteAddress,
    required this.remotePort,
    required this.socket,
    required this.conversationId,
    this.isIPv6 = false,
  });

  /// Get connection duration
  Duration? getConnectionDuration() {
    if (connectedAt == null) return null;
    return DateTime.now().difference(connectedAt!);
  }

  /// Get connection info
  String getConnectionInfo() {
    final ipType = isIPv6 ? 'IPv6' : 'IPv4';
    final localAddr = socket.address.address;
    final duration = getConnectionDuration();
    final durationStr = duration != null 
      ? '${duration.inSeconds}s'
      : 'N/A';
    
    return 'P2P Connection: $remoteAddress:$remotePort ($ipType) | Local Address: $localAddr | Duration: $durationStr';
  }
}
