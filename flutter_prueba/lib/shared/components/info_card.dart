import 'package:flutter/material.dart';

class InfoCard extends StatelessWidget {
  final String text;
  const InfoCard({Key? key, this.text = 'Acceso seguro · Datos cifrados'}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface.withOpacity(0.04), borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8))),
    );
  }
}
