import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'admin.dart';
import 'customer.dart';
import 'loading_page.dart';

class RoleRouter extends StatelessWidget {
  final String uid;
  const RoleRouter({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const LoadingPage(message: 'Loading your account...');
        }
        if (snap.hasError) {
          return Scaffold(
            body: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Could not load profile:\n${snap.error}',
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                OutlinedButton(
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    child: const Text('Sign out')),
              ]),
            ),
          );
        }
        final role = snap.data?.data()?['role'];
        return role == 'admin' ? const AdminShell() : const CustomerShell();
      },
    );
  }
}
