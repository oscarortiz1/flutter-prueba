import 'package:flutter/material.dart';

class SocialButtonsRow extends StatelessWidget {
  const SocialButtonsRow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _iconButton(context, icon: Icons.apple, label: 'Apple'),
        const SizedBox(width: 12),
        _iconButton(context, icon: Icons.g_mobiledata, label: 'Google'),
        const SizedBox(width: 12),
        _iconButton(context, icon: Icons.facebook, label: 'Facebook'),
      ],
    );
  }

  Widget _iconButton(BuildContext context, {required IconData icon, required String label}) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurface),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.06), elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
    );
  }
}
