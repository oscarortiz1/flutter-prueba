import '../../models/movement.dart';

abstract class AddMovementFormEvent {}

class SubmitMovement extends AddMovementFormEvent {
  final Movement movement;
  SubmitMovement(this.movement);
}
