import 'dart:io';
import 'package:flutter/material.dart';
import 'package:p2p_chat/screens/settings_screen.dart';
import 'package:p2p_chat/screens/network_info_screen.dart';
import 'package:p2p_chat/screens/profile_screen.dart';
import 'package:p2p_chat/screens/identity_selection_screen.dart';
import 'package:p2p_chat/utils/identity_manager.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _identityManager = IdentityManager();
  Identity? _currentIdentity;
  int _currentIndex = 1; // Start at chat screen (middle)

  final List<Widget> _screens = [
    const SettingsScreen(),
    const _ChatHomeScreen(),
    const NetworkInfoScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadIdentity();
  }

  Future<void> _loadIdentity() async {
    final identity = await _identityManager.getCurrentIdentity();
    setState(() => _currentIdentity = identity);
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
      _loadIdentity();
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
        children: _screens,
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
              onPressed: () {
                // TODO: Quick add peer
              },
              backgroundColor: Colors.deepPurple,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _ChatHomeScreen extends StatelessWidget {
  const _ChatHomeScreen();

  @override
  Widget build(BuildContext context) {
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
            'No conversations yet',
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
            onPressed: () {
              // TODO: Navigate to add peer
            },
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
}