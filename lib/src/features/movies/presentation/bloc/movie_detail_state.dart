import 'package:equatable/equatable.dart';
import 'package:mtv_app/src/features/movies/domain/entities/video_detail.dart';

abstract class MovieDetailState extends Equatable {
  const MovieDetailState();

  @override
  List<Object> get props => [];
}

class MovieDetailInitial extends MovieDetailState {}

class MovieDetailLoading extends MovieDetailState {}

class MovieDetailLoaded extends MovieDetailState {
  final VideoDetail videoDetail;

  const MovieDetailLoaded({required this.videoDetail});

  @override
  List<Object> get props => [videoDetail];
}

class MovieDetailError extends MovieDetailState {
  final String message;

  const MovieDetailError({required this.message});

  @override
  List<Object> get props => [message];
}