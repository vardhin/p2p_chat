import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class Peer {
  final String id;
  final String identityId; // Links peer to specific identity
  final String name;
  final String ipAddress;
  final int port;
  final String publicKey;
  final bool useLocalIP;
  final DateTime addedAt;
  final DateTime? lastSeenAt;

  Peer({
    required this.id,
    required this.identityId,
    required this.name,
    required this.ipAddress,
    required this.port,
    required this.publicKey,
    required this.useLocalIP,
    required this.addedAt,
    this.lastSeenAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'identity_id': identityId,
    'name': name,
    'ip_address': ipAddress,
    'port': port,
    'public_key': publicKey,
    'use_local_ip': useLocalIP,
    'added_at': addedAt.toIso8601String(),
    'last_seen_at': lastSeenAt?.toIso8601String(),
  };

  factory Peer.fromJson(Map<String, dynamic> json) => Peer(
    id: json['id'],
    identityId: json['identity_id'],
    name: json['name'],
    ipAddress: json['ip_address'],
    port: json['port'],
    publicKey: json['public_key'],
    useLocalIP: json['use_local_ip'],
    addedAt: DateTime.parse(json['added_at']),
    lastSeenAt: json['last_seen_at'] != null 
        ? DateTime.parse(json['last_seen_at']) 
        : null,
  );

  Peer copyWith({
    String? name,
    String? ipAddress,
    int? port,
    String? publicKey,
    bool? useLocalIP,
    DateTime? lastSeenAt,
  }) {
    return Peer(
      id: id,
      identityId: identityId,
      name: name ?? this.name,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      publicKey: publicKey ?? this.publicKey,
      useLocalIP: useLocalIP ?? this.useLocalIP,
      addedAt: addedAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }
}

class PeerManager {
  static final PeerManager _instance = PeerManager._internal();
  factory PeerManager() => _instance;
  PeerManager._internal();

  final _secureStorage = const FlutterSecureStorage();
  static const String _peersKey = 'user_peers';

  /// Get all peers across all identities
  Future<List<Peer>> _getAllPeers() async {
    final peersJson = await _secureStorage.read(key: _peersKey);
    if (peersJson == null) return [];

    final List<dynamic> decoded = jsonDecode(peersJson);
    return decoded.map((json) => Peer.fromJson(json)).toList();
  }

  /// Save all peers
  Future<void> _savePeers(List<Peer> peers) async {
    final encoded = jsonEncode(peers.map((p) => p.toJson()).toList());
    await _secureStorage.write(key: _peersKey, value: encoded);
  }

  /// Get peers for a specific identity
  Future<List<Peer>> getPeersForIdentity(String identityId) async {
    final allPeers = await _getAllPeers();
    return allPeers.where((p) => p.identityId == identityId).toList();
  }

  /// Add a new peer for an identity
  Future<void> addPeer({
    required String identityId,
    required String name,
    required String ipAddress,
    required int port,
    required String publicKey,
    required bool useLocalIP,
  }) async {
    final peers = await _getAllPeers();
    
    final newPeer = Peer(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      identityId: identityId,
      name: name,
      ipAddress: ipAddress,
      port: port,
      publicKey: publicKey,
      useLocalIP: useLocalIP,
      addedAt: DateTime.now(),
    );

    peers.add(newPeer);
    await _savePeers(peers);
  }

  /// Update a peer
  Future<void> updatePeer(Peer updatedPeer) async {
    final peers = await _getAllPeers();
    final index = peers.indexWhere((p) => p.id == updatedPeer.id);
    
    if (index != -1) {
      peers[index] = updatedPeer;
      await _savePeers(peers);
    }
  }

  /// Update last seen time for a peer
  Future<void> updateLastSeen(String peerId) async {
    final peers = await _getAllPeers();
    final index = peers.indexWhere((p) => p.id == peerId);
    
    if (index != -1) {
      peers[index] = peers[index].copyWith(lastSeenAt: DateTime.now());
      await _savePeers(peers);
    }
  }

  /// Delete a peer
  Future<void> deletePeer(String peerId) async {
    final peers = await _getAllPeers();
    peers.removeWhere((p) => p.id == peerId);
    await _savePeers(peers);
  }

  /// Delete all peers for a specific identity
  Future<void> deletePeersForIdentity(String identityId) async {
    final peers = await _getAllPeers();
    peers.removeWhere((p) => p.identityId == identityId);
    await _savePeers(peers);
  }

  /// Get a specific peer by ID
  Future<Peer?> getPeerById(String peerId) async {
    final peers = await _getAllPeers();
    try {
      return peers.firstWhere((p) => p.id == peerId);
    } catch (e) {
      return null;
    }
  }

  /// Check if a peer exists for an identity
  Future<bool> hasPeers(String identityId) async {
    final peers = await getPeersForIdentity(identityId);
    return peers.isNotEmpty;
  }

  /// Clear all peers
  Future<void> clearAll() async {
    await _secureStorage.delete(key: _peersKey);
  }
}