import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// SVG-style Skwilti logo drawn with Flutter Canvas — matches the real logo.
class SkwiltiLogo extends StatelessWidget {
  final double height;
  final bool textOnly;
  final bool iconOnly;

  const SkwiltiLogo({super.key, this.height = 32, this.textOnly = false, this.iconOnly = false});

  @override
  Widget build(BuildContext context) {
    if (iconOnly) return _SkwiltiIcon(size: height);
    if (textOnly) return _SkwiltiText(fontSize: height * 0.6);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _SkwiltiIcon(size: height),
        SizedBox(width: height * 0.25),
        _SkwiltiText(fontSize: height * 0.55),
      ],
    );
  }
}

class _SkwiltiIcon extends StatelessWidget {
  final double size;
  const _SkwiltiIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _SkwiltiIconPainter()),
    );
  }
}

class _SkwiltiIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Orange circle (top right)
    final orangePaint = Paint()..color = const Color(0xFFE8630A)..style = PaintingStyle.fill;
    final greenPaint  = Paint()..color = const Color(0xFF1B6B2E)..style = PaintingStyle.fill;
    final whitePaint  = Paint()..color = Colors.white..style = PaintingStyle.fill;

    // Big orange circle
    canvas.drawCircle(Offset(w * 0.62, h * 0.30), w * 0.37, orangePaint);

    // Green S-snake body
    final path = Path();
    // Top curl of S
    path.moveTo(w * 0.55, h * 0.10);
    path.cubicTo(w * 0.30, h * 0.05, w * 0.05, h * 0.20, w * 0.15, h * 0.42);
    path.cubicTo(w * 0.22, h * 0.56, w * 0.45, h * 0.52, w * 0.50, h * 0.62);
    path.cubicTo(w * 0.58, h * 0.75, w * 0.40, h * 0.88, w * 0.20, h * 0.85);
    path.cubicTo(w * 0.08, h * 0.83, w * 0.04, h * 0.92, w * 0.10, h * 0.97);
    // Width of snake
    path.lineTo(w * 0.22, h * 0.97);
    path.cubicTo(w * 0.22, h * 0.97, w * 0.16, h * 0.90, w * 0.28, h * 0.92);
    path.cubicTo(w * 0.52, h * 0.96, w * 0.72, h * 0.80, w * 0.63, h * 0.62);
    path.cubicTo(w * 0.56, h * 0.48, w * 0.33, h * 0.52, w * 0.28, h * 0.42);
    path.cubicTo(w * 0.18, h * 0.26, w * 0.38, h * 0.14, w * 0.55, h * 0.18);
    path.close();
    canvas.drawPath(path, greenPaint);

    // Small orange dots on the snake
    canvas.drawCircle(Offset(w * 0.30, h * 0.58), w * 0.05, orangePaint);
    canvas.drawCircle(Offset(w * 0.42, h * 0.68), w * 0.04, orangePaint);

    // White dot (eye/node on orange circle)
    canvas.drawCircle(Offset(w * 0.72, h * 0.20), w * 0.07, whitePaint);
    canvas.drawCircle(Offset(w * 0.72, h * 0.20), w * 0.04, orangePaint);

    // Orange underline stroke
    final strokePaint = Paint()
      ..color = const Color(0xFFE8630A)
      ..strokeWidth = h * 0.07
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w * 0.05, h * 1.02), Offset(w * 0.60, h * 1.02), strokePaint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _SkwiltiText extends StatelessWidget {
  final double fontSize;
  const _SkwiltiText({required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Skwilti',
      style: GoogleFonts.nunito(
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        color: AppColors.green,
        letterSpacing: -0.5,
      ),
    );
  }
}

/// Compact square app icon version
class SkwiltiAppIcon extends StatelessWidget {
  final double size;
  final double borderRadius;
  const SkwiltiAppIcon({super.key, this.size = 48, this.borderRadius = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.12),
        child: SkwiltiLogo(height: size * 0.76, iconOnly: true),
      ),
    );
  }
}
