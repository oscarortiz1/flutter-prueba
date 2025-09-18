import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/movement.dart';
import 'add_movement_form_bloc.dart';


typedef OnCreateMovement = void Function(Movement movement);

class AddMovementFormWidget extends StatefulWidget {
  final OnCreateMovement onCreate;
  const AddMovementFormWidget({Key? key, required this.onCreate}) : super(key: key);

  @override
  State<AddMovementFormWidget> createState() => _AddMovementFormWidgetState();
}

class _AddMovementFormWidgetState extends State<AddMovementFormWidget> {
  final _desc = TextEditingController();
  final _amount = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _desc.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final desc = _desc.text.trim();
    final raw = _amount.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(raw) ?? 0;
    final movement = Movement(
      amount: amount,
      description: desc,
      type: 'transfer',
      accountFrom: 'default',
      accountTo: 'default',
      currency: 'PEN',
      status: 'pending',
      syncStatus: 'pending',
    );
    // notify parent
    widget.onCreate(movement);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AddMovementFormBloc(),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _desc,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Monto', hintText: '1.000'),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
                    const SizedBox(width: 8),
                    ElevatedButton(onPressed: _submit, child: const Text('Crear')),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
