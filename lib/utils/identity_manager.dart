import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class Identity {
  final String id;
  final String name;
  final String seedPhrase;
  final DateTime createdAt;
  final String? profilePicturePath;

  Identity({
    required this.id,
    required this.name,
    required this.seedPhrase,
    required this.createdAt,
    this.profilePicturePath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'seed_phrase': seedPhrase,
    'created_at': createdAt.toIso8601String(),
    'profile_picture_path': profilePicturePath,
  };

  factory Identity.fromJson(Map<String, dynamic> json) => Identity(
    id: json['id'],
    name: json['name'],
    seedPhrase: json['seed_phrase'],
    createdAt: DateTime.parse(json['created_at']),
    profilePicturePath: json['profile_picture_path'],
  );

  Identity copyWith({
    String? name,
    String? profilePicturePath,
  }) {
    return Identity(
      id: id,
      name: name ?? this.name,
      seedPhrase: seedPhrase,
      createdAt: createdAt,
      profilePicturePath: profilePicturePath ?? this.profilePicturePath,
    );
  }
}

class IdentityManager {
  static final IdentityManager _instance = IdentityManager._internal();
  factory IdentityManager() => _instance;
  IdentityManager._internal();

  final _secureStorage = const FlutterSecureStorage();
  static const String _identitiesKey = 'user_identities';
  static const String _currentIdentityKey = 'current_identity_id';

  /// Get all stored identities
  Future<List<Identity>> getAllIdentities() async {
    final identitiesJson = await _secureStorage.read(key: _identitiesKey);
    if (identitiesJson == null) return [];

    final List<dynamic> decoded = jsonDecode(identitiesJson);
    return decoded.map((json) => Identity.fromJson(json)).toList();
  }

  /// Add a new identity
  Future<void> addIdentity(String name, String seedPhrase) async {
    final identities = await getAllIdentities();
    
    final newIdentity = Identity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      seedPhrase: seedPhrase,
      createdAt: DateTime.now(),
    );

    identities.add(newIdentity);
    await _saveIdentities(identities);
    
    // Set as current identity if it's the first one
    if (identities.length == 1) {
      await setCurrentIdentity(newIdentity.id);
    }
  }

  /// Save identities list
  Future<void> _saveIdentities(List<Identity> identities) async {
    final encoded = jsonEncode(identities.map((i) => i.toJson()).toList());
    await _secureStorage.write(key: _identitiesKey, value: encoded);
  }

  /// Get current identity
  Future<Identity?> getCurrentIdentity() async {
    final currentId = await _secureStorage.read(key: _currentIdentityKey);
    if (currentId == null) return null;

    final identities = await getAllIdentities();
    try {
      return identities.firstWhere((i) => i.id == currentId);
    } catch (e) {
      return null;
    }
  }

  /// Set current identity
  Future<void> setCurrentIdentity(String identityId) async {
    await _secureStorage.write(key: _currentIdentityKey, value: identityId);
  }

  /// Update identity
  Future<void> updateIdentity(Identity updatedIdentity) async {
    final identities = await getAllIdentities();
    final index = identities.indexWhere((i) => i.id == updatedIdentity.id);
    
    if (index != -1) {
      identities[index] = updatedIdentity;
      await _saveIdentities(identities);
    }
  }

  /// Check if any identity exists
  Future<bool> hasIdentities() async {
    final identities = await getAllIdentities();
    return identities.isNotEmpty;
  }

  /// Delete an identity
  Future<void> deleteIdentity(String identityId) async {
    final identities = await getAllIdentities();
    identities.removeWhere((i) => i.id == identityId);
    await _saveIdentities(identities);

    // If deleted current identity, clear it
    final currentId = await _secureStorage.read(key: _currentIdentityKey);
    if (currentId == identityId) {
      await _secureStorage.delete(key: _currentIdentityKey);
      
      // Set first identity as current if any exist
      if (identities.isNotEmpty) {
        await setCurrentIdentity(identities.first.id);
      }
    }
  }

  /// Logout (clear current identity)
  Future<void> logout() async {
    await _secureStorage.delete(key: _currentIdentityKey);
  }

  /// Clear all identities
  Future<void> clearAll() async {
    await _secureStorage.delete(key: _identitiesKey);
    await _secureStorage.delete(key: _currentIdentityKey);
  }
}