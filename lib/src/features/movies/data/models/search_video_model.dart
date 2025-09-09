import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_video_model.freezed.dart';
part 'search_video_model.g.dart';

@freezed
class SearchVideoModel with _$SearchVideoModel {
  const factory SearchVideoModel({
    required String id,
    required String title,
    String? poster,
    List<String>? episodes,
    String? source,
    @JsonKey(name: 'source_name') String? sourceName,
    @JsonKey(name: 'class') String? category,
    String? year,
    String? desc,
    @JsonKey(name: 'type_name') String? type,
    @JsonKey(name: 'douban_id') int? doubanId,
  }) = _SearchVideoModel;

  factory SearchVideoModel.fromJson(Map<String, dynamic> json) =>
      _$SearchVideoModelFromJson(json);
}