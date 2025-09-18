import 'dart:async';
import 'dart:math';

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
    // generate a 4-digit code
    final code = (1000 + Random().nextInt(9000)).toString();
    // send via local notification
    await NotificationService().showOtpNotification(code, event.email);
    emit(OtpSent(code, event.email));
  }

  FutureOr<void> _onVerifyOtp(VerifyOtp event, Emitter<LoginState> emit) {
    final current = state;
    if (current is OtpSent && event.code == current.code) {
      // persist logged-in state
      AuthService().setLoggedIn(current.email);
      emit(OtpVerified());
    } else {
      emit(LoginFailure('Código inválido'));
      // revert to OtpSent to allow retries
      if (current is OtpSent) emit(current);
    }
  }
}
