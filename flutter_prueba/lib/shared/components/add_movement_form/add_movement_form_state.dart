abstract class AddMovementFormState {}

class AddMovementFormInitial extends AddMovementFormState {}

class AddMovementFormSubmitting extends AddMovementFormState {}

class AddMovementFormSuccess extends AddMovementFormState {}

class AddMovementFormFailure extends AddMovementFormState {
  final String message;
  AddMovementFormFailure(this.message);
}
