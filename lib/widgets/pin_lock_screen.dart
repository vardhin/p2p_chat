import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:p2p_chat/utils/pin_manager.dart';
import 'package:p2p_chat/utils/network_data_cache.dart';

class PinLockScreen extends StatefulWidget {
  const PinLockScreen({super.key});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final _pinController = TextEditingController();
  final _seedPhraseController = TextEditingController();
  String? _errorMessage;
  bool _isVerifying = false;
  bool _requiresSeedPhrase = false;
  int _failedAttempts = 0;
  final _pinManager = PinManager();
  final _cache = NetworkDataCache();

  @override
  void initState() {
    super.initState();
    _checkSessionStatus();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _seedPhraseController.dispose();
    super.dispose();
  }

  Future<void> _checkSessionStatus() async {
    final invalidated = await _pinManager.isSessionInvalidated();
    final attempts = await _pinManager.getFailedAttempts();
    if (mounted) {
      setState(() {
        _requiresSeedPhrase = invalidated;
        _failedAttempts = attempts;
      });
    }
  }

  Future<void> _verifyPin() async {
    if (_pinController.text.length != 4) {
      setState(() => _errorMessage = 'PIN must be 4 digits');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    await Future.delayed(const Duration(milliseconds: 100));
    final isCorrect = await _pinManager.verifyPin(_pinController.text);

    if (isCorrect) {
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } else {
      final attempts = await _pinManager.getFailedAttempts();
      final remaining = 4 - attempts;
      
      if (mounted) {
        setState(() {
          _failedAttempts = attempts;
          _isVerifying = false;
          
          if (attempts >= 4) {
            _requiresSeedPhrase = true;
            _errorMessage = 'Too many failed attempts. Enter seed phrase.';
          } else {
            _errorMessage = 'Incorrect PIN ($remaining attempts remaining)';
          }
        });
      }
      _pinController.clear();
    }
  }

  Future<void> _verifySeedPhrase() async {
    final seedPhrase = _seedPhraseController.text.trim();
    
    if (seedPhrase.isEmpty) {
      setState(() => _errorMessage = 'Please enter your seed phrase');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    await Future.delayed(const Duration(milliseconds: 100));
    final isValid = await _cache.verifySeedPhrase(seedPhrase);

    if (isValid) {
      await _pinManager.resetFailedAttempts();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } else {
      if (mounted) {
        setState(() {
          _errorMessage = 'Invalid seed phrase';
          _isVerifying = false;
        });
      }
      _seedPhraseController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: true, // Fix for keyboard
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 
                             MediaQuery.of(context).viewInsets.bottom - 100,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _requiresSeedPhrase ? Icons.warning : Icons.lock,
                      size: 80,
                      color: _requiresSeedPhrase ? Colors.orange : Colors.deepPurple,
                    ),
                    const SizedBox(height: 30),
                    Text(
                      _requiresSeedPhrase ? 'Session Invalidated' : 'Enter PIN to Unlock',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_requiresSeedPhrase) ...[
                      const SizedBox(height: 10),
                      const Text(
                        '4 failed attempts. Enter seed phrase to continue.',
                        style: TextStyle(color: Colors.orange, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 40),
                    if (!_requiresSeedPhrase) ...[
                      SizedBox(
                        width: 200,
                        child: TextField(
                          controller: _pinController,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          obscureText: true,
                          autofocus: true,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 32, letterSpacing: 20),
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            counterText: '',
                            border: const OutlineInputBorder(),
                            errorText: _errorMessage,
                            errorMaxLines: 2,
                          ),
                          onChanged: (value) {
                            if (value.length == 4 && !_isVerifying) {
                              _verifyPin();
                            }
                          },
                        ),
                      ),
                      if (_failedAttempts > 0) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Failed attempts: $_failedAttempts/4',
                          style: TextStyle(
                            color: _failedAttempts >= 3 ? Colors.red : Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ] else ...[
                      TextField(
                        controller: _seedPhraseController,
                        maxLines: 3,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: 'Seed Phrase',
                          border: const OutlineInputBorder(),
                          errorText: _errorMessage,
                          helperText: 'Enter your 12-word seed phrase',
                          helperMaxLines: 2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isVerifying ? null : _verifySeedPhrase,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          backgroundColor: Colors.deepPurple,
                        ),
                        child: const Text('Verify Seed Phrase'),
                      ),
                    ],
                    if (_isVerifying) ...[
                      const SizedBox(height: 20),
                      const CircularProgressIndicator(color: Colors.deepPurple),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}