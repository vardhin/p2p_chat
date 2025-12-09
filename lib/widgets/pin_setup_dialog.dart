import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:p2p_chat/utils/pin_manager.dart';

class PinSetupDialog extends StatefulWidget {
  const PinSetupDialog({super.key});

  @override
  State<PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends State<PinSetupDialog> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _isConfirming = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (!_isConfirming) {
      // First entry
      if (_pinController.text.length != 4) {
        setState(() => _errorMessage = 'PIN must be 4 digits');
        return;
      }
      setState(() {
        _isConfirming = true;
        _errorMessage = null;
      });
    } else {
      // Confirm entry
      if (_pinController.text != _confirmPinController.text) {
        setState(() => _errorMessage = 'PINs do not match');
        _confirmPinController.clear();
        return;
      }

      try {
        await PinManager().setPin(_pinController.text);
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        setState(() => _errorMessage = e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isConfirming ? 'Confirm PIN' : 'Set Up PIN'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_isConfirming) ...[
            const Text('Enter a 4-digit PIN for app lock'),
            const SizedBox(height: 20),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              autofocus: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Enter PIN',
                border: const OutlineInputBorder(),
                errorText: _errorMessage,
              ),
              onSubmitted: (_) => _handleSubmit(),
            ),
          ] else ...[
            const Text('Confirm your PIN'),
            const SizedBox(height: 20),
            TextField(
              controller: _confirmPinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              autofocus: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Confirm PIN',
                border: const OutlineInputBorder(),
                errorText: _errorMessage,
              ),
              onSubmitted: (_) => _handleSubmit(),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _handleSubmit,
          child: Text(_isConfirming ? 'Confirm' : 'Next'),
        ),
      ],
    );
  }
}