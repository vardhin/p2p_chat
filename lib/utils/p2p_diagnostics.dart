import 'dart:io';
import 'dart:async';
import 'dart:convert' show utf8;
import 'package:p2p_chat/src/rust/api/network.dart';
import 'package:p2p_chat/utils/peer_manager.dart';

/// P2P Connection Diagnostics - Tests IPv4/IPv6 connectivity and hole punching
class P2PConnectionDiagnostics {
  /// Check if local IPv4 is available
  static bool hasLocalIPv4(NetworkInfo networkInfo) {
    return networkInfo.localIpv4 != null && networkInfo.localIpv4!.isNotEmpty;
  }

  /// Check if local IPv6 is available
  static bool hasLocalIPv6(NetworkInfo networkInfo) {
    return networkInfo.localIpv6 != null && networkInfo.localIpv6!.isNotEmpty;
  }

  /// Check if peers are on the same subnet (for local direct connection)
  static bool areOnSameSubnet({
    required String localIp,
    required String peerIp,
    required String subnetMask,
  }) {
    try {
      // Use Rust function to check if on same subnet
      return areOnSameLANSubnet(ip1: localIp, ip2: peerIp, subnetMask: subnetMask);
    } catch (e) {
      print('Error checking subnet: $e');
      return false;
    }
  }

  /// Test UDP connectivity to a specific peer
  static Future<bool> testUDPConnectivity({
    required String peerIp,
    required int peerPort,
    int timeoutSeconds = 5,
  }) async {
    try {
      // Create UDP socket
      final socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
      );

      // Send test packet
      final testData = utf8.encode('PING');
      socket.send(
        testData,
        InternetAddress(peerIp),
        peerPort,
      );

      // Wait for response with timeout
      Completer<bool> completer = Completer();
      
      late StreamSubscription subscription;
      subscription = socket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          try {
            final datagram = socket.receive();
            if (datagram != null) {
              completer.complete(true);
              subscription.cancel();
              socket.close();
            }
          } catch (e) {
            print('Error receiving UDP response: $e');
          }
        }
      });

      // Timeout handling
      Future.delayed(Duration(seconds: timeoutSeconds)).then((_) {
        if (!completer.isCompleted) {
          completer.complete(false);
          subscription.cancel();
          socket.close();
        }
      });

      return await completer.future;
    } catch (e) {
      print('Error testing UDP connectivity: $e');
      return false;
    }
  }

  /// Perform hole punching to establish connection
  static Future<bool> performHolePunching({
    required String peerIp,
    required int peerPort,
    int maxAttempts = 5,
    int delayMs = 100,
  }) async {
    try {
      final socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
      );

      print('[HOLE PUNCH] Starting UDP hole punching to $peerIp:$peerPort');
      print('[HOLE PUNCH] Local port: ${socket.address.address}');

      for (int i = 0; i < maxAttempts; i++) {
        try {
          final punchData = utf8.encode('PUNCH:$i');
          socket.send(
            punchData,
            InternetAddress(peerIp),
            peerPort,
          );
          print('[HOLE PUNCH] Attempt ${i + 1}/$maxAttempts sent');

          await Future.delayed(Duration(milliseconds: delayMs));
        } catch (e) {
          print('[HOLE PUNCH] Attempt ${i + 1} failed: $e');
        }
      }

      socket.close();
      print('[HOLE PUNCH] Hole punching completed');
      return true;
    } catch (e) {
      print('[HOLE PUNCH] Error during hole punching: $e');
      return false;
    }
  }

  /// Generate diagnostics report for a peer connection
  static Future<String> generateDiagnosticsReport({
    required Peer peer,
    required NetworkInfo localNetworkInfo,
  }) async {
    final report = StringBuffer();
    report.writeln('=== P2P Connection Diagnostics Report ===\n');

    // Local Network Info
    report.writeln('Local Network Configuration:');
    report.writeln('  IPv4: ${localNetworkInfo.localIpv4 ?? "Not available"}');
    report.writeln('  IPv6: ${localNetworkInfo.localIpv6 ?? "Not available"}');
    report.writeln('  Subnet Mask: ${localNetworkInfo.subnetMask ?? "Not available"}');
    report.writeln('  Gateway: ${localNetworkInfo.gateway ?? "Not available"}');
    report.writeln('');

    // Peer Information
    report.writeln('Peer Information:');
    report.writeln('  Peer ID: ${peer.id}');
    report.writeln('  Peer Name: ${peer.name}');
    report.writeln('  Peer IP: ${peer.ipAddress}');
    report.writeln('  Peer Port: ${peer.port}');
    report.writeln('  Use Local IP: ${peer.useLocalIP}');
    report.writeln('');

    // Connection Checks
    report.writeln('Connection Checks:');

    // Check if IPv4 is available
    final hasIPv4 = hasLocalIPv4(localNetworkInfo);
    report.writeln('  ✓ IPv4 Available: $hasIPv4');

    // Check if IPv6 is available
    final hasIPv6 = hasLocalIPv6(localNetworkInfo);
    report.writeln('  ✓ IPv6 Available: $hasIPv6');

    // Check subnet
    bool sameSubnet = false;
    if (hasIPv4 && localNetworkInfo.subnetMask != null) {
      sameSubnet = areOnSameSubnet(
        localIp: localNetworkInfo.localIpv4!,
        peerIp: peer.ipAddress,
        subnetMask: localNetworkInfo.subnetMask!,
      );
      report.writeln('  ✓ Same Subnet: $sameSubnet');
    }

    // Test UDP connectivity
    report.writeln('');
    report.writeln('Testing UDP Connectivity...');
    final udpConnectivity = await testUDPConnectivity(
      peerIp: peer.ipAddress,
      peerPort: peer.port,
      timeoutSeconds: 3,
    );
    report.writeln('  ✓ UDP Connectivity: $udpConnectivity');

    // Recommendation
    report.writeln('');
    report.writeln('Connection Strategy:');
    if (sameSubnet && hasIPv4) {
      report.writeln('  → Use LOCAL IPv4 for direct LAN connection');
      report.writeln('  → Hole punching: Required for NAT traversal');
    } else if (hasIPv4) {
      report.writeln('  → Attempting GLOBAL IPv4 connection');
      report.writeln('  → Hole punching: Recommended');
    } else if (hasIPv6) {
      report.writeln('  → Attempting IPv6 connection');
      report.writeln('  → Hole punching: May not be needed for IPv6');
    } else {
      report.writeln('  → ⚠️ No suitable connection method found!');
    }

    return report.toString();
  }
}
