import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
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

  Future<void> _googleLogin() async {
    if (_loading) return;
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService().loginWithGoogle('en');
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HubScreen()));
      }
    } catch (_) {
      setState(() { _error = 'Google sign-in failed'; _loading = false; });
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
      setState(() { _error = 'Invalid email or password'; _loading = false; });
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
              Text('Welcome back', style: theme.textTheme.titleMedium),
              const SizedBox(height: 36),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passCtrl,
                obscureText: !_showPass,
                onSubmitted: (_) => _login(),
                decoration: InputDecoration(
                  labelText: 'Password',
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
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _loading ? null : _login,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Log In'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _loading ? null : _googleLogin,
                icon: const Icon(Icons.g_mobiledata, size: 22),
                label: const Text('Continue with Google'),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: const Text('Sign up'),
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
