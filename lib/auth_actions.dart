import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

Future<void> confirmSignOut(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (dc) => AlertDialog(
      backgroundColor: Colors.white,
      title: const Text('Sign out?'),
      content: const Text("You'll need to log in again to place or track orders."),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dc, false),
          child: const Text('Cancel', style: TextStyle(color: Colors.black)),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dc, true),
          child: const Text('Sign out'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;

  final rootNav = Navigator.of(context, rootNavigator: true);
  showDialog(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => const Center(
      child: SizedBox(
        width: 64, height: 64,
        child: Card(
          color: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
          ),
        ),
      ),
    ),
  );

  await FirebaseAuth.instance.signOut();
  rootNav.pop(); // dismiss the loading dialog; the auth-state listener swaps to LoginPage underneath
}