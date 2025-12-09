import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:p2p_chat/src/rust/api/network.dart';

class NetworkInfoScreen extends StatefulWidget {
  const NetworkInfoScreen({super.key});

  @override
  State<NetworkInfoScreen> createState() => _NetworkInfoScreenState();
}

class _NetworkInfoScreenState extends State<NetworkInfoScreen> {
  NetworkInfo? _networkInfo;
  bool _isLoading = false;
  final TextEditingController _peerIpController = TextEditingController();
  bool? _isSameSubnet;

  @override
  void initState() {
    super.initState();
    _loadNetworkInfo();
  }

  @override
  void dispose() {
    _peerIpController.dispose();
    super.dispose();
  }

  Future<void> _loadNetworkInfo() async {
    setState(() => _isLoading = true);
    try {
      final info = getNetworkInfo();
      setState(() {
        _networkInfo = info;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading network info: $e')),
        );
      }
    }
  }

  void _checkPeerSubnet() {
    if (_networkInfo?.localIpv4 != null && 
        _networkInfo?.subnetMask != null &&
        _peerIpController.text.isNotEmpty) {
      try {
        final result = areOnSameSubnet(
          ip1: _networkInfo!.localIpv4!,
          ip2: _peerIpController.text,
          subnetMask: _networkInfo!.subnetMask!,
        );
        setState(() => _isSameSubnet = result);
      } catch (e) {
        setState(() => _isSameSubnet = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid IP address format')),
        );
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildIPCard({
    required String title,
    required String? ipAddress,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Card(
      elevation: 4,
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      ipAddress ?? 'Not available',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'monospace',
                        color: ipAddress != null ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                  if (ipAddress != null)
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      color: color,
                      onPressed: () => _copyToClipboard(ipAddress, title),
                      tooltip: 'Copy',
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Not available',
              style: TextStyle(
                color: value != null ? Colors.white : Colors.grey,
                fontSize: 14,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Information'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNetworkInfo,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.network_check,
                    size: 80,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Your Network Addresses',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  
                  // Public IPs Section
                  const Text(
                    'Public Addresses',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildIPCard(
                    title: 'Public IPv4',
                    subtitle: 'Internet-visible address',
                    ipAddress: _networkInfo?.publicIpv4,
                    icon: Icons.public,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  _buildIPCard(
                    title: 'Public IPv6',
                    subtitle: 'Internet-visible address',
                    ipAddress: _networkInfo?.publicIpv6,
                    icon: Icons.public,
                    color: Colors.deepOrange,
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Local IPs Section
                  const Text(
                    'Local Addresses',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildIPCard(
                    title: 'Local IPv4',
                    subtitle: 'Same network only',
                    ipAddress: _networkInfo?.localIpv4,
                    icon: Icons.router,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildIPCard(
                    title: 'Local IPv6',
                    subtitle: 'Same network only',
                    ipAddress: _networkInfo?.localIpv6,
                    icon: Icons.router,
                    color: Colors.lightBlue,
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // LAN Details Section
                  const Text(
                    'LAN Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 4,
                    color: Colors.grey[900],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildInfoRow('Interface', _networkInfo?.interfaceName),
                          _buildInfoRow('Subnet Mask', _networkInfo?.subnetMask),
                          _buildInfoRow('Network Prefix', _networkInfo?.networkPrefix),
                          _buildInfoRow('Broadcast', _networkInfo?.broadcastAddress),
                          _buildInfoRow('Gateway', _networkInfo?.gateway),
                          _buildInfoRow('MAC Address', _networkInfo?.macAddress),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Peer Subnet Checker
                  const Text(
                    'Check Peer Subnet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 4,
                    color: Colors.grey[900],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: _peerIpController,
                            decoration: InputDecoration(
                              labelText: 'Peer IP Address',
                              hintText: 'e.g., 192.168.1.100',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.check_circle),
                                onPressed: _checkPeerSubnet,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            onSubmitted: (_) => _checkPeerSubnet(),
                          ),
                          if (_isSameSubnet != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _isSameSubnet! 
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _isSameSubnet! ? Colors.green : Colors.red,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _isSameSubnet! ? Icons.check_circle : Icons.cancel,
                                    color: _isSameSubnet! ? Colors.green : Colors.red,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _isSameSubnet!
                                          ? 'Peer is on the SAME local network'
                                          : 'Peer is on a DIFFERENT network',
                                      style: TextStyle(
                                        color: _isSameSubnet! ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Use network prefix to automatically detect peers on the same LAN',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.amber[200],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}