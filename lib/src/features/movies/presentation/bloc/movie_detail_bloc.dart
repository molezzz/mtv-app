import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mtv_app/src/features/movies/domain/usecases/get_video_detail.dart';
import 'package:mtv_app/src/features/movies/presentation/bloc/movie_detail_event.dart';
import 'package:mtv_app/src/features/movies/presentation/bloc/movie_detail_state.dart';

class MovieDetailBloc extends Bloc<MovieDetailEvent, MovieDetailState> {
  final GetVideoDetail getVideoDetail;

  MovieDetailBloc({
    required this.getVideoDetail,
  }) : super(MovieDetailInitial()) {
    on<FetchVideoDetailEvent>(_onFetchVideoDetail);
  }

  Future<void> _onFetchVideoDetail(
    FetchVideoDetailEvent event,
    Emitter<MovieDetailState> emit,
  ) async {
    emit(MovieDetailLoading());
    try {
      final videoDetail = await getVideoDetail(event.source, event.id);
      emit(MovieDetailLoaded(videoDetail: videoDetail));
    } catch (e) {
      emit(MovieDetailError(message: 'Failed to fetch video detail: ${e.toString()}'));
    }
  }
}