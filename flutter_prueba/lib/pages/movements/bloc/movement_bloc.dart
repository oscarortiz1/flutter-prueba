import 'package:bloc/bloc.dart';
import 'movement_event.dart';
import 'movement_state.dart';
import '../../../shared/repositories/movement_repository.dart';

class MovementBloc extends Bloc<MovementEvent, MovementState> {
  final MovementRepository _repo;
  MovementBloc(this._repo) : super(MovementsLoading()) {
    const pageSize = 20;

    on<LoadMovements>((_, emit) async {
      emit(MovementsLoading());
      try {
        // prefer cached local results; if empty, try server once
        final list = await _repo.fetchCachedOrServer();
        final hasReachedMax = list.length < pageSize;
        emit(MovementsLoaded(list, page: 0, hasReachedMax: hasReachedMax));
      } catch (e) {
        emit(MovementsError(e.toString()));
      }
    });

    on<RefreshMovements>((_, emit) async {
      emit(MovementsLoading());
      try {
  // Force server pull and repopulate local cache
  _repo.resetServerCheck();
  final list = await _repo.fetchCachedOrServer();
        final hasReachedMax = list.length < pageSize;
        emit(MovementsLoaded(list, page: 0, hasReachedMax: hasReachedMax));
      } catch (e) {
        emit(MovementsError(e.toString()));
      }
    });

    on<LoadMoreMovements>((event, emit) async {
      if (state is MovementsLoaded) {
        final cur = state as MovementsLoaded;
        if (cur.hasReachedMax) return;
        final nextPage = cur.page + 1;
        try {
          final list = await _repo.fetchPage(nextPage, limit: pageSize, query: cur.query);
          final hasReachedMax = list.length < pageSize;
          final combined = List.of(cur.movements)..addAll(list);
          emit(MovementsLoaded(combined, page: nextPage, hasReachedMax: hasReachedMax, query: cur.query));
        } catch (e) {
          emit(MovementsError(e.toString()));
        }
      }
    });

    on<ApplyMovementsFilter>((event, emit) async {
      emit(MovementsLoading());
      try {
        final list = await _repo.fetchPage(0, limit: pageSize, query: event.query);
        final hasReachedMax = list.length < pageSize;
        emit(MovementsLoaded(list, page: 0, hasReachedMax: hasReachedMax, query: event.query));
      } catch (e) {
        emit(MovementsError(e.toString()));
      }
    });

    on<AddMovement>((event, emit) async {
      if (state is MovementsLoaded) {
        try {
          final added = await _repo.add(event.movement);
          final list = List.of((state as MovementsLoaded).movements)..insert(0, added);
          emit(MovementsLoaded(list));
        } catch (e) {
          emit(MovementsError(e.toString()));
        }
      }
    });

    on<DeleteMovement>((event, emit) async {
      if (state is MovementsLoaded) {
        try {
          await _repo.delete(event.id);
          final list = List.of((state as MovementsLoaded).movements)..removeWhere((m) => m.id == event.id);
          emit(MovementsLoaded(list));
        } catch (e) {
          emit(MovementsError(e.toString()));
        }
      }
    });
  }
}
