import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'auth_actions.dart';
import 'widgets.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isGoogle = user?.providerData.any((p) => p.providerId == 'google.com') ?? false;
    final joined = user?.metadata.creationTime;
    return ListView(padding: const EdgeInsets.all(20), children: [
      Center(
        child: Column(children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.black,
            backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
            child: user?.photoURL == null
                ? Text((user?.displayName?.isNotEmpty == true ? user!.displayName![0] : 'U').toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800))
                : null,
          ),
          const SizedBox(height: 12),
          Text(user?.displayName?.isNotEmpty == true ? user!.displayName! : 'Customer',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          Text(user?.email ?? '', style: const TextStyle(color: Colors.black54)),
        ]),
      ),
      const SizedBox(height: 28),
      AppCard(
        child: Column(children: [
          KV('Signed in with', isGoogle ? 'Google' : 'Email & password'),
          KV('Member since', joined != null ? DateFormat('MMM d, y').format(joined) : '—'),
        ]),
      ),
      const SizedBox(height: 28),
      OutlinedButton.icon(
        onPressed: () => confirmSignOut(context),
        icon: const Icon(Icons.logout),
        label: const Text('Sign out'),
      ),
    ]);
  }
}