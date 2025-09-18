import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  final double size;
  const BrandLogo({Key? key, this.size = 86}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(colors: [Color(0xFF7C4DFF), Color(0xFF536DFE)]),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 8))],
      ),
      child: Center(child: Icon(Icons.flutter_dash, color: Theme.of(context).colorScheme.onPrimary, size: size * 0.46)),
    );
  }
}
