import 'package:flutter/material.dart';

class PrimaryTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;

  const PrimaryTextField({Key? key, required this.controller, required this.hint, required this.icon, this.obscure = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
  final theme = Theme.of(context);
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: theme.colorScheme.onSurface.withOpacity(0.7)),
        hintText: hint,
        hintStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
        filled: true,
        fillColor: theme.inputDecorationTheme.fillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
    );
  }
}
