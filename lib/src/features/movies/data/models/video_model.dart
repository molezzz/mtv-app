import 'package:freezed_annotation/freezed_annotation.dart';

part 'video_model.freezed.dart';
part 'video_model.g.dart';

@freezed
class VideoModel with _$VideoModel {
  const factory VideoModel({
    @JsonKey(name: 'vod_id') required String id,
    @JsonKey(name: 'vod_name') required String title,
    @JsonKey(name: 'vod_content') String? description,
    @JsonKey(name: 'vod_pic') String? pic,
    @JsonKey(name: 'vod_year') String? year,
    @JsonKey(name: 'vod_remarks') String? note,
    @JsonKey(name: 'type_name') String? type,
    String? source,
  }) = _VideoModel;

  factory VideoModel.fromJson(Map<String, dynamic> json) =>
      _$VideoModelFromJson(json);
}