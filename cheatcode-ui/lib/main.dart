import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'providers/app_provider.dart';
import 'screens/onboarding_screen.dart';
import 'screens/feed_screen.dart';
import 'theme/app_theme.dart';

void main() {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const CheatcodeApp());
}

class CheatcodeApp extends StatelessWidget {
  const CheatcodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        title: 'cheatcode()',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const _AppEntry(),
      ),
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  bool _checking = true;
  bool _hasSession = false;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final provider = context.read<AppProvider>();
    await provider.tryRestoreSession();
    if (mounted) {
      setState(() {
        _checking = false;
        _hasSession = provider.userId != null;
      });
    }
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: SizedBox.shrink());
    }
    return _hasSession ? const FeedScreen() : const OnboardingScreen();
  }
}