import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../hub/hub_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _showPass = false;
  bool _loading = false;
  String? _error;
  String _strength = '';

  void _checkStrength(String p) {
    if (p.length < 6) { setState(() => _strength = 'Weak'); return; }
    final score = [RegExp(r'[a-zA-Z]').hasMatch(p), RegExp(r'\d').hasMatch(p), RegExp(r'[^a-zA-Z0-9]').hasMatch(p)].where((b) => b).length;
    setState(() => _strength = score == 3 ? 'Strong' : score == 2 ? 'Medium' : 'Weak');
  }

  Color get _strengthColor => _strength == 'Strong' ? Colors.green : _strength == 'Medium' ? Colors.orange : Colors.red;

  Future<void> _register() async {
    if (_loading) return;
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService().register(_emailCtrl.text.trim(), _passCtrl.text, 'en');
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HubScreen()));
    } catch (_) {
      setState(() { _error = 'Registration failed. Try a different email.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('GatherHype', style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              )),
              const SizedBox(height: 8),
              Text('Save & organize your links', style: theme.textTheme.titleMedium),
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
                onChanged: _checkStrength,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(_showPass ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _showPass = !_showPass),
                  ),
                ),
              ),
              if (_strength.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('Password strength: $_strength', style: TextStyle(color: _strengthColor, fontSize: 12)),
              ],
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Create account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
