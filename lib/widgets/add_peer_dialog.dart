import 'package:flutter/material.dart';

class AddPeerDialog extends StatefulWidget {
  const AddPeerDialog({super.key});

  @override
  State<AddPeerDialog> createState() => _AddPeerDialogState();
}

class _AddPeerDialogState extends State<AddPeerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '8080');
  final _publicKeyController = TextEditingController();
  
  bool _useLocalIP = true;

  @override
  void dispose() {
    _nameController.dispose();
    _ipController.dispose();
    _portController.dispose();
    _publicKeyController.dispose();
    super.dispose();
  }

  void _addPeer() {
    if (_formKey.currentState!.validate()) {
      final peerData = {
        'name': _nameController.text.trim(),
        'ip': _ipController.text.trim(),
        'port': int.parse(_portController.text.trim()),
        'publicKey': _publicKeyController.text.trim(),
        'useLocalIP': _useLocalIP,
      };
      
      Navigator.of(context).pop(peerData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.person_add,
                      color: Colors.deepPurple,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Add New Peer',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Peer Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Peer Name',
                    hintText: 'e.g., Alice',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a peer name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Connection Type Switch
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _useLocalIP ? Icons.router : Icons.public,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _useLocalIP ? 'Local Network' : 'Public Internet',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Switch(
                        value: _useLocalIP,
                        onChanged: (value) => setState(() => _useLocalIP = value),
                        activeColor: Colors.deepPurple,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // IP Address
                TextFormField(
                  controller: _ipController,
                  decoration: InputDecoration(
                    labelText: _useLocalIP ? 'Local IP Address' : 'Public IP Address',
                    hintText: _useLocalIP ? '192.168.1.100' : '203.0.113.42',
                    prefixIcon: Icon(_useLocalIP ? Icons.router : Icons.public),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an IP address';
                    }
                    // Basic IP validation
                    final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
                    if (!ipRegex.hasMatch(value.trim())) {
                      return 'Invalid IP address format';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Port
                TextFormField(
                  controller: _portController,
                  decoration: const InputDecoration(
                    labelText: 'Port',
                    hintText: '8080',
                    prefixIcon: Icon(Icons.settings_ethernet),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a port';
                    }
                    final port = int.tryParse(value.trim());
                    if (port == null || port < 1 || port > 65535) {
                      return 'Port must be between 1 and 65535';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Public Key
                TextFormField(
                  controller: _publicKeyController,
                  decoration: const InputDecoration(
                    labelText: 'Public Key',
                    hintText: 'Peer\'s public key',
                    prefixIcon: Icon(Icons.key),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter peer\'s public key';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                // Info Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Make sure the peer is online and reachable at this address',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[200],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _addPeer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Add Peer'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}