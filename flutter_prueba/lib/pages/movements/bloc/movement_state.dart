import '../../../shared/models/movement.dart';

abstract class MovementState {}

class MovementsLoading extends MovementState {}

class MovementsLoaded extends MovementState {
  final List<Movement> movements;
  final int page; // zero-based
  final bool hasReachedMax;
  final String? query;
  final int total;
  final int totalPages;

  MovementsLoaded(this.movements, {this.page = 0, this.hasReachedMax = false, this.query, this.total = 0, this.totalPages = 0});
}

class MovementsError extends MovementState {
  final String message;
  MovementsError(this.message);
}
