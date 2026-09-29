import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'logo.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = AuthService();
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool register = false, busy = false, hide = true;
  String? error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
      // On success, the auth gate in main.dart switches screens automatically.
    } catch (e) {
      final m = AuthService.message(e);
      if (mounted) setState(() => error = m.isEmpty ? null : m);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    final email = _email.text.trim();
    final pass = _password.text;
    _run(() => register
        ? _auth.register(_name.text.trim(), email, pass)
        : _auth.login(email, pass));
  }

  Future<void> _forgot() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => error = 'Enter your email above first.');
      return;
    }
    await _run(() => _auth.resetPassword(email));
    if (mounted && error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: InkredibleLockup()),
                  const SizedBox(height: 20),
                  Text(register ? 'Create your account' : 'Welcome back',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 32),
                  if (register) ...[
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Full name'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter your name'
                          : null,
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'Enter a valid email'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _password,
                    obscureText: hide,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                            hide ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => hide = !hide),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6)
                        ? 'At least 6 characters'
                        : null,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  if (!register)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: busy ? null : _forgot,
                        child: const Text('Forgot password?',
                            style: TextStyle(color: Colors.black)),
                      ),
                    ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: busy ? null : _submit,
                    child: busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(register ? 'Create account' : 'Log in'),
                  ),
                  const SizedBox(height: 20),
                  Row(children: const [
                    Expanded(child: Divider()),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or',
                            style: TextStyle(color: Colors.black54))),
                    Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: busy ? null : () => _run(_auth.signInWithGoogle),
                    icon: const Icon(Icons.g_mobiledata, size: 32),
                    label: const Text('Continue with Google'),
                  ),
                  const SizedBox(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(register
                        ? 'Already have an account?'
                        : "Don't have an account?"),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => setState(() {
                                register = !register;
                                error = null;
                              }),
                      child: Text(register ? 'Log in' : 'Register',
                          style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w800)),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
