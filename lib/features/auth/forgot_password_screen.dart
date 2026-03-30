import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';

// ──────────────────────────────────────────────
//  FORGOT PASSWORD
// ──────────────────────────────────────────────
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  Future<void> _submit() async {
    if (_loading) return;
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService().forgotPassword(_emailCtrl.text.trim());
      setState(() { _sent = true; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Something went wrong. Try again.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot password')),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: _sent
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
                  const SizedBox(height: 16),
                  const Text('Check your email for a reset code.', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResetPasswordScreen())),
                    child: const Text('Enter reset code'),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Enter your email and we\'ll send you a reset code.'),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Send reset code'),
                  ),
                ],
              ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
//  RESET PASSWORD
// ──────────────────────────────────────────────
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _done = false;
  String? _error;

  Future<void> _submit() async {
    if (_loading) return;
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService().resetPassword(_emailCtrl.text.trim(), _codeCtrl.text.trim(), _passCtrl.text);
      setState(() { _done = true; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Invalid code or expired. Try again.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: _done
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
                  const SizedBox(height: 16),
                  const Text('Password updated! You can now log in.', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                    child: const Text('Back to login'),
                  ),
                ],
              )
            : Column(
                children: [
                  TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
                  const SizedBox(height: 14),
                  TextField(controller: _codeCtrl, decoration: const InputDecoration(labelText: 'Reset code')),
                  const SizedBox(height: 14),
                  TextField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'New password')),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Reset password'),
                  ),
                ],
              ),
      ),
    );
  }
}
