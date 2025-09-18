import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_prueba/shared/services/notification_service.dart';
import 'bloc/login_bloc.dart';
import 'bloc/login_event.dart';
import 'bloc/login_state.dart';
import '../../shared/components/primary_text_field.dart';
import '../../shared/components/otp_input.dart';
import '../../shared/components/brand_logo.dart';
import '../../shared/components/app_background.dart';
import '../../shared/components/social_buttons.dart';
import '../../shared/components/info_card.dart';
import '../../shared/components/primary_button.dart';

/// Reescritura limpia del login usando componentes compartidos
class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();

  bool _showOtp = false;

  late final AnimationController _animController;
  late final Animation<double> _fade;
  late final Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    NotificationService().init();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _goToOtp() {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    context.read<LoginBloc>().add(SendOtp(email));
    setState(() => _showOtp = true);
  }

  void _backFromOtp() => setState(() => _showOtp = false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AppBackground(
            topColor: Theme.of(context).colorScheme.primary.withOpacity(0.9),
            bottomColor: Theme.of(
              context,
            ).colorScheme.secondary.withOpacity(0.9),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isWide ? 900 : 420),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      child: AnimatedCrossFade(
                        firstChild: _buildAuthCard(context, isWide),
                        secondChild: _buildOtpCard(context, isWide),
                        crossFadeState: _showOtp
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 500),
                        firstCurve: Curves.easeOut,
                        secondCurve: Curves.easeIn,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthCard(BuildContext context, bool isWide) {
    return SlideTransition(
      position: _cardSlide,
      child: Card(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.06),
        elevation: 16,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: isWide
              ? Row(
                  children: [
                    Expanded(child: _leftPanel(context)),
                    const SizedBox(width: 20),
                    Expanded(child: _rightPanel(context)),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _leftPanel(context),
                    const SizedBox(height: 18),
                    _rightPanel(context),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _leftPanel(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeTransition(opacity: _fade, child: const BrandLogo()),
        const SizedBox(height: 12),
        Text(
          'Bienvenido de nuevo',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          'Accede a tu cuenta para continuar',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        PrimaryTextField(
          controller: _emailController,
          hint: 'Correo electrónico',
          icon: Icons.email,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: PrimaryButton(
                onPressed: _goToOtp,
                child: const Text(
                  'Enviar código',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            child: Text(
              '¿Olvidaste tu contraseña?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }

  Widget _rightPanel(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        SizedBox(height: 6),
        SocialButtonsRow(),
        SizedBox(height: 18),
        InfoCard(),
      ],
    );
  }

  Widget _buildOtpCard(BuildContext context, bool isWide) {
    return Card(
      color: Theme.of(context).colorScheme.surface.withOpacity(0.06),
      elevation: 16,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: _backFromOtp,
                  icon: Icon(
                    Icons.arrow_back,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  'Verificación',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                const SizedBox(width: 40),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Ingresa el código enviado a tu correo',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            BlocBuilder<LoginBloc, LoginState>(
              builder: (context, state) {
                if (state is OtpSent) {
                  return Column(
                    children: [
                      OtpInput(
                        length: 4,
                        boxSize: isWide ? 64 : 54,
                        onChanged: (v) {
                          if (v.length == 4)
                            context.read<LoginBloc>().add(VerifyOtp(v));
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                } else if (state is LoginFailure) {
                  return Column(
                    children: [
                      Text(
                        state.message,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OtpInput(
                        length: 4,
                        boxSize: isWide ? 64 : 54,
                        onChanged: (v) {
                          if (v.length == 4)
                            context.read<LoginBloc>().add(VerifyOtp(v));
                        },
                      ),
                    ],
                  );
                } else if (state is OtpVerified) {
                  return Center(
                    child: Text(
                      'Verificado ✅',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }
                return OtpInput(
                  length: 4,
                  boxSize: isWide ? 64 : 54,
                  onChanged: (v) {
                    if (v.length == 4)
                      context.read<LoginBloc>().add(VerifyOtp(v));
                  },
                );
              },
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 28,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Verificar'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {},
              child: Text(
                'Reenviar código',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
