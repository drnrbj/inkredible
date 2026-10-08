import 'package:flutter/material.dart';

class LoadingPage extends StatefulWidget {
  final String message;
  const LoadingPage({super.key, this.message = 'Setting things up...'});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 84,
              height: 84,
              child: Stack(alignment: Alignment.center, children: [
                RotationTransition(
                  turns: _ctl,
                  child: CustomPaint(
                    size: const Size(84, 84),
                    painter: _DashPainter(),
                  ),
                ),
                const Icon(Icons.print_outlined, size: 34, color: Colors.black),
              ]),
            ),
            const SizedBox(height: 28),
            const Text('INKREDIBLE',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 4)),
            const SizedBox(height: 8),
            Text(widget.message,
                style: const TextStyle(color: Colors.black54, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(1);
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 4.9, false, paint); // ~280° arc, ~80° gap
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}