import 'package:flutter/material.dart';
import 'package:p2p_chat/utils/p2p_messaging_service.dart';
import 'package:p2p_chat/utils/peer_manager.dart';

class P2PConnectionDiagnosticsScreen extends StatefulWidget {
  final Peer peer;

  const P2PConnectionDiagnosticsScreen({
    super.key,
    required this.peer,
  });

  @override
  State<P2PConnectionDiagnosticsScreen> createState() =>
      _P2PConnectionDiagnosticsScreenState();
}

class _P2PConnectionDiagnosticsScreenState
    extends State<P2PConnectionDiagnosticsScreen> {
  final _messagingService = P2PMessagingService();
  late ScrollController _logScrollController;

  @override
  void initState() {
    super.initState();
    _logScrollController = ScrollController();
  }

  @override
  void dispose() {
    _logScrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_logScrollController.hasClients) {
      _logScrollController.jumpTo(
        _logScrollController.position.maxScrollExtent,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final logs = _messagingService.getConnectionLogs(widget.peer.id) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('P2P Connection Diagnostics'),
        backgroundColor: Colors.deepPurple,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Peer Information Card
            Card(
              elevation: 4,
              color: Colors.grey[900],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Peer Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Peer ID', widget.peer.id),
                    _buildInfoRow('Peer Name', widget.peer.name),
                    _buildInfoRow('IP Address', widget.peer.ipAddress),
                    _buildInfoRow('Port', widget.peer.port.toString()),
                    _buildInfoRow(
                      'Connection Type',
                      widget.peer.useLocalIP ? 'Local LAN' : 'Remote',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Connection Status Card
            Card(
              elevation: 4,
              color: Colors.grey[900],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connection Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<(String, bool)>(
                      stream: _messagingService.onConnectionStatusChanged,
                      builder: (context, snapshot) {
                        final isConnected = snapshot.data?.$2 ?? false;
                        final statusColor =
                            isConnected ? Colors.green : Colors.red;
                        final statusText =
                            isConnected ? 'Connected' : 'Disconnected';

                        return Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Connection test initiated'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Test Connection'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Connection Logs Card
            Card(
              elevation: 4,
              color: Colors.grey[900],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Connection Logs',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Logs would be cleared'),
                              ),
                            );
                          },
                          tooltip: 'Clear logs',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.deepPurple, width: 0.5),
                      ),
                      child: ListView(
                        controller: _logScrollController,
                        padding: const EdgeInsets.all(12),
                        children: [
                          if (logs.isEmpty)
                            const Text(
                              'No logs yet. Initiate a connection to see logs.',
                              style: TextStyle(color: Colors.white54),
                            )
                          else
                            ...logs.map((log) => Text(
                              log,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: Colors.greenAccent,
                              ),
                            )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total Logs: ${logs.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Diagnostics Information
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What is P2P Diagnostics?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This screen shows real-time diagnostics for peer-to-peer connections. '
                    'It includes:\n'
                    '• Peer information (IP, port, connection type)\n'
                    '• Live connection status indicator\n'
                    '• Detailed connection logs with timestamps\n'
                    '• UDP hole punching progress\n'
                    '• IPv4/IPv6 detection and handling\n\n'
                    'Use this to troubleshoot connection issues.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
