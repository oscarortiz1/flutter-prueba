import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Color topColor;
  final Color bottomColor;
  const AppBackground({Key? key, required this.topColor, required this.bottomColor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [topColor, bottomColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: CustomPaint(painter: _AppBackgroundPainter()),
    );
  }
}

class _AppBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.03);
    final path = Path();
    path.moveTo(0, size.height * 0.28);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.22, size.width * 0.5, size.height * 0.33);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.45, size.width, size.height * 0.36);
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();
    canvas.drawPath(path, paint);

    final circlePaint = Paint()..color = Colors.white.withOpacity(0.02);
    canvas.drawCircle(Offset(size.width * 0.12, size.height * 0.14), 64, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.86, size.height * 0.82), 100, circlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
