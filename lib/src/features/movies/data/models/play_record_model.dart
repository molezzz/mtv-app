import 'package:freezed_annotation/freezed_annotation.dart';

part 'play_record_model.freezed.dart';
part 'play_record_model.g.dart';

@freezed
class PlayRecordModel with _$PlayRecordModel {
  const factory PlayRecordModel({
    @Default('') String title,
    @JsonKey(name: 'source_name') @Default('') String sourceName,
    @Default('') String cover,
    @Default(0) int index,
    @JsonKey(name: 'total_episodes') @Default(0) int totalEpisodes,
    @JsonKey(name: 'play_time') @Default(0) int playTime,
    @JsonKey(name: 'total_time') @Default(0) int totalTime,
    @JsonKey(name: 'save_time') @Default(0) int saveTime,
    @Default('') String year,
    @JsonKey(name: 'search_title') String? searchTitle,
  }) = _PlayRecordModel;

  factory PlayRecordModel.fromJson(Map<String, dynamic> json) =>
      _$PlayRecordModelFromJson(json);
}
