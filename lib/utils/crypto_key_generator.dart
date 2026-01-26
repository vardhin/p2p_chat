import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Utility class for public/private key pair generation
class CryptoKeyGenerator {
  /// Generates a public/private key pair from a seed phrase
  /// Returns a map with only 'public_key' and 'private_key'
  static Map<String, String> generateKeyPair(String seedPhrase) {
    try {
      // Derive private key from seed phrase
      final privateKeyBytes = _derivePrivateKey(seedPhrase);
      final privateKey = base64Encode(privateKeyBytes);

      // Derive public key from private key
      final publicKeyBytes = _derivePublicKey(privateKeyBytes);
      final publicKey = base64Encode(publicKeyBytes);

      return {
        'private_key': privateKey,
        'public_key': publicKey,
      };
    } catch (e) {
      throw Exception('Failed to generate key pair: $e');
    }
  }

  /// Derives the private key from seed phrase using SHA256
  /// Private key = SHA256(seedPhrase + 'private_key_derivation')
  static Uint8List _derivePrivateKey(String seedPhrase) {
    final seedBytes = utf8.encode(seedPhrase);
    final domainBytes = utf8.encode('private_key_derivation');
    
    final combined = <int>[...seedBytes, ...domainBytes];
    final digest = sha256.convert(combined);
    
    return Uint8List.fromList(digest.bytes);
  }

  /// Derives the public key from private key using SHA256
  /// Public key = SHA256(privateKey + 'public_key_derivation')
  static Uint8List _derivePublicKey(Uint8List privateKey) {
    final domainBytes = utf8.encode('public_key_derivation');
    
    final combined = <int>[...privateKey, ...domainBytes];
    final digest = sha256.convert(combined);
    
    return Uint8List.fromList(digest.bytes);
  }

  /// Generates a formatted JSON string containing the key pair
  static String generateKeyPairAsJson(String seedPhrase) {
    final keys = generateKeyPair(seedPhrase);
    
    final json = {
      'private_key': keys['private_key'],
      'public_key': keys['public_key'],
      'key_format': 'base64',
      'algorithm': 'SHA256',
      'key_size': '256-bit',
    };

    return jsonEncode(json);
  }

  /// Exports complete identity data including key pair
  static String exportIdentityData({
    required String seedPhrase,
    required String identityName,
  }) {
    final keys = generateKeyPair(seedPhrase);
    
    final json = {
      'identity_name': identityName,
      'seed_phrase': seedPhrase,
      'key_pair': {
        'private_key': keys['private_key'],
        'public_key': keys['public_key'],
      },
      'export_date': DateTime.now().toIso8601String(),
      'version': '1.0',
    };

    return jsonEncode(json);
  }

  /// Gets just the public key from seed phrase (useful for sharing)
  static String getPublicKeyOnly(String seedPhrase) {
    try {
      final privateKeyBytes = _derivePrivateKey(seedPhrase);
      final publicKeyBytes = _derivePublicKey(privateKeyBytes);
      return base64Encode(publicKeyBytes);
    } catch (e) {
      throw Exception('Failed to derive public key: $e');
    }
  }

  /// Gets just the private key from seed phrase
  static String getPrivateKeyOnly(String seedPhrase) {
    try {
      final privateKeyBytes = _derivePrivateKey(seedPhrase);
      return base64Encode(privateKeyBytes);
    } catch (e) {
      throw Exception('Failed to derive private key: $e');
    }
  }
}
