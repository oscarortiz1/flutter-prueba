import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'bloc/register_bloc.dart';
import 'bloc/register_event.dart';
import 'bloc/register_state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _showPass = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RegisterBloc(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Registro')),
        body: BlocListener<RegisterBloc, RegisterState>(
          listener: (context, state) {
            if (state is RegisterSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registro exitoso')));
              // use GoRouter to ensure correct navigation stack
              Future.delayed(const Duration(milliseconds: 400), () => context.go('/'));
            }
            if (state is RegisterFailure) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${state.message}')));
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(labelText: 'Nombre', prefixIcon: Icon(Icons.person)),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _emailCtrl,
                          decoration: const InputDecoration(labelText: 'Correo', prefixIcon: Icon(Icons.email)),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passCtrl,
                          obscureText: !_showPass,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_showPass ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _showPass = !_showPass),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        BlocBuilder<RegisterBloc, RegisterState>(builder: (context, state) {
                          final loading = state is RegisterLoading;
                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: loading
                                  ? null
                                  : () {
                                      final name = _nameCtrl.text.trim();
                                      final email = _emailCtrl.text.trim();
                                      final pass = _passCtrl.text;
                                      if (name.isEmpty || email.isEmpty || pass.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completa todos los campos')));
                                        return;
                                      }
                                      context.read<RegisterBloc>().add(SubmitRegister(name, email, pass));
                                    },
                              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                              child: loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Registrar'),
                            ),
                          );
                        })
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: () => GoRouter.of(context).go('/'),
                  child: const Text('Volver al inicio'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
