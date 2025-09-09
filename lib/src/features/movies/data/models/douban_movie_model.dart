import 'package:freezed_annotation/freezed_annotation.dart';

part 'douban_movie_model.freezed.dart';
part 'douban_movie_model.g.dart';

@freezed
class DoubanMovieModel with _$DoubanMovieModel {
  const factory DoubanMovieModel({
    required String id,
    required String title,
    @JsonKey(name: 'poster') String? pic,
    String? year,
    @JsonKey(name: 'rate') String? rateString, // API返回的是字符串
    String? url,
    List<String>? genres,
    List<String>? directors,
    List<String>? casts,
  }) = _DoubanMovieModel;

  const DoubanMovieModel._();

  factory DoubanMovieModel.fromJson(Map<String, dynamic> json) =>
      _$DoubanMovieModelFromJson(json);

  // 获取数字评分
  double? get rating {
    if (rateString == null || rateString!.isEmpty) return null;
    return double.tryParse(rateString!);
  }
}