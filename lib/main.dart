import 'package:flutter/material.dart';
import 'package:p2p_chat/screens/identity_selection_screen.dart';
import 'package:p2p_chat/screens/chat_screen.dart';
import 'package:p2p_chat/widgets/pin_lock_screen.dart';
import 'package:p2p_chat/src/rust/frb_generated.dart';
import 'package:p2p_chat/utils/identity_manager.dart';
import 'package:p2p_chat/utils/pin_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: const AppInitializer(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _hasIdentities = false;
  bool _hasCurrentIdentity = false;
  bool _needsUnlock = false;
  bool _isShowingLockScreen = false;
  final _identityManager = IdentityManager();
  final _pinManager = PinManager();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkIdentity();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _lockApp();
    }
  }

  Future<void> _lockApp() async {
    if (_isShowingLockScreen) return;
    
    final autoLockEnabled = await _pinManager.isAutoLockEnabled();
    if (autoLockEnabled && _hasCurrentIdentity && mounted) {
      setState(() => _needsUnlock = true);
    }
  }

  Future<void> _checkIdentity() async {
    final hasIdentities = await _identityManager.hasIdentities();
    final currentIdentity = await _identityManager.getCurrentIdentity();
    final autoLockEnabled = await _pinManager.isAutoLockEnabled();
    
    setState(() {
      _hasIdentities = hasIdentities;
      _hasCurrentIdentity = currentIdentity != null;
      _needsUnlock = currentIdentity != null && autoLockEnabled;
      _isLoading = false;
    });
  }

  Future<void> _handleUnlock() async {
    if (_isShowingLockScreen) return;
    
    _isShowingLockScreen = true;
    
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const PinLockScreen(),
        fullscreenDialog: true,
      ),
    );
    
    _isShowingLockScreen = false;
    
    if (result == true) {
      setState(() => _needsUnlock = false);
    } else {
      setState(() => _needsUnlock = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_needsUnlock && !_isShowingLockScreen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _needsUnlock && !_isShowingLockScreen) {
          _handleUnlock();
        }
      });
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 80, color: Colors.deepPurple),
              SizedBox(height: 20),
              Text('App Locked', style: TextStyle(fontSize: 24)),
            ],
          ),
        ),
      );
    }

    if (_hasCurrentIdentity) {
      return const AppWithLifecycle();
    }

    return const IdentitySelectionScreen();
  }
}

class AppWithLifecycle extends StatefulWidget {
  const AppWithLifecycle({super.key});

  @override
  State<AppWithLifecycle> createState() => _AppWithLifecycleState();
}

class _AppWithLifecycleState extends State<AppWithLifecycle> with WidgetsBindingObserver {
  final _pinManager = PinManager();
  bool _isLockScreenShowing = false;
  bool _isInBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _isInBackground = true;
    }
    
    if (state == AppLifecycleState.resumed && _isInBackground) {
      _isInBackground = false;
      _lockApp();
    }
  }

  Future<void> _lockApp() async {
    if (_isLockScreenShowing) return;
    
    final autoLockEnabled = await _pinManager.isAutoLockEnabled();
    if (autoLockEnabled && mounted) {
      _isLockScreenShowing = true;
      
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => const PinLockScreen(),
          fullscreenDialog: true,
        ),
      );
      
      _isLockScreenShowing = false;
      
      if (result != true && mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (!_isLockScreenShowing) {
          _lockApp();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const ChatScreen();
  }
}
