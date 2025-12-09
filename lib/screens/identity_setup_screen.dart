import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:p2p_chat/src/rust/api/identity.dart';
import 'package:p2p_chat/screens/home_screen.dart';
import 'package:p2p_chat/utils/identity_manager.dart';
import 'package:p2p_chat/utils/pin_manager.dart';
import 'package:p2p_chat/widgets/pin_setup_dialog.dart';

class IdentitySetupScreen extends StatefulWidget {
  const IdentitySetupScreen({super.key});

  @override
  State<IdentitySetupScreen> createState() => _IdentitySetupScreenState();
}

class _IdentitySetupScreenState extends State<IdentitySetupScreen> {
  final _nameController = TextEditingController(text: 'My Identity');
  String? _seedPhrase;
  bool _isRevealed = false;
  bool _hasConfirmed = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _generateSeedPhrase() {
    setState(() {
      _seedPhrase = generateSeedPhrase();
      _isRevealed = false;
      _hasConfirmed = false;
    });
  }

  void _copySeedPhrase() {
    if (_seedPhrase != null) {
      Clipboard.setData(ClipboardData(text: _seedPhrase!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seed phrase copied to clipboard'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _continue() async {
    // Store identity
    await IdentityManager().addIdentity(_nameController.text.trim(), _seedPhrase!);
    
    // Prompt to set up PIN
    if (mounted) {
      final pinSet = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const PinSetupDialog(),
      );

      if (pinSet == true && mounted) {
        Navigator.of(context).pop(true); // Return success
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Identity'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.security, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 20),
            const Text(
              'Secure P2P Identity',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Your seed phrase is the key to your identity. Keep it safe and never share it.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Identity Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 20),
            if (_seedPhrase == null)
              ElevatedButton.icon(
                onPressed: _generateSeedPhrase,
                icon: const Icon(Icons.add_circle),
                label: const Text('Generate Seed Phrase'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.deepPurple,
                ),
              )
            else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.deepPurple),
                ),
                child: Column(
                  children: [
                    if (_isRevealed)
                      SelectableText(
                        _seedPhrase!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'monospace',
                        ),
                      )
                    else
                      const Text(
                        '••• ••• ••• ••• ••• •••',
                        style: TextStyle(fontSize: 16, letterSpacing: 2),
                      ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton.icon(
                          onPressed: () => setState(() => _isRevealed = !_isRevealed),
                          icon: Icon(_isRevealed ? Icons.visibility_off : Icons.visibility),
                          label: Text(_isRevealed ? 'Hide' : 'Reveal'),
                        ),
                        TextButton.icon(
                          onPressed: _copySeedPhrase,
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              CheckboxListTile(
                value: _hasConfirmed,
                onChanged: (value) => setState(() => _hasConfirmed = value ?? false),
                title: const Text(
                  'I have safely stored my seed phrase',
                  style: TextStyle(fontSize: 14),
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _hasConfirmed ? _continue : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.green,
                ),
                child: const Text('Continue'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}