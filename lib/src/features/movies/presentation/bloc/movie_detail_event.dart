import 'package:equatable/equatable.dart';

abstract class MovieDetailEvent extends Equatable {
  const MovieDetailEvent();

  @override
  List<Object> get props => [];
}

class FetchVideoDetailEvent extends MovieDetailEvent {
  final String source;
  final String id;

  const FetchVideoDetailEvent({
    required this.source,
    required this.id,
  });

  @override
  List<Object> get props => [source, id];
}