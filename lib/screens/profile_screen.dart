import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:p2p_chat/utils/identity_manager.dart';
import 'package:p2p_chat/utils/pin_manager.dart';
import 'package:p2p_chat/screens/identity_selection_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Identity identity;

  const ProfileScreen({super.key, required this.identity});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Identity _currentIdentity;
  final _identityManager = IdentityManager();
  final _pinManager = PinManager();
  final _nameController = TextEditingController();
  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    _currentIdentity = widget.identity;
    _nameController.text = _currentIdentity.name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      // Save to app directory
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'profile_${_currentIdentity.id}.jpg';
      final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');

      // Update identity
      final updatedIdentity = _currentIdentity.copyWith(
        profilePicturePath: savedImage.path,
      );

      await _identityManager.updateIdentity(updatedIdentity);
      
      setState(() {
        _currentIdentity = updatedIdentity;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated')),
        );
      }
    }
  }

  Future<void> _updateName() async {
    final newName = _nameController.text.trim();
    
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    final updatedIdentity = _currentIdentity.copyWith(name: newName);
    await _identityManager.updateIdentity(updatedIdentity);

    setState(() {
      _currentIdentity = updatedIdentity;
      _isEditingName = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name updated')),
      );
    }
  }

  Future<void> _changeIdentity() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const IdentitySelectionScreen(isChanging: true),
      ),
    );

    if (result == true && mounted) {
      // Identity changed, pop back to home
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _identityManager.logout();
      if (mounted) {
        Navigator.of(context).pop(true); // Signal logout
      }
    }
  }

  Widget _buildProfilePicture() {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.deepPurple,
            backgroundImage: _currentIdentity.profilePicturePath != null
                ? FileImage(File(_currentIdentity.profilePicturePath!))
                : null,
            child: _currentIdentity.profilePicturePath == null
                ? Text(
                    _currentIdentity.name[0].toUpperCase(),
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt, size: 20),
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
        title: const Text('Profile'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildProfilePicture(),
            const SizedBox(height: 10),
            const Text(
              'Tap to change picture',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            
            // Identity Name
            if (_isEditingName)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Identity Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _updateName,
                    icon: const Icon(Icons.check, color: Colors.green),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isEditingName = false;
                        _nameController.text = _currentIdentity.name;
                      });
                    },
                    icon: const Icon(Icons.close, color: Colors.red),
                  ),
                ],
              )
            else
              ListTile(
                leading: const Icon(Icons.person, color: Colors.deepPurple),
                title: const Text('Identity Name'),
                subtitle: Text(
                  _currentIdentity.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => setState(() => _isEditingName = true),
                ),
              ),
            
            const Divider(height: 40),
            
            // Identity ID
            ListTile(
              leading: const Icon(Icons.fingerprint, color: Colors.deepPurple),
              title: const Text('Identity ID'),
              subtitle: Text(
                _currentIdentity.id,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
            
            // Created At
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.deepPurple),
              title: const Text('Created'),
              subtitle: Text(
                '${_currentIdentity.createdAt.day}/${_currentIdentity.createdAt.month}/${_currentIdentity.createdAt.year}',
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Change Identity Button
            ElevatedButton.icon(
              onPressed: _changeIdentity,
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Change Identity'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Logout Button
            ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}