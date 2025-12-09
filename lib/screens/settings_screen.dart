import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),
          _buildSection(
            title: 'Identity',
            children: [
              _buildListTile(
                icon: Icons.fingerprint,
                title: 'View Seed Phrase',
                subtitle: 'Backup your identity',
                onTap: () {
                  // TODO: Show seed phrase
                },
              ),
              _buildListTile(
                icon: Icons.key,
                title: 'Export Keys',
                subtitle: 'Export cryptographic keys',
                onTap: () {
                  // TODO: Export keys
                },
              ),
            ],
          ),
          const Divider(),
          _buildSection(
            title: 'Privacy & Security',
            children: [
              _buildListTile(
                icon: Icons.lock,
                title: 'Auto-lock',
                subtitle: 'Lock app after inactivity',
                trailing: Switch(
                  value: true,
                  onChanged: (value) {
                    // TODO: Toggle auto-lock
                  },
                ),
              ),
              _buildListTile(
                icon: Icons.visibility_off,
                title: 'Hide IP Address',
                subtitle: 'Use Tor or VPN',
                trailing: Switch(
                  value: false,
                  onChanged: (value) {
                    // TODO: Toggle IP hiding
                  },
                ),
              ),
              _buildListTile(
                icon: Icons.delete_forever,
                title: 'Clear Chat History',
                subtitle: 'Delete all conversations',
                onTap: () {
                  // TODO: Clear history
                },
              ),
            ],
          ),
          const Divider(),
          _buildSection(
            title: 'Network',
            children: [
              _buildListTile(
                icon: Icons.vpn_key,
                title: 'Port Settings',
                subtitle: 'Configure P2P ports',
                onTap: () {
                  // TODO: Port settings
                },
              ),
              _buildListTile(
                icon: Icons.dns,
                title: 'STUN/TURN Servers',
                subtitle: 'NAT traversal configuration',
                onTap: () {
                  // TODO: Server settings
                },
              ),
            ],
          ),
          const Divider(),
          _buildSection(
            title: 'About',
            children: [
              _buildListTile(
                icon: Icons.info,
                title: 'App Version',
                subtitle: '1.0.0',
              ),
              _buildListTile(
                icon: Icons.code,
                title: 'Open Source',
                subtitle: 'View on GitHub',
                onTap: () {
                  // TODO: Open GitHub
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Reset app
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Reset App?'),
                    content: const Text(
                      'This will delete all data including your identity. This action cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Implement reset
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.restore),
              label: const Text('Reset App'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
    );
  }
}