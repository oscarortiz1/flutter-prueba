import 'package:bloc/bloc.dart';
import 'movement_event.dart';
import 'movement_state.dart';
import '../../../shared/repositories/movement_repository.dart';
import '../../../shared/models/movement.dart';

class MovementBloc extends Bloc<MovementEvent, MovementState> {
  final MovementRepository _repo;
  MovementBloc(this._repo) : super(MovementsLoading()) {
    const pageSize = 20;

    on<LoadMovements>((_, emit) async {
      emit(MovementsLoading());
      try {
        // load first page (page 0) using server if needed
        final meta = await _repo.fetchPageWithMeta(0, limit: pageSize);
  final list = (meta['movements'] as List).cast<Movement>();
        final total = meta['total'] as int? ?? 0;
        final totalPages = meta['totalPages'] as int? ?? 0;
        final hasReachedMax = (0 >= (totalPages - 1));
        emit(MovementsLoaded(List.of(list), page: 0, hasReachedMax: hasReachedMax, total: total, totalPages: totalPages));
      } catch (e) {
        emit(MovementsError(e.toString()));
      }
    });

    on<RefreshMovements>((_, emit) async {
      if (state is MovementsLoaded) {
        final cur = state as MovementsLoaded;
        emit(MovementsLoading());
        try {
          final meta = await _repo.fetchPageWithMeta(cur.page, limit: pageSize, query: cur.query);
          final list = (meta['movements'] as List).cast<Movement>();
          final total = meta['total'] as int? ?? 0;
          final totalPages = meta['totalPages'] as int? ?? 0;
          final hasReachedMax = (cur.page >= (totalPages - 1));
          emit(MovementsLoaded(List.of(list), page: cur.page, hasReachedMax: hasReachedMax, query: cur.query, total: total, totalPages: totalPages));
        } catch (e) {
          emit(MovementsError(e.toString()));
        }
      } else {
        // fallback to full load
        add(LoadMovements());
      }
    });

    // LoadMore is retained for compatibility but UI uses page controls now.
    on<LoadMoreMovements>((event, emit) async {
      // no-op or alias to go to next page
      if (state is MovementsLoaded) {
        final cur = state as MovementsLoaded;
        if (cur.page < (cur.totalPages - 1)) {
          add(GoToPage(cur.page + 1));
        }
      }
    });

    on<GoToPage>((event, emit) async {
      emit(MovementsLoading());
      try {
        final meta = await _repo.fetchPageWithMeta(event.page, limit: pageSize);
  final list = (meta['movements'] as List).cast<Movement>();
        final total = meta['total'] as int? ?? 0;
        final totalPages = meta['totalPages'] as int? ?? 0;
        final hasReachedMax = (event.page >= (totalPages - 1));
        emit(MovementsLoaded(List.of(list), page: event.page, hasReachedMax: hasReachedMax, total: total, totalPages: totalPages));
      } catch (e) {
        emit(MovementsError(e.toString()));
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
