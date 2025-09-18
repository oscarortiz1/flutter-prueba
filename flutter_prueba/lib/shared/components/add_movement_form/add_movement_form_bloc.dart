import 'package:bloc/bloc.dart';
import 'add_movement_form_event.dart';
import 'add_movement_form_state.dart';

class AddMovementFormBloc extends Bloc<AddMovementFormEvent, AddMovementFormState> {
  AddMovementFormBloc() : super(AddMovementFormInitial()) {
    on<SubmitMovement>((event, emit) async {
      emit(AddMovementFormSubmitting());
      try {
        // In this simplified form bloc we just wait a short time to simulate processing
        await Future.delayed(const Duration(milliseconds: 300));
        emit(AddMovementFormSuccess());
      } catch (e) {
        emit(AddMovementFormFailure(e.toString()));
      }
    });
  }
}
