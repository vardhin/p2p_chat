import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:p2p_chat/utils/identity_manager.dart';
import 'package:p2p_chat/utils/crypto_key_generator.dart';

class CryptoKeysScreen extends StatefulWidget {
  final Identity identity;

  const CryptoKeysScreen({super.key, required this.identity});

  @override
  State<CryptoKeysScreen> createState() => _CryptoKeysScreenState();
}

class _CryptoKeysScreenState extends State<CryptoKeysScreen> {
  late Identity _identity;
  Map<String, String>? _cryptoKeys;
  bool _isLoading = false;
  bool _showKeys = false;

  @override
  void initState() {
    super.initState();
    _identity = widget.identity;
    _generateCryptoKeys();
  }

  Future<void> _generateCryptoKeys() async {
    setState(() => _isLoading = true);
    try {
      // Generate key pair using the crypto key generator utility
      final keys = CryptoKeyGenerator.generateKeyPair(_identity.seedPhrase);
      
      setState(() {
        _cryptoKeys = keys;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating keys: $e')),
        );
      }
    }
  }

  void _copyKeyToClipboard(String keyName, String keyValue) {
    Clipboard.setData(ClipboardData(text: keyValue));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$keyName copied to clipboard'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _exportAllKeys() async {
    if (_cryptoKeys == null) return;

    final exportData = CryptoKeyGenerator.exportIdentityData(
      seedPhrase: _identity.seedPhrase,
      identityName: _identity.name,
    );

    Clipboard.setData(ClipboardData(text: exportData));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All keys exported to clipboard'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildKeyCard(String keyName, String? keyValue) {
    return Card(
      elevation: 4,
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  keyName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: keyValue != null
                      ? () => _copyKeyToClipboard(keyName, keyValue)
                      : null,
                  tooltip: 'Copy to clipboard',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (keyValue != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.deepPurple, width: 0.5),
                ),
                child: SelectableText(
                  _showKeys ? keyValue : keyValue.replaceAll(RegExp(r'.'), '*'),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.greenAccent,
                  ),
                ),
              )
            else
              const Text(
                'Failed to generate key',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cryptographic Keys'),
        backgroundColor: Colors.deepPurple,
        elevation: 4,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      border: Border.all(color: Colors.orange),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⚠️ Security Notice',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'These cryptographic keys are derived from your seed phrase. '
                          'Keep them secret and secure. Never share these keys with anyone. '
                          'These are used for encryption and identity verification.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Toggle visibility
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Show Keys',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Switch(
                        value: _showKeys,
                        onChanged: (value) => setState(() => _showKeys = value),
                        activeColor: Colors.deepPurple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Keys Display
                  const Text(
                    'Your Public & Private Keys',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  if (_cryptoKeys != null)
                    Column(
                      children: [
                        _buildKeyCard('Private Key', _cryptoKeys!['private_key']),
                        _buildKeyCard('Public Key', _cryptoKeys!['public_key']),
                      ],
                    )
                  else
                    const Center(
                      child: Text('Failed to generate keys'),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _generateCryptoKeys,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Regenerate Keys'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _exportAllKeys,
                          icon: const Icon(Icons.download),
                          label: const Text('Export All Keys'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Info about key derivation
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
                          'Key Information',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• Private Key: Your secret key for signing and authentication. '
                          'NEVER share this with anyone!\n'
                          '• Public Key: Your identity key shared with peers. Used for verification.\n\n'
                          'Both keys are derived from your seed phrase using SHA256 hashing.',
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
}
