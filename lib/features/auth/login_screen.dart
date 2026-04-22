import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/i18n_service.dart';
import 'widgets/google_sign_in_button.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../hub/hub_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _showPass = false;
  bool _loading = false;
  String? _error;
  StreamSubscription<GoogleSignInAccount?>? _googleSub;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _googleSub = AuthService().googleSignIn.onCurrentUserChanged.listen(_onGoogleUser);
      AuthService().googleSignIn.signInSilently();
    }
  }

  Future<void> _onGoogleUser(GoogleSignInAccount? user) async {
    if (user == null || !mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService().loginWithGoogleAccount(user, I18nService.currentLang);
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HubScreen()));
      }
    } catch (_) {
      if (mounted) setState(() { _error = I18nService.t('auth.googleFailed'); _loading = false; });
    }
  }

  @override
  void dispose() {
    _googleSub?.cancel();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _googleLogin() async {
    if (_loading) return;
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService().loginWithGoogle(I18nService.currentLang);
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HubScreen()));
      }
    } catch (_) {
      setState(() { _error = I18nService.t('auth.googleFailed'); _loading = false; });
    }
  }

  Future<void> _login() async {
    if (_loading) return;
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService().login(_emailCtrl.text.trim(), _passCtrl.text);
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HubScreen()));
      }
    } catch (_) {
      setState(() { _error = I18nService.t('auth.invalidCredentials'); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text('GatherHype', style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              )),
              const SizedBox(height: 8),
              Text(I18nService.t('auth.welcomeBack'), style: theme.textTheme.titleMedium),
              const SizedBox(height: 36),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: I18nService.t('auth.email')),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passCtrl,
                obscureText: !_showPass,
                onSubmitted: (_) => _login(),
                decoration: InputDecoration(
                  labelText: I18nService.t('auth.password'),
                  suffixIcon: IconButton(
                    icon: Icon(_showPass ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _showPass = !_showPass),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                  child: Text(I18nService.t('auth.forgotPassword')),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _loading ? null : _login,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(I18nService.t('auth.logIn')),
              ),
              const SizedBox(height: 12),
              if (kIsWeb)
                buildGoogleSignInButton()
              else
                OutlinedButton.icon(
                  onPressed: _loading ? null : _googleLogin,
                  icon: const Icon(Icons.g_mobiledata, size: 22),
                  label: Text(I18nService.t('auth.continueWithGoogle')),
                ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(I18nService.t('auth.noAccount')),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: Text(I18nService.t('auth.signUp')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
