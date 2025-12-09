import 'dart:convert';
import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:p2p_chat/src/rust/api/crypto.dart';
import 'package:p2p_chat/src/rust/api/network.dart';

class NetworkDataCache {
  static final NetworkDataCache _instance = NetworkDataCache._internal();
  factory NetworkDataCache() => _instance;
  NetworkDataCache._internal();

  Database? _database;
  final _secureStorage = const FlutterSecureStorage();
  
  static const String _seedPhraseKey = 'user_seed_phrase';
  static const String _identityExistsKey = 'identity_exists';
  static const int _cacheValidityMinutes = 30;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'network_cache.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE network_data (
            id INTEGER PRIMARY KEY,
            encrypted_data BLOB NOT NULL,
            cached_at INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  /// Store seed phrase securely
  Future<void> storeSeedPhrase(String seedPhrase) async {
    await _secureStorage.write(key: _seedPhraseKey, value: seedPhrase);
    await _secureStorage.write(key: _identityExistsKey, value: 'true');
  }

  /// Retrieve seed phrase
  Future<String?> getSeedPhrase() async {
    return await _secureStorage.read(key: _seedPhraseKey);
  }

  /// Check if identity exists
  Future<bool> hasIdentity() async {
    final exists = await _secureStorage.read(key: _identityExistsKey);
    return exists == 'true';
  }

  /// Verify seed phrase matches stored one
  Future<bool> verifySeedPhrase(String seedPhrase) async {
    final stored = await getSeedPhrase();
    return stored == seedPhrase;
  }

  /// Cache network data with encryption
  Future<void> cacheNetworkData(NetworkInfo networkInfo) async {
    try {
      final seedPhrase = await getSeedPhrase();
      if (seedPhrase == null) {
        throw Exception('Seed phrase not found');
      }

      // Convert NetworkInfo to JSON
      final jsonData = jsonEncode({
        'local_ipv4': networkInfo.localIpv4,
        'local_ipv6': networkInfo.localIpv6,
        'public_ipv4': networkInfo.publicIpv4,
        'public_ipv6': networkInfo.publicIpv6,
        'subnet_mask': networkInfo.subnetMask,
        'gateway': networkInfo.gateway,
        'network_prefix': networkInfo.networkPrefix,
        'interface_name': networkInfo.interfaceName,
        'mac_address': networkInfo.macAddress,
        'broadcast_address': networkInfo.broadcastAddress,
      });

      // Encrypt data
      final encryptedData = encryptNetworkData(
        data: jsonData,
        seedPhrase: seedPhrase,
      );

      final db = await database;
      
      // Delete old cache
      await db.delete('network_data');
      
      // Insert new cache
      await db.insert('network_data', {
        'encrypted_data': encryptedData,
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error caching network data: $e');
      rethrow;
    }
  }

  /// Retrieve cached network data if still valid
  Future<NetworkInfo?> getCachedNetworkData({bool forceRefresh = false}) async {
    try {
      if (forceRefresh) {
        return null; // Force refresh, don't use cache
      }

      final seedPhrase = await getSeedPhrase();
      if (seedPhrase == null) {
        return null;
      }

      final db = await database;
      final List<Map<String, dynamic>> results = await db.query(
        'network_data',
        limit: 1,
        orderBy: 'cached_at DESC',
      );

      if (results.isEmpty) {
        return null;
      }

      final cachedAt = results[0]['cached_at'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      final ageMinutes = (now - cachedAt) ~/ (1000 * 60);

      // Check if cache is still valid
      if (ageMinutes > _cacheValidityMinutes) {
        await clearCache(); // Clear expired cache
        return null;
      }

      // Decrypt data
      final encryptedData = results[0]['encrypted_data'] as List<int>;
      final decryptedJson = decryptNetworkData(
        encryptedData: Uint8List.fromList(encryptedData),
        seedPhrase: seedPhrase,
      );

      final Map<String, dynamic> jsonData = jsonDecode(decryptedJson);

      // Reconstruct NetworkInfo
      return NetworkInfo(
        localIpv4: jsonData['local_ipv4'],
        localIpv6: jsonData['local_ipv6'],
        publicIpv4: jsonData['public_ipv4'],
        publicIpv6: jsonData['public_ipv6'],
        subnetMask: jsonData['subnet_mask'],
        gateway: jsonData['gateway'],
        networkPrefix: jsonData['network_prefix'],
        interfaceName: jsonData['interface_name'],
        macAddress: jsonData['mac_address'],
        broadcastAddress: jsonData['broadcast_address'],
      );
    } catch (e) {
      print('Error retrieving cached network data: $e');
      return null;
    }
  }

  /// Get cache age in minutes
  Future<int?> getCacheAgeMinutes() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> results = await db.query(
        'network_data',
        limit: 1,
        orderBy: 'cached_at DESC',
      );

      if (results.isEmpty) {
        return null;
      }

      final cachedAt = results[0]['cached_at'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      return (now - cachedAt) ~/ (1000 * 60);
    } catch (e) {
      return null;
    }
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    final db = await database;
    await db.delete('network_data');
  }

  /// Clear all data including seed phrase
  Future<void> clearAll() async {
    await clearCache();
    await _secureStorage.delete(key: _seedPhraseKey);
    await _secureStorage.delete(key: _identityExistsKey);
  }
}