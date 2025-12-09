import 'dart:io';
import 'package:flutter/material.dart';
import 'package:p2p_chat/utils/identity_manager.dart';
import 'package:p2p_chat/utils/pin_manager.dart';
import 'package:p2p_chat/screens/identity_setup_screen.dart';
import 'package:p2p_chat/screens/home_screen.dart';
import 'package:p2p_chat/widgets/pin_setup_dialog.dart';

class IdentitySelectionScreen extends StatefulWidget {
  final bool isChanging;
  
  const IdentitySelectionScreen({super.key, this.isChanging = false});

  @override
  State<IdentitySelectionScreen> createState() => _IdentitySelectionScreenState();
}

class _IdentitySelectionScreenState extends State<IdentitySelectionScreen> {
  final _identityManager = IdentityManager();
  final _pinManager = PinManager();
  List<Identity> _identities = [];
  bool _isLoading = true;
  String? _currentIdentityId;

  @override
  void initState() {
    super.initState();
    _loadIdentities();
  }

  Future<void> _loadIdentities() async {
    final identities = await _identityManager.getAllIdentities();
    final currentIdentity = await _identityManager.getCurrentIdentity();
    
    setState(() {
      _identities = identities;
      _currentIdentityId = currentIdentity?.id;
      _isLoading = false;
    });
  }

  Future<void> _selectIdentity(Identity identity) async {
    // If changing identity, just switch
    if (widget.isChanging) {
      await _identityManager.setCurrentIdentity(identity.id);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
      return;
    }

    // First time selection
    await _identityManager.setCurrentIdentity(identity.id);
    
    final hasPin = await _pinManager.hasStoredPin();
    
    if (!hasPin && mounted) {
      final pinSet = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const PinSetupDialog(),
      );

      if (pinSet == true && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } else if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  Future<void> _createNewIdentity() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const IdentitySetupScreen()),
    );
    
    if (result == true) {
      _loadIdentities();
    }
  }

  Future<void> _deleteIdentity(Identity identity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Identity'),
        content: Text('Are you sure you want to delete "${identity.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _identityManager.deleteIdentity(identity.id);
      _loadIdentities();
    }
  }

  Widget _buildProfileAvatar(Identity identity) {
    if (identity.profilePicturePath != null) {
      return CircleAvatar(
        radius: 25,
        backgroundImage: FileImage(File(identity.profilePicturePath!)),
      );
    }
    
    return CircleAvatar(
      radius: 25,
      backgroundColor: Colors.deepPurple,
      child: Text(
        identity.name[0].toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
      onWillPop: () async => widget.isChanging,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isChanging ? 'Change Identity' : 'Select Identity'),
          backgroundColor: Colors.deepPurple,
          automaticallyImplyLeading: widget.isChanging,
        ),
        body: _identities.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.account_circle, size: 100, color: Colors.grey),
                    const SizedBox(height: 20),
                    const Text('No identities found', style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: _createNewIdentity,
                      icon: const Icon(Icons.add),
                      label: const Text('Create New Identity'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        backgroundColor: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _identities.length,
                      itemBuilder: (context, index) {
                        final identity = _identities[index];
                        final isCurrent = identity.id == _currentIdentityId;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: isCurrent ? Colors.deepPurple.withOpacity(0.2) : null,
                          child: ListTile(
                            leading: _buildProfileAvatar(identity),
                            title: Row(
                              children: [
                                Text(
                                  identity.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (isCurrent) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Active',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Text(
                              'Created ${_formatDate(identity.createdAt)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteIdentity(identity),
                            ),
                            onTap: () => _selectIdentity(identity),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                      onPressed: _createNewIdentity,
                      icon: const Icon(Icons.add),
                      label: const Text('Create New Identity'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.deepPurple,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}