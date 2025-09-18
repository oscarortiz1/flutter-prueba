abstract class LoginState {}

class LoginInitial extends LoginState {}

class OtpSent extends LoginState {
  final String code; // for local verification in this demo
  final String email;
  OtpSent(this.code, this.email);
}

class OtpVerified extends LoginState {}

class LoginFailure extends LoginState {
  final String message;
  LoginFailure(this.message);
}
