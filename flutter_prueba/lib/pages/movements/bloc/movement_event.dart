import '../../../shared/models/movement.dart';

abstract class MovementEvent {}

class LoadMovements extends MovementEvent {}

class RefreshMovements extends MovementEvent {}

class LoadMoreMovements extends MovementEvent {}

class ApplyMovementsFilter extends MovementEvent {
  final String? query;
  ApplyMovementsFilter(this.query);
}

class AddMovement extends MovementEvent {
  final Movement movement;
  AddMovement(this.movement);
}

class DeleteMovement extends MovementEvent {
  final int id;
  DeleteMovement(this.id);
}
