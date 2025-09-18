import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'login_event.dart';
import 'login_state.dart';
import '../../../shared/services/notification_service.dart';
import '../../../shared/services/auth_service.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(LoginInitial()) {
    on<SendOtp>(_onSendOtp);
    on<VerifyOtp>(_onVerifyOtp);
    on<ResetLogin>((_, emit) => emit(LoginInitial()));
  }

  FutureOr<void> _onSendOtp(SendOtp event, Emitter<LoginState> emit) async {
    // ask backend for OTP (validates email+password)
    emit(LoginInitial());
    try {
      final code = await AuthService().requestOtp(event.email, event.password);
      if (code != null) {
        // show local notification with code
        await NotificationService().showOtpNotification(code, event.email);
        // debug log
        // ignore: avoid_print
        print('LoginBloc: OTP sent for ${event.email} -> $code');
        emit(OtpSent(code, event.email));
      } else {
        emit(LoginFailure('Credenciales inválidas'));
      }
    } catch (e) {
      // log for developers
      // ignore: avoid_print
      print('LoginBloc requestOtp error: $e');
      final msg = _friendlyError(e);
      emit(LoginFailure(msg));
    }
  }

  FutureOr<void> _onVerifyOtp(VerifyOtp event, Emitter<LoginState> emit) async {
    final current = state;
    if (current is! OtpSent) {
      emit(LoginFailure('No hay OTP enviado'));
      return;
    }

    try {
      // verify via backend (await to ensure correct ordering)
      final ok = await AuthService().verifyOtp(current.email, event.code);
      // ignore: avoid_print
      print('LoginBloc: verifyOtp returned $ok for ${current.email} with code ${event.code}');
      if (ok) {
        emit(OtpVerified());
      } else {
        emit(LoginFailure('Código inválido o expirado'));
        // re-emit the OtpSent so UI can stay in OTP mode
        emit(current);
      }
    } catch (e) {
      // log and present a friendly message
      // ignore: avoid_print
      print('LoginBloc verifyOtp error: $e');
      final msg = _friendlyError(e);
      emit(LoginFailure(msg));
      emit(current);
    }
  }

  String _friendlyError(Object e) {
    final s = e.toString();
    if (s.contains('Connection refused') || s.contains('Failed host lookup') || s.contains('SocketException') || s.contains('No route to host')) {
      return 'No se pudo conectar al servidor. Verifica que el backend esté corriendo y la configuración de red (baseUrl).';
    }
    if (s.contains('DioException')) {
      // return concise Dio message
      return s;
    }
    return 'Error de red: $s';
  }
}
