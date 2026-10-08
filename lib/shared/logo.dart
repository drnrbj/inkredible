import 'package:flutter/material.dart';

/// Black rounded badge: ink drop (the dot of the "i") over a paper sheet (the stem).
class InkredibleLogo extends StatelessWidget {
  final double size;
  final bool inverted; // true = white badge, black mark (for dark backgrounds)
  const InkredibleLogo({super.key, this.size = 64, this.inverted = false});

  @override
  Widget build(BuildContext context) {
    const black = Color(0xFF0A0A0A);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LogoPainter(
          bg: inverted ? Colors.white : black,
          fg: inverted ? black : Colors.white,
        ),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final Color bg, fg;
  _LogoPainter({required this.bg, required this.fg});

  @override
  void paint(Canvas c, Size size) {
    final s = size.width;
    final bgPaint = Paint()..color = bg;
    final fgPaint = Paint()..color = fg;

    // Badge
    c.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(s * 0.26)),
      bgPaint,
    );

    // Ink drop (the dot of the "i")
    final cx = s * 0.5, top = s * 0.14, r = s * 0.11, cy = s * 0.37;
    final ctrlY = top + (cy - top) * 0.55;
    final drop = Path()
      ..moveTo(cx, top)
      ..cubicTo(cx + r * 0.35, ctrlY, cx + r, cy - r * 0.5, cx + r, cy)
      ..arcToPoint(Offset(cx - r, cy),
          radius: Radius.circular(r), clockwise: true)
      ..cubicTo(cx - r, cy - r * 0.5, cx - r * 0.35, ctrlY, cx, top)
      ..close();
    c.drawPath(drop, fgPaint);

    // Paper sheet (the stem of the "i")
    final left = s * 0.37, right = s * 0.63;
    final pTop = s * 0.56, pBot = s * 0.86, cut = s * 0.08;
    c.drawRRect(
      RRect.fromLTRBR(left, pTop, right, pBot, Radius.circular(s * 0.03)),
      fgPaint,
    );
    // Cut the top-right corner...
    c.drawPath(
      Path()
        ..moveTo(right - cut, pTop - 1)
        ..lineTo(right + 1, pTop - 1)
        ..lineTo(right + 1, pTop + cut)
        ..close(),
      bgPaint,
    );
    // ...and draw the folded flap
    c.drawPath(
      Path()
        ..moveTo(right - cut, pTop)
        ..lineTo(right - cut, pTop + cut)
        ..lineTo(right, pTop + cut)
        ..close(),
      Paint()..color = fg.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.bg != bg || old.fg != fg;
}

/// Logo + wordmark (+ optional tagline), for login and loading screens.
class InkredibleLockup extends StatelessWidget {
  final double logoSize;
  final bool tagline;
  const InkredibleLockup({super.key, this.logoSize = 72, this.tagline = true});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Hero(tag: 'inkredible-logo', child: InkredibleLogo(size: logoSize)),
      const SizedBox(height: 18),
      const Text('INKREDIBLE',
          style: TextStyle(
              fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 6)),
      if (tagline) ...[
        const SizedBox(height: 6),
        const Text('Print smarter. Skip the line.',
            style: TextStyle(color: Colors.black54, fontSize: 14)),
      ],
    ]);
  }
}