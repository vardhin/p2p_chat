import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:p2p_chat/utils/network_data_cache.dart';
import 'package:p2p_chat/utils/pin_manager.dart';
import 'package:p2p_chat/utils/identity_manager.dart';
import 'package:p2p_chat/widgets/pin_setup_dialog.dart';
import 'package:p2p_chat/screens/crypto_keys_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoLockEnabled = false;
  final _cache = NetworkDataCache();
  final _pinManager = PinManager();
  final _identityManager = IdentityManager();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await _pinManager.isAutoLockEnabled();
    setState(() => _autoLockEnabled = enabled);
  }

  Future<void> _showSeedPhrase() async {
    final identity = await _identityManager.getCurrentIdentity();
    final seedPhrase = identity?.seedPhrase;
    
    if (seedPhrase == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No seed phrase found')),
        );
      }
      return;
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Your Seed Phrase'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.deepPurple),
                ),
                child: SelectableText(
                  seedPhrase,
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '⚠️ Keep this safe! Never share it with anyone.',
                style: TextStyle(color: Colors.orange, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: seedPhrase));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
              child: const Text('Copy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _toggleAutoLock(bool value) async {
    if (value) {
      // Enable auto-lock - need to set up PIN first
      final hasPin = await _pinManager.hasStoredPin();
      
      if (!hasPin) {
        // Show PIN setup dialog
        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => const PinSetupDialog(),
        );

        if (result == true) {
          await _pinManager.enableAutoLock();
          setState(() => _autoLockEnabled = true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Auto-lock enabled')),
            );
          }
        }
      } else {
        await _pinManager.enableAutoLock();
        setState(() => _autoLockEnabled = true);
      }
    } else {
      // Disable auto-lock
      await _pinManager.disableAutoLock();
      setState(() => _autoLockEnabled = false);
    }
  }

  Future<void> _openGitHub() async {
    final uri = Uri.parse('https://github.com/vardhin/p2p_chat');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open GitHub')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 10),
        _buildSection(
          title: 'Identity',
          children: [
            _buildListTile(
              icon: Icons.fingerprint,
              title: 'View Seed Phrase',
              subtitle: 'Backup your identity',
              onTap: _showSeedPhrase,
            ),
            FutureBuilder<Identity?>(
              future: _identityManager.getCurrentIdentity(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return _buildListTile(
                    icon: Icons.key,
                    title: 'Cryptographic Keys',
                    subtitle: 'View and export crypto keys',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CryptoKeysScreen(
                            identity: snapshot.data!,
                          ),
                        ),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
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
              subtitle: 'Lock app with PIN after inactivity',
              trailing: Switch(
                value: _autoLockEnabled,
                onChanged: _toggleAutoLock,
              ),
            ),
            _buildListTile(
              icon: Icons.pin,
              title: 'Change PIN',
              subtitle: 'Update your lock PIN',
              onTap: () async {
                final result = await showDialog<bool>(
                  context: context,
                  builder: (context) => const PinSetupDialog(),
                );
                if (result == true && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN updated')),
                  );
                }
              },
            ),
            _buildListTile(
              icon: Icons.visibility_off,
              title: 'Hide IP Address',
              subtitle: 'Use Tor or VPN',
              trailing: Switch(
                value: false,
                onChanged: (value) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Coming soon!')),
                  );
                },
              ),
            ),
            _buildListTile(
              icon: Icons.delete_forever,
              title: 'Clear Cache',
              subtitle: 'Delete cached network data',
              onTap: () async {
                await _cache.clearCache();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cache cleared')),
                  );
                }
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coming soon!')),
                );
              },
            ),
            _buildListTile(
              icon: Icons.dns,
              title: 'STUN/TURN Servers',
              subtitle: 'NAT traversal configuration',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coming soon!')),
                );
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
              subtitle: 'github.com/vardhin/p2p_chat',
              onTap: _openGitHub,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ElevatedButton.icon(
            onPressed: () {
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
                      onPressed: () async {
                        await _cache.clearAll();
                        await _pinManager.removePin();
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('App reset complete')),
                          );
                        }
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