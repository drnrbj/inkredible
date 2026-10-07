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
  final _confirm = TextEditingController();
  bool register = false, busy = false, hide = true, hideConfirm = true;
  String? error;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
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
    if (!_emailRegex.hasMatch(email)) {
      setState(() => error = 'Enter your email above first.');
      return;
    }
    await _run(() => _auth.resetPassword(email));
    if (mounted && error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent')));
    }
  }

  void _toggleMode() {
    setState(() {
      register = !register;
      error = null;
      _confirm.clear();
      hideConfirm = true;
    });
    _form.currentState?.reset();
  }

  InputDecoration _decoration(String label, IconData icon, {Widget? suffix}) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 22),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.black.withOpacity(0.04),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: border(Colors.transparent),
      enabledBorder: border(Colors.transparent),
      focusedBorder: border(Colors.black, 1.6),
      errorBorder: border(Colors.red.shade400),
      focusedErrorBorder: border(Colors.red.shade400, 1.6),
      floatingLabelStyle: const TextStyle(color: Colors.black),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: InkredibleLockup()),
                    const SizedBox(height: 24),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Column(
                        key: ValueKey(register),
                        children: [
                          Text(
                            register ? 'Create your account' : 'Welcome back',
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            register
                                ? 'Sign up to start ordering'
                                : 'Log in to continue',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Full name (register only)
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      alignment: Alignment.topCenter,
                      child: register
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: TextFormField(
                                controller: _name,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.name],
                                decoration: _decoration(
                                    'Full name', Icons.person_outline),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Enter your name'
                                        : null,
                              ),
                            )
                          : const SizedBox(width: double.infinity),
                    ),

                    // Email
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration:
                          _decoration('Email', Icons.mail_outline_rounded),
                      validator: (v) =>
                          (v == null || !_emailRegex.hasMatch(v.trim()))
                              ? 'Enter a valid email'
                              : null,
                    ),
                    const SizedBox(height: 14),

                    // Password
                    TextFormField(
                      controller: _password,
                      obscureText: hide,
                      textInputAction:
                          register ? TextInputAction.next : TextInputAction.done,
                      autofillHints: [
                        register
                            ? AutofillHints.newPassword
                            : AutofillHints.password
                      ],
                      decoration: _decoration(
                        'Password',
                        Icons.lock_outline_rounded,
                        suffix: IconButton(
                          icon: Icon(hide
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () => setState(() => hide = !hide),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'At least 6 characters'
                          : null,
                      onFieldSubmitted: (_) {
                        if (!register) _submit();
                      },
                    ),

                    // Confirm password (register only)
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      alignment: Alignment.topCenter,
                      child: register
                          ? Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: TextFormField(
                                controller: _confirm,
                                obscureText: hideConfirm,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [
                                  AutofillHints.newPassword
                                ],
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                decoration: _decoration(
                                  'Confirm password',
                                  Icons.lock_reset_rounded,
                                  suffix: IconButton(
                                    icon: Icon(hideConfirm
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined),
                                    onPressed: () => setState(
                                        () => hideConfirm = !hideConfirm),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Confirm your password';
                                  }
                                  if (v != _password.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) => _submit(),
                              ),
                            )
                          : const SizedBox(width: double.infinity),
                    ),

                    if (!register)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: busy ? null : _forgot,
                          child: const Text('Forgot password?',
                              style: TextStyle(color: Colors.black)),
                        ),
                      )
                    else
                      const SizedBox(height: 8),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 18, color: Colors.red.shade400),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(error!,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red.shade400)),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: busy ? null : _submit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(register ? 'Create account' : 'Log in',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
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
                    OutlinedButton(
                      onPressed:
                          busy ? null : () => _run(_auth.signInWithGoogle),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        foregroundColor: Colors.black87,
                        side: BorderSide(color: Colors.black.withOpacity(0.18)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          GoogleLogo(size: 22),
                          SizedBox(width: 12),
                          Text('Continue with Google',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(register
                              ? 'Already have an account?'
                              : "Don't have an account?"),
                          TextButton(
                            onPressed: busy ? null : _toggleMode,
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
      ),
    );
  }
}

/// Multicolor Google "G", drawn in code (no asset needed).
class GoogleLogo extends StatelessWidget {
  final double size;
  const GoogleLogo({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _GoogleLogoPainter());
}

class _GoogleLogoPainter extends CustomPainter {
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);
  static const _blue = Color(0xFF4285F4);

  double _rad(double deg) => deg * 3.1415926535 / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = s * 0.2;
    final center = Offset(s / 2, s / 2);
    final rect = Rect.fromCircle(center: center, radius: s / 2 - stroke / 2);

    Paint p(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    canvas.drawArc(rect, _rad(-150), _rad(100), false, p(_red));
    canvas.drawArc(rect, _rad(150), _rad(60), false, p(_yellow));
    canvas.drawArc(rect, _rad(30), _rad(120), false, p(_green));
    canvas.drawArc(rect, _rad(0), _rad(30), false, p(_blue));

    // Blue horizontal bar of the "G"
    canvas.drawRect(
      Rect.fromLTRB(s / 2, s / 2 - stroke / 2, s, s / 2 + stroke / 2),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}