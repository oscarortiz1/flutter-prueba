import 'package:flutter/material.dart';

/// Serio, responsivo y animado: Login + OTP (visual only)
class LoginPage extends StatefulWidget {
	const LoginPage({Key? key}) : super(key: key);

	@override
	State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
	final _emailController = TextEditingController();
	final _passwordController = TextEditingController();
	bool _showOtp = false;

	late final AnimationController _animController;
	late final Animation<double> _pulse;
	late final Animation<Offset> _cardSlide;

	@override
	void initState() {
		super.initState();
		_animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
		_pulse = Tween<double>(begin: 0.98, end: 1.02).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOut));
		_cardSlide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
		_animController.repeat(reverse: true);
	}

	@override
	void dispose() {
		_animController.dispose();
		_emailController.dispose();
		_passwordController.dispose();
		super.dispose();
	}

	void _goToOtp() => setState(() => _showOtp = true);
	void _backFromOtp() => setState(() => _showOtp = false);

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			body: Stack(
				children: [
					_Background(
						topColor: Theme.of(context).colorScheme.primary.withOpacity(0.9),
						bottomColor: Colors.indigo.shade900,
					),
					SafeArea(
						child: LayoutBuilder(builder: (context, constraints) {
							final isWide = constraints.maxWidth > 700;
							return Center(
								child: ConstrainedBox(
									constraints: BoxConstraints(maxWidth: isWide ? 900 : 420),
									child: Padding(
										padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
										child: AnimatedCrossFade(
											firstChild: _buildAuthCard(context, isWide),
											secondChild: _buildOtpCard(context, isWide),
											crossFadeState: _showOtp ? CrossFadeState.showSecond : CrossFadeState.showFirst,
											duration: const Duration(milliseconds: 500),
											firstCurve: Curves.easeOut,
											secondCurve: Curves.easeIn,
										),
									),
								),
							);
						}),
					),
				],
			),
		);
	}

	Widget _buildAuthCard(BuildContext context, bool isWide) {
		return SlideTransition(
			position: _cardSlide,
			child: Card(
				color: Colors.white.withOpacity(0.08),
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
				ScaleTransition(scale: _pulse, child: _brandLogo()),
				const SizedBox(height: 12),
				const Text('Bienvenido de nuevo', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
				const SizedBox(height: 6),
				const Text('Accede a tu cuenta para continuar', style: TextStyle(color: Colors.white70)),
				const SizedBox(height: 18),
				_buildTextField(controller: _emailController, hint: 'Correo electrónico', icon: Icons.email),
				const SizedBox(height: 12),
				_buildTextField(controller: _passwordController, hint: 'Contraseña', icon: Icons.lock, obscure: true),
				const SizedBox(height: 16),
				Row(children: [Expanded(child: _primaryButton())]),
				const SizedBox(height: 10),
				Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () {}, child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(color: Colors.white70))))
			],
		);
	}

	Widget _rightPanel(BuildContext context) {
		return Column(
			mainAxisSize: MainAxisSize.min,
			children: [
				const SizedBox(height: 6),
				_socialButtonsRow(),
				const SizedBox(height: 18),
				_infoCard(),
			],
		);
	}

	Widget _primaryButton() {
		return ElevatedButton(
			onPressed: _goToOtp,
			style: ElevatedButton.styleFrom(
				backgroundColor: Colors.deepPurpleAccent,
				padding: const EdgeInsets.symmetric(vertical: 14),
				shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
			),
			child: const Text('Iniciar sesión', style: TextStyle(fontSize: 16)),
		);
	}

	Widget _socialButtonsRow() {
		return Row(
			mainAxisAlignment: MainAxisAlignment.center,
			children: [
				_iconButton(icon: Icons.apple, label: 'Apple'),
				const SizedBox(width: 12),
				_iconButton(icon: Icons.g_mobiledata, label: 'Google'),
				const SizedBox(width: 12),
				_iconButton(icon: Icons.facebook, label: 'Facebook'),
			],
		);
	}

	Widget _iconButton({required IconData icon, required String label}) {
		return ElevatedButton.icon(
			onPressed: () {},
			icon: Icon(icon, size: 18, color: Colors.white),
			label: Text(label, style: const TextStyle(fontSize: 13)),
			style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.06), elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
		);
	}

	Widget _infoCard() {
		return Container(
			width: double.infinity,
			padding: const EdgeInsets.all(12),
			decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(10)),
			child: const Text('Acceso seguro · Datos cifrados', style: TextStyle(color: Colors.white70)),
		);
	}

	Widget _buildOtpCard(BuildContext context, bool isWide) {
		return Card(
			color: Colors.white.withOpacity(0.08),
			elevation: 16,
			shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
			child: Padding(
				padding: const EdgeInsets.all(20),
				child: Column(mainAxisSize: MainAxisSize.min, children: [
					Row(children: [
						IconButton(onPressed: _backFromOtp, icon: const Icon(Icons.arrow_back, color: Colors.white)),
						const Spacer(),
						const Text('Verificación', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
						const Spacer(),
						const SizedBox(width: 40)
					]),
					const SizedBox(height: 12),
					const Text('Ingresa el código enviado a tu correo', style: TextStyle(color: Colors.white70)),
					const SizedBox(height: 18),
					_otpFields(isWide),
					const SizedBox(height: 18),
					ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent, padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 28), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('Verificar')),
					const SizedBox(height: 8),
					TextButton(onPressed: () {}, child: const Text('Reenviar código', style: TextStyle(color: Colors.white70)))
				]),
			),
		);
	}

	Widget _brandLogo() {
		return Container(
			width: 86,
			height: 86,
			decoration: BoxDecoration(
				shape: BoxShape.circle,
				gradient: const LinearGradient(colors: [Color(0xFF7C4DFF), Color(0xFF536DFE)]),
				boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.28), blurRadius: 12, offset: const Offset(0, 8))],
			),
			child: const Center(child: Icon(Icons.flutter_dash, color: Colors.white, size: 40)),
		);
	}

	Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, bool obscure = false}) {
		return TextField(
			controller: controller,
			obscureText: obscure,
			style: const TextStyle(color: Colors.white),
			decoration: InputDecoration(
				prefixIcon: Icon(icon, color: Colors.white70),
				hintText: hint,
				hintStyle: const TextStyle(color: Colors.white54),
				filled: true,
				fillColor: Colors.white.withOpacity(0.04),
				border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
				contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
			),
		);
	}

	Widget _otpFields(bool isWide) {
		final boxSize = isWide ? 64.0 : 54.0;
		return Row(
			mainAxisAlignment: MainAxisAlignment.center,
			children: List.generate(4, (i) {
				return AnimatedContainer(
					duration: const Duration(milliseconds: 350),
					margin: const EdgeInsets.symmetric(horizontal: 8),
					width: boxSize,
					height: boxSize,
					decoration: BoxDecoration(
						color: Colors.white.withOpacity(0.03),
						borderRadius: BorderRadius.circular(12),
						border: Border.all(color: Colors.white12),
						boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.14), blurRadius: 8, offset: const Offset(0, 6))],
					),
					child: const Center(child: Text('-', style: TextStyle(color: Colors.white38, fontSize: 22, fontWeight: FontWeight.w700))),
				);
			}),
		);
	}
}

class _Background extends StatelessWidget {
	final Color topColor;
	final Color bottomColor;
	const _Background({Key? key, required this.topColor, required this.bottomColor}) : super(key: key);

	@override
	Widget build(BuildContext context) {
		return Container(
			decoration: BoxDecoration(
				gradient: LinearGradient(colors: [topColor, bottomColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
			),
			child: CustomPaint(painter: _BackgroundPainter()),
		);
	}
}

class _BackgroundPainter extends CustomPainter {
	@override
	void paint(Canvas canvas, Size size) {
		final paint = Paint()..color = Colors.white.withOpacity(0.03);
		final path = Path();
		path.moveTo(0, size.height * 0.28);
		path.quadraticBezierTo(size.width * 0.25, size.height * 0.22, size.width * 0.5, size.height * 0.33);
		path.quadraticBezierTo(size.width * 0.75, size.height * 0.45, size.width, size.height * 0.36);
		path.lineTo(size.width, 0);
		path.lineTo(0, 0);
		path.close();
		canvas.drawPath(path, paint);

		final circlePaint = Paint()..color = Colors.white.withOpacity(0.02);
		canvas.drawCircle(Offset(size.width * 0.12, size.height * 0.14), 64, circlePaint);
		canvas.drawCircle(Offset(size.width * 0.86, size.height * 0.82), 100, circlePaint);
	}

	@override
	bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

