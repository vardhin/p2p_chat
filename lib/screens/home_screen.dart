import 'dart:io';
import 'package:flutter/material.dart';
import 'package:p2p_chat/screens/settings_screen.dart';
import 'package:p2p_chat/screens/profile_screen.dart';
import 'package:p2p_chat/screens/identity_selection_screen.dart';
import 'package:p2p_chat/utils/identity_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _identityManager = IdentityManager();
  Identity? _currentIdentity;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('P2P Chat'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: _buildProfileAvatar(),
            onPressed: _openProfile,
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 100, color: Colors.deepPurple),
            SizedBox(height: 20),
            Text(
              'Welcome to P2P Chat',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Start a secure conversation'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Start new chat
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add_comment),
      ),
    );
  }
}