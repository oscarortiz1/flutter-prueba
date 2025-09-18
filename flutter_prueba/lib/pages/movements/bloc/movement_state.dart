import '../../../shared/models/movement.dart';

abstract class MovementState {}

class MovementsLoading extends MovementState {}

class MovementsLoaded extends MovementState {
  final List<Movement> movements;
  final int page; // zero-based
  final bool hasReachedMax;
  final String? query;

  MovementsLoaded(this.movements, {this.page = 0, this.hasReachedMax = false, this.query});
}

class MovementsError extends MovementState {
  final String message;
  MovementsError(this.message);
}
