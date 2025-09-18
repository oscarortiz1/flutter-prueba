abstract class LoginEvent {}

class SendOtp extends LoginEvent {
  final String email;
  SendOtp(this.email);
}

class VerifyOtp extends LoginEvent {
  final String code;
  VerifyOtp(this.code);
}

class ResetLogin extends LoginEvent {}
