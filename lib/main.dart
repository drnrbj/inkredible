import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inkredible/data/data.dart';
import 'package:inkredible/customer/customer.dart';
import 'package:inkredible/admin/admin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:inkredible/auth/auth_gate.dart';
import 'package:inkredible/auth/login_page.dart';
import 'package:inkredible/services/push_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await PushNotifications.init();
  runApp(MultiProvider(
    providers: [ChangeNotifierProvider(create: (_) => ShopStore())],
    child: const InkredibleApp(),
  ));
}

ThemeData buildTheme() {
  const black = Color(0xFF0A0A0A);
  const border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(color: Colors.black26),
  );
  final btnShape =
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
  return ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: black,
      onPrimary: Colors.white,
      secondary: black,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: black,
      error: Color(0xFF444444),
      outline: Colors.black26,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: black,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
          color: black,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: 2),
    ),
    dividerColor: Colors.black12,
    inputDecorationTheme: const InputDecorationTheme(
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: black, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: black,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 52),
        shape: btnShape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: black,
        minimumSize: const Size(0, 52),
        side: const BorderSide(color: black),
        shape: btnShape,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: black,
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
          color: s.contains(WidgetState.selected) ? Colors.white : black)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? black : Colors.white),
        foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? Colors.white : black),
      ),
    ),
    chipTheme: const ChipThemeData(
      selectedColor: black,
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.black26),
      showCheckmark: false,
    ),
  );
}

class InkredibleApp extends StatelessWidget {
  const InkredibleApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inkredible',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          if (snap.data == null) return const LoginPage();
          PushNotifications.syncToken();
          return RoleRouter(uid: snap.data!.uid);
        },
      ),
    );
  }
}

class RoleSelectPage extends StatelessWidget {
  const RoleSelectPage({super.key});
  @override
  Widget build(BuildContext context) {
    final session = context.read<Session>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(Icons.print_outlined, size: 48),
              const SizedBox(height: 16),
              const Text('INKREDIBLE',
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4)),
              const SizedBox(height: 8),
              const Spacer(),
              FilledButton(
                  onPressed: () => session.set(Role.customer),
                  child: const Text('Continue as Customer')),
              const SizedBox(height: 12),
              OutlinedButton(
                  onPressed: () => session.set(Role.admin),
                  child: const Text('Shop Owner / Staff')),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
