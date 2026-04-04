import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/auth_service.dart';
import 'core/utils/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/hub/hub_screen.dart';

final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString('themeMode');
  if (saved == 'light') themeModeNotifier.value = ThemeMode.light;
  if (saved == 'dark') themeModeNotifier.value = ThemeMode.dark;
  runApp(const GatherHypeApp());
}

Future<void> toggleTheme() async {
  final next = themeModeNotifier.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  themeModeNotifier.value = next;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('themeMode', next == ThemeMode.dark ? 'dark' : 'light');
}

class GatherHypeApp extends StatelessWidget {
  const GatherHypeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (_, mode, __) => MaterialApp(
        title: 'G',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _checking = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final loggedIn = await AuthService().isLoggedIn();
    setState(() {
      _loggedIn = loggedIn;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _loggedIn ? const HubScreen() : const LoginScreen();
  }
}
