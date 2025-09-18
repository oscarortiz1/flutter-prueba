import 'package:flutter/material.dart';
import '../../shared/services/theme_service.dart';
import '../profile/profile.page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with SingleTickerProviderStateMixin {
  final ThemeService _themeService = ThemeService();
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _themeService.load();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Widget _buildHeader(BuildContext c) {
    return SizeTransition(
      sizeFactor: CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
      axisAlignment: -1,
      child: Row(
        children: [
          Transform.rotate(
            angle: _animController.drive(Tween(begin: -0.2, end: 0.0)).value,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 6))],
              ),
              child: const Icon(Icons.settings, color: Colors.white, size: 36),
            ),
          ),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Ajustes', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Personaliza tu experiencia', style: Theme.of(context).textTheme.bodyMedium)
          ])
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor.withOpacity(0.98);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              // Glass-like card
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Tema', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      Icon(Icons.dark_mode, color: Theme.of(context).colorScheme.primary),
                    ]),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<ThemeMode>(
                      valueListenable: _themeService.mode,
                      builder: (context, mode, _) {
                        return Column(
                          children: [
                            _themedTile(ThemeMode.system, 'Sistema', mode == ThemeMode.system),
                            _themedTile(ThemeMode.light, 'Claro', mode == ThemeMode.light),
                            _themedTile(ThemeMode.dark, 'Oscuro', mode == ThemeMode.dark),
                          ],
                        );
                      },
                    )
                  ],
                ),
              ),
              const SizedBox(height: 20),
             
            ],
          ),
        ),
      ),
    );
  }

  Widget _themedTile(ThemeMode value, String label, bool selected) {
    return ListTile(
      onTap: () => _themeService.setMode(value),
      leading: AnimatedContainer(duration: const Duration(milliseconds: 300), width: 42, height: 42, decoration: BoxDecoration(color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.shade200, borderRadius: BorderRadius.circular(10)), child: Icon(value == ThemeMode.light ? Icons.wb_sunny : (value == ThemeMode.dark ? Icons.nightlight_round : Icons.phone_iphone), color: selected ? Colors.white : Colors.black54)),
      title: Text(label, style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
      trailing: AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: selected ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.secondary, key: const ValueKey('sel')) : const SizedBox.shrink()),
    );
  }
}
