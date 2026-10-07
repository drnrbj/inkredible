import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'auth_actions.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});
  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool saving = false;

  Future<void> _editName(User user) async {
    final ctl = TextEditingController(text: user.displayName ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (dc) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Edit name'),
        content: TextField(
          controller: ctl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Full name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dc),
            child: const Text('Cancel', style: TextStyle(color: Colors.black)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dc, ctl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || name == user.displayName) return;

    setState(() => saving = true);
    try {
      await user.updateDisplayName(name);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'name': name}, SetOptions(merge: true));
      await user.reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not update name: $e')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();
    final name = user.displayName?.isNotEmpty == true ? user.displayName! : 'Customer';

    return ListView(padding: const EdgeInsets.all(20), children: [
      Center(
        child: Column(children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.black,
            backgroundImage:
                user.photoURL != null ? NetworkImage(user.photoURL!) : null,
            child: user.photoURL == null
                ? Text(name[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800))
                : null,
          ),
          const SizedBox(height: 14),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(width: 6),
            InkWell(
              onTap: saving ? null : () => _editName(user),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: saving
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.edit_outlined, size: 18, color: Colors.black54),
              ),
            ),
          ]),
          Text(user.email ?? '', style: const TextStyle(color: Colors.black54)),
        ]),
      ),
      const SizedBox(height: 32),
      OutlinedButton.icon(
        onPressed: () => confirmSignOut(context),
        icon: const Icon(Icons.logout),
        label: const Text('Sign out'),
      ),
    ]);
  }
}