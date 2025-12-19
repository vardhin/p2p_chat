import 'dart:io';
import 'package:flutter/material.dart';
import 'package:p2p_chat/screens/settings_screen.dart';
import 'package:p2p_chat/screens/network_info_screen.dart';
import 'package:p2p_chat/screens/profile_screen.dart';
import 'package:p2p_chat/screens/identity_selection_screen.dart';
import 'package:p2p_chat/utils/identity_manager.dart';
import 'package:p2p_chat/utils/peer_manager.dart';
import 'package:p2p_chat/widgets/add_peer_dialog.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _identityManager = IdentityManager();
  final _peerManager = PeerManager();
  Identity? _currentIdentity;
  List<Peer> _peers = [];
  int _currentIndex = 1; // Start at chat screen (middle)

  @override
  void initState() {
    super.initState();
    _loadIdentityAndPeers();
  }

  Future<void> _loadIdentityAndPeers() async {
    final identity = await _identityManager.getCurrentIdentity();
    if (identity != null) {
      final peers = await _peerManager.getPeersForIdentity(identity.id);
      setState(() {
        _currentIdentity = identity;
        _peers = peers;
      });
    }
  }

  Future<void> _openProfile() async {
    if (_currentIdentity == null) return;

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfileScreen(identity: _currentIdentity!),
      ),
    );

    // If logout was triggered
    if (result == true && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const IdentitySelectionScreen(),
        ),
      );
    } else {
      // Reload identity in case it was updated
      _loadIdentityAndPeers();
    }
  }

  Widget _buildProfileAvatar() {
    if (_currentIdentity == null) {
      return const CircleAvatar(
        backgroundColor: Colors.deepPurple,
        child: Icon(Icons.person),
      );
    }

    if (_currentIdentity!.profilePicturePath != null) {
      return CircleAvatar(
        backgroundImage: FileImage(File(_currentIdentity!.profilePicturePath!)),
      );
    }

    return CircleAvatar(
      backgroundColor: Colors.deepPurple,
      child: Text(
        _currentIdentity!.name[0].toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Settings';
      case 1:
        return 'P2P Chats';
      case 2:
        return 'Network Info';
      default:
        return 'P2P Chat';
    }
  }

  Future<void> _showAddPeerDialog() async {
    if (_currentIdentity == null) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddPeerDialog(),
    );

    if (result != null && mounted) {
      try {
        await _peerManager.addPeer(
          identityId: _currentIdentity!.id,
          name: result['name'],
          ipAddress: result['ip'],
          port: result['port'],
          publicKey: result['publicKey'],
          useLocalIP: result['useLocalIP'],
        );

        // Reload peers
        await _loadIdentityAndPeers();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Peer "${result['name']}" added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add peer: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deletePeer(Peer peer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Peer'),
        content: Text('Are you sure you want to delete "${peer.name}"?'),
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
      await _peerManager.deletePeer(peer.id);
      _loadIdentityAndPeers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: _buildProfileAvatar(),
            onPressed: _openProfile,
            tooltip: 'Profile',
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const SettingsScreen(),
          _ChatHomeScreen(
            peers: _peers,
            onAddPeer: _showAddPeerDialog,
            onDeletePeer: _deletePeer,
          ),
          const NetworkInfoScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        backgroundColor: Colors.grey[900],
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.network_check),
            label: 'Network',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton(
              onPressed: _showAddPeerDialog,
              backgroundColor: Colors.deepPurple,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _ChatHomeScreen extends StatelessWidget {
  final List<Peer> peers;
  final VoidCallback onAddPeer;
  final Function(Peer) onDeletePeer;

  const _ChatHomeScreen({
    required this.peers,
    required this.onAddPeer,
    required this.onDeletePeer,
  });

  @override
  Widget build(BuildContext context) {
    if (peers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 100,
              color: Colors.grey[700],
            ),
            const SizedBox(height: 20),
            Text(
              'No peers yet',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Add a peer to start chatting',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: onAddPeer,
              icon: const Icon(Icons.add),
              label: const Text('Add New Peer'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                backgroundColor: Colors.deepPurple,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: peers.length,
      itemBuilder: (context, index) {
        final peer = peers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.deepPurple,
              child: Text(
                peer.name[0].toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              peer.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${peer.ipAddress}:${peer.port}',
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      peer.useLocalIP ? Icons.router : Icons.public,
                      size: 14,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      peer.useLocalIP ? 'Local' : 'Public',
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chat, color: Colors.deepPurple),
                  onPressed: () {
                    // TODO: Open chat with peer
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => onDeletePeer(peer),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}