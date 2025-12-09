import 'package:flutter/material.dart';
import 'package:p2p_chat/screens/identity_setup_screen.dart';
import 'package:p2p_chat/src/rust/frb_generated.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'P2P Secure Chat',
      theme: ThemeData.dark(),
      home: const IdentitySetupScreen(),
    );
  }
}
