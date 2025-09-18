import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

final _rnd = Random();
const pageSize = 20;

// memoria simulada
final _emailsOTP = <String, String>{};
final _movs = List.generate(240, (i) => {
  "id": i + 1,
  "amount": (i % 2 == 0 ? 1 : -1) * (_rnd.nextInt(9000) + 100) / 100.0,
  "description": "Movimiento #${i + 1}",
  "createdAt": DateTime.now().subtract(Duration(minutes: i * 7)).toIso8601String(),
});

Response _json(data, {int status = 200}) =>
    Response(status, body: jsonEncode(data), headers: {'content-type': 'application/json'});

// simula latencia y fallos controlados
Future<void> _maybeDelayAndFail() async {
  await Future.delayed(Duration(milliseconds: 300 + _rnd.nextInt(600)));
  final p = _rnd.nextDouble();
  if (p < 0.08) throw TimeoutException("simulated timeout");
  if (p < 0.14) throw Exception("simulated 500");
}

void main(List<String> args) async {
  final app = Router();

  app.post('/auth/request-otp', (Request req) async {
    try {
      await _maybeDelayAndFail();
      final body = jsonDecode(await req.readAsString()) as Map;
      final email = (body['email'] ?? '').toString().trim().toLowerCase();
      if (email.isEmpty) return _json({"message": "email requerido"}, status: 400);
      final otp = (_rnd.nextInt(900000) + 100000).toString();
      _emailsOTP[email] = otp;
      // En una real, se enviaría por correo; aquí lo devolvemos para la prueba.
      return _json({"message": "OTP generado", "otp": otp});
    } on TimeoutException {
      return _json({"message": "timeout"}, status: 504);
    } catch (e) {
      return _json({"message": "error"}, status: 500);
    }
  });

  app.post('/auth/verify-otp', (Request req) async {
    try {
      await _maybeDelayAndFail();
      final body = jsonDecode(await req.readAsString()) as Map;
      final email = (body['email'] ?? '').toString().trim().toLowerCase();
      final otp = (body['otp'] ?? '').toString();
      if (_emailsOTP[email] == otp) {
        return _json({"token": "token_${email}_fake", "user":{"email": email}});
      }
      return _json({"message": "OTP inválido"}, status: 401);
    } on TimeoutException {
      return _json({"message": "timeout"}, status: 504);
    } catch (_) {
      return _json({"message": "error"}, status: 500);
    }
  });

  app.get('/transactions', (Request req) async {
    try {
      await _maybeDelayAndFail();
      final params = req.requestedUri.queryParameters;
      final page = int.tryParse(params['page'] ?? '1') ?? 1;
      final limit = int.tryParse(params['limit'] ?? '$pageSize') ?? pageSize;
      final start = (page - 1) * limit;
      final end = min(start + limit, _movs.length);
      final pageItems = start < _movs.length ? _movs.sublist(start, end) : [];
      return _json({
        "page": page,
        "limit": limit,
        "total": _movs.length,
        "items": pageItems,
      });
    } on TimeoutException {
      return _json({"message": "timeout"}, status: 504);
    } catch (_) {
      return _json({"message": "error"}, status: 500);
    }
  });

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler(app);

  final port = int.parse(const String.fromEnvironment('PORT', defaultValue: '8080'));
  final server = await serve(handler, '0.0.0.0', port);
  print('Mock API on http://localhost:${server.port}');
}
