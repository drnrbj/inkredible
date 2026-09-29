import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Future<void> register(String name, String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    await cred.user!.updateDisplayName(name);
    await _createProfile(cred.user!, name);
  }

  Future<void> login(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<void> signInWithGoogle() async {
    final cred = await _auth.signInWithProvider(GoogleAuthProvider());
    if (cred.additionalUserInfo?.isNewUser ?? false) {
      await _createProfile(cred.user!, cred.user!.displayName ?? '');
    }
  }

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<void> _createProfile(User u, String name) =>
      _db.collection('users').doc(u.uid).set({
        'name': name,
        'email': u.email,
        'role': 'customer', // promote admins manually in the console
        'createdAt': FieldValue.serverTimestamp(),
      });

  static String message(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          return 'Incorrect email or password.';
        case 'email-already-in-use':
          return 'That email is already registered. Try logging in.';
        case 'weak-password':
          return 'Password must be at least 6 characters.';
        case 'invalid-email':
          return 'Enter a valid email address.';
        case 'network-request-failed':
          return 'No internet connection.';
        case 'too-many-requests':
          return 'Too many attempts. Try again later.';
        case 'canceled':
        case 'web-context-canceled':
          return '';
      }
      return e.message ?? 'Something went wrong.';
    }
    return 'Something went wrong. Please try again.';
  }
}