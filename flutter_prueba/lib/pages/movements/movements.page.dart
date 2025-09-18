import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../shared/models/movement.dart';
import '../../shared/repositories/movement_repository.dart';
import 'bloc/movement_bloc.dart';
import 'bloc/movement_event.dart';
import 'bloc/movement_state.dart';
import '../../shared/components/add_movement_form/add_movement_form_widget.dart';
import '../../shared/services/sync_service.dart';

class MovementsPage extends StatefulWidget {
  const MovementsPage({Key? key}) : super(key: key);

  @override
  State<MovementsPage> createState() => _MovementsPageState();
}

class _MovementsPageState extends State<MovementsPage> {
  MovementBloc? _bloc;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Delay BLoC creation until after first frame to avoid early plugin calls
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final bloc = MovementBloc(MovementRepository());
        setState(() {
          _bloc = bloc;
        });
      } catch (e) {
        setState(() {
          _error = e.toString();
        });
      }
    });
  }

  @override
  void dispose() {
    _bloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Movimientos')),
        body: Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text('Error inicializando la base de datos: $_error'))),
      );
    }

    if (_bloc == null) {
      // show loading while bloc is being created
      return Scaffold(
        appBar: AppBar(title: const Text('Movimientos')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return BlocProvider.value(
      value: _bloc!,
      child: const MovementsView(),
    );
  }
}

// Formatter that formats numbers as thousands separated (e.g. 1.234,56)
class ThousandsFormatter extends TextInputFormatter {
  // Format with grouping and NO decimals (e.g. 1.234)
  final NumberFormat _format = NumberFormat.currency(locale: 'es_ES', decimalDigits: 0, symbol: '');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final newText = newValue.text;
    if (newText.isEmpty) return newValue.copyWith(text: '');

    // Remove everything except digits
    final cleaned = newText.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return oldValue;

    final number = int.tryParse(cleaned);
    if (number == null) return oldValue;

    final formatted = _format.format(number).trim();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class MovementsView extends StatefulWidget {
  const MovementsView({Key? key}) : super(key: key);

  @override
  State<MovementsView> createState() => _MovementsViewState();
}

class _MovementsViewState extends State<MovementsView> with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;
  late final AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    // remove infinite-scroll listener; pagination uses explicit controls
    _staggerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    // Trigger initial load when the view is mounted and the BlocProvider is available
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        context.read<MovementBloc>().add(LoadMovements());
        // If there was a queued sync while offline, try to consume it now
        try {
          await SyncService().tryConsumeQueuedSync();
        } catch (e) {
          if (kDebugMode) debugPrint('tryConsumeQueuedSync failed: $e');
        }
      } catch (e) {
        if (kDebugMode) debugPrint('initial load failed: $e');
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      context.read<MovementBloc>().add(ApplyMovementsFilter(v.isEmpty ? null : v));
    });
  }

  Future<void> _openAddModal() async {
    final created = await showModalBottomSheet<Movement>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(child: AddMovementFormWidget(onCreate: (m) => Navigator.of(c).pop(m))),
        ),
      ),
    );
    if (created != null) {
      context.read<MovementBloc>().add(AddMovement(created));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Movimiento creado')));
    }
  }

  Widget _buildSearch(BuildContext context) {
    return Hero(
      tag: 'movements-search',
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: 'Buscar movimientos...', border: InputBorder.none),
            onChanged: _onSearchChanged,
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Movement m, int index) {
    final amountStr = NumberFormat.currency(locale: 'es_ES', symbol: '', decimalDigits: 0).format(m.amount);
    final anim = CurvedAnimation(parent: _staggerController, curve: Interval((index * 0.05).clamp(0.0, 1.0), 1.0, curve: Curves.easeOut));
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.05), end: Offset.zero).animate(anim),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(m.description ?? 'Movimiento', style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${m.accountFrom} → ${m.accountTo} · ${m.createdAt.toLocal().toString()}'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('S/ $amountStr', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              IconButton(onPressed: () => _confirmDelete(m), icon: const Icon(Icons.delete_outline)),
            ]),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(Movement m) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Eliminar movimiento'),
        content: const Text('¿Estás seguro que deseas eliminar este movimiento?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () {
            Navigator.of(c).pop();
            context.read<MovementBloc>().add(DeleteMovement(m.id!));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Movimiento eliminado')));
          }, child: const Text('Eliminar'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movimientos'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton.icon(
              onPressed: _openAddModal,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nuevo'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildSearch(context),
            const SizedBox(height: 12),
            Expanded(
              child: BlocBuilder<MovementBloc, MovementState>(builder: (context, state) {
                if (state is MovementsLoading) return const Center(child: CircularProgressIndicator());
                if (state is MovementsError) return Center(child: Text('Error: ${state.message}'));
                if (state is MovementsLoaded) {
                  final list = state.movements;
                  if (list.isEmpty) return const Center(child: Text('No hay movimientos'));
                  // Page content with pull-to-refresh
                  return Column(
                    children: [
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () async {
                            context.read<MovementBloc>().add(RefreshMovements());
                            await Future.delayed(const Duration(milliseconds: 600));
                          },
                          child: ListView.separated(
                            controller: _scrollController,
                            itemCount: list.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final m = list[i];
                              return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: _buildCard(m, i));
                            },
                          ),
                        ),
                      ),
                      // Paginator controls
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: state.page > 0 ? () => context.read<MovementBloc>().add(GoToPage(state.page - 1)) : null,
                              child: const Text('Anterior'),
                            ),
                            const SizedBox(width: 12),
                            Text('Página ${state.page + 1} de ${state.totalPages}'),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: state.page < (state.totalPages - 1) ? () => context.read<MovementBloc>().add(GoToPage(state.page + 1)) : null,
                              child: const Text('Siguiente'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),
            )
          ],
        ),
      ),
    );
  }
}
