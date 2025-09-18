import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/services/auth_service.dart';

/// Responsive layout page intended to be used as a shell for nested routes.
///
/// Use it with `GoRouter`'s `ShellRoute` or wrap your nested routes so the
/// `child` of this widget is the active sub-route content.
class LayoutPage extends StatefulWidget {
  final Widget child;
  final int selectedIndex;
  final ValueChanged<int>? onIndexChanged;
  final VoidCallback? onLogout;

  const LayoutPage({Key? key, required this.child, this.selectedIndex = 0, this.onIndexChanged, this.onLogout}) : super(key: key);

  @override
  State<LayoutPage> createState() => _LayoutPageState();
}

class _LayoutPageState extends State<LayoutPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  static const _staggerDelay = 0.08;

  final List<_NavItem> navItems = [
    _NavItem(label: 'Inicio', icon: Icons.home),
    _NavItem(label: 'Perfil', icon: Icons.person),
    _NavItem(label: 'Ajustes', icon: Icons.settings),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    // start the entrance animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _stagger(int index) {
    final start = (index * _staggerDelay).clamp(0.0, 0.9);
    final end = (start + 0.5).clamp(0.0, 1.0);
    return CurvedAnimation(parent: _controller, curve: Interval(start, end, curve: Curves.easeOut));
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        
       
      ),
      drawer: isWide
          ? null
          : Drawer(
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    // Header with avatar and aura
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary.withOpacity(0.24), Theme.of(context).colorScheme.primary.withOpacity(0.06)]),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.14), blurRadius: 28, spreadRadius: 6),
                          ],
                        ),
                        child: Row(children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary]),
                              boxShadow: [
                                BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.28), blurRadius: 24, spreadRadius: 8),
                              ],
                            ),
                            child: const Center(child: Icon(Icons.person, color: Colors.white, size: 30)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Usuario', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), Text('Activo', style: Theme.of(context).textTheme.bodySmall)]))
                        ]),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        children: [
                          ...List.generate(navItems.length, (i) {
                            final n = navItems[i];
                            final anim = _stagger(i);
                            final selected = i == widget.selectedIndex;
                            return FadeTransition(
                              opacity: anim,
                              child: SlideTransition(
                                position: Tween<Offset>(begin: const Offset(-0.08, 0), end: Offset.zero).animate(anim),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: selected
                                      ? BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.06), blurRadius: 14, spreadRadius: 2)])
                                      : null,
                                  child: ListTile(
                                    leading: Icon(n.icon, color: selected ? Theme.of(context).colorScheme.primary : null),
                                    title: Text(n.label, style: selected ? TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600) : null),
                                    selected: selected,
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      widget.onIndexChanged?.call(i);
                                    },
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.surface, foregroundColor: Theme.of(context).colorScheme.onSurface, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        icon: const Icon(Icons.logout),
                        label: const Text('Cerrar sesión'),
                        onPressed: () async {
                          // prefer provided callback, otherwise call AuthService directly
                          if (widget.onLogout != null) return widget.onLogout!();
                          final a = AuthService();
                          await a.logout();
                          // Clear navigation stack and go to login (root '/').
                          try {
                            context.go('/');
                          } catch (_) {
                            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                          }
                        },
                      ),
                    )
                  ],
                ),
              ),
            ),
      body: Row(
        children: [
          if (isWide)
            Container(
              width: 120,
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Column(children: [
                // Avatar with heavier aura
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary]),
                    boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.28), blurRadius: 30, spreadRadius: 10)],
                  ),
                  child: const Center(child: Icon(Icons.person, color: Colors.white, size: 32)),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: List.generate(navItems.length, (i) {
                      final n = navItems[i];
                      final anim = _stagger(i);
                      final selected = i == widget.selectedIndex;
                      return FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(begin: const Offset(-0.04, 0), end: Offset.zero).animate(anim),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => widget.onIndexChanged?.call(i),
                              child: Container(
                                width: 96,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: selected
                                    ? BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.06), blurRadius: 12)])
                                    : null,
                                child: Column(children: [Icon(n.icon, color: selected ? Theme.of(context).colorScheme.primary : null), const SizedBox(height: 6), Text(n.label, style: const TextStyle(fontSize: 12))]),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () async {
                      if (widget.onLogout != null) return widget.onLogout!();
                      final a = AuthService();
                      await a.logout();
                      try {
                        context.go('/');
                      } catch (_) {
                        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                      }
                    },
                    tooltip: 'Cerrar sesión',
                  ),
                )
              ]),
            ),
          Expanded(
            child: Container(
              alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: widget.child,
                ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  _NavItem({required this.label, required this.icon});
}
