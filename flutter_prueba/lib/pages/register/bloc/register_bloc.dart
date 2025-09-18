import 'package:bloc/bloc.dart';
import '../../../shared/services/auth_service.dart';
import 'register_event.dart';
import 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final AuthService _auth = AuthService();

  RegisterBloc() : super(RegisterInitial()) {
    on<SubmitRegister>((event, emit) async {
      emit(RegisterLoading());
      try {
        final ok = await _auth.register(event.name, event.email, event.password);
        if (ok) {
          emit(RegisterSuccess());
        } else {
          emit(RegisterFailure('Registro fallido'));
        }
      } catch (e) {
        emit(RegisterFailure(e.toString()));
      }
    });
  }
}
