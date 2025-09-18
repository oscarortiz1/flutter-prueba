abstract class RegisterEvent {}

class SubmitRegister extends RegisterEvent {
  final String name;
  final String email;
  final String password;

  SubmitRegister(this.name, this.email, this.password);
}
