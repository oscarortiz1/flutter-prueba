abstract class LoginEvent {}

class SendOtp extends LoginEvent {
  final String email;
  final String password;
  // allow optional args with defaults to avoid accidental no-arg calls
  SendOtp([this.email = '', this.password = '']);
}

class VerifyOtp extends LoginEvent {
  final String code;
  VerifyOtp(this.code);
}

class ResetLogin extends LoginEvent {}
