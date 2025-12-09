import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class PinManager {
  static final PinManager _instance = PinManager._internal();
  factory PinManager() => _instance;
  PinManager._internal();

  final _secureStorage = const FlutterSecureStorage();
  static const String _pinHashKey = 'app_pin_hash';
  static const String _autoLockEnabledKey = 'auto_lock_enabled';
  static const String _failedAttemptsKey = 'failed_attempts';
  static const String _sessionInvalidatedKey = 'session_invalidated';
  static const int _maxAttempts = 4;

  /// Hash PIN with SHA-256
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Set up PIN for auto-lock
  Future<void> setPin(String pin) async {
    if (pin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(pin)) {
      throw Exception('PIN must be exactly 4 digits');
    }
    final hashedPin = _hashPin(pin);
    await _secureStorage.write(key: _pinHashKey, value: hashedPin);
    await _secureStorage.write(key: _autoLockEnabledKey, value: 'true');
    await resetFailedAttempts();
  }

  /// Verify PIN
  Future<bool> verifyPin(String pin) async {
    final storedHash = await _secureStorage.read(key: _pinHashKey);
    if (storedHash == null) return false;
    
    final isCorrect = storedHash == _hashPin(pin);
    
    if (!isCorrect) {
      await incrementFailedAttempts();
    } else {
      await resetFailedAttempts();
    }
    
    return isCorrect;
  }

  Future<int> getFailedAttempts() async {
    final attempts = await _secureStorage.read(key: _failedAttemptsKey);
    return int.tryParse(attempts ?? '0') ?? 0;
  }

  Future<void> incrementFailedAttempts() async {
    final current = await getFailedAttempts();
    final newCount = current + 1;
    await _secureStorage.write(key: _failedAttemptsKey, value: newCount.toString());
    
    if (newCount >= _maxAttempts) {
      await invalidateSession();
    }
  }

  Future<void> resetFailedAttempts() async {
    await _secureStorage.delete(key: _failedAttemptsKey);
    await _secureStorage.delete(key: _sessionInvalidatedKey);
  }

  Future<void> invalidateSession() async {
    await _secureStorage.write(key: _sessionInvalidatedKey, value: 'true');
  }

  Future<bool> isSessionInvalidated() async {
    final invalidated = await _secureStorage.read(key: _sessionInvalidatedKey);
    return invalidated == 'true';
  }

  /// Check if auto-lock is enabled
  Future<bool> isAutoLockEnabled() async {
    final enabled = await _secureStorage.read(key: _autoLockEnabledKey);
    return enabled == 'true';
  }

  /// Enable auto-lock (PIN must be set first)
  Future<void> enableAutoLock() async {
    final hasPin = await hasStoredPin();
    if (!hasPin) {
      throw Exception('PIN must be set before enabling auto-lock');
    }
    await _secureStorage.write(key: _autoLockEnabledKey, value: 'true');
  }

  /// Disable auto-lock
  Future<void> disableAutoLock() async {
    await _secureStorage.write(key: _autoLockEnabledKey, value: 'false');
  }

  /// Check if PIN is set
  Future<bool> hasStoredPin() async {
    final pin = await _secureStorage.read(key: _pinHashKey);
    return pin != null;
  }

  /// Remove PIN and disable auto-lock
  Future<void> removePin() async {
    await _secureStorage.delete(key: _pinHashKey);
    await _secureStorage.delete(key: _autoLockEnabledKey);
    await _secureStorage.delete(key: _failedAttemptsKey);
    await _secureStorage.delete(key: _sessionInvalidatedKey);
  }
}