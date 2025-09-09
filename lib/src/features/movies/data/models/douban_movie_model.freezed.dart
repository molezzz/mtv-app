// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'douban_movie_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

DoubanMovieModel _$DoubanMovieModelFromJson(Map<String, dynamic> json) {
  return _DoubanMovieModel.fromJson(json);
}

/// @nodoc
mixin _$DoubanMovieModel {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  @JsonKey(name: 'poster')
  String? get pic => throw _privateConstructorUsedError;
  String? get year => throw _privateConstructorUsedError;
  @JsonKey(name: 'rate')
  String? get rateString => throw _privateConstructorUsedError; // API返回的是字符串
  String? get url => throw _privateConstructorUsedError;
  List<String>? get genres => throw _privateConstructorUsedError;
  List<String>? get directors => throw _privateConstructorUsedError;
  List<String>? get casts => throw _privateConstructorUsedError;

  /// Serializes this DoubanMovieModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DoubanMovieModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DoubanMovieModelCopyWith<DoubanMovieModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DoubanMovieModelCopyWith<$Res> {
  factory $DoubanMovieModelCopyWith(
          DoubanMovieModel value, $Res Function(DoubanMovieModel) then) =
      _$DoubanMovieModelCopyWithImpl<$Res, DoubanMovieModel>;
  @useResult
  $Res call(
      {String id,
      String title,
      @JsonKey(name: 'poster') String? pic,
      String? year,
      @JsonKey(name: 'rate') String? rateString,
      String? url,
      List<String>? genres,
      List<String>? directors,
      List<String>? casts});
}

/// @nodoc
class _$DoubanMovieModelCopyWithImpl<$Res, $Val extends DoubanMovieModel>
    implements $DoubanMovieModelCopyWith<$Res> {
  _$DoubanMovieModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DoubanMovieModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? pic = freezed,
    Object? year = freezed,
    Object? rateString = freezed,
    Object? url = freezed,
    Object? genres = freezed,
    Object? directors = freezed,
    Object? casts = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      pic: freezed == pic
          ? _value.pic
          : pic // ignore: cast_nullable_to_non_nullable
              as String?,
      year: freezed == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as String?,
      rateString: freezed == rateString
          ? _value.rateString
          : rateString // ignore: cast_nullable_to_non_nullable
              as String?,
      url: freezed == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String?,
      genres: freezed == genres
          ? _value.genres
          : genres // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      directors: freezed == directors
          ? _value.directors
          : directors // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      casts: freezed == casts
          ? _value.casts
          : casts // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DoubanMovieModelImplCopyWith<$Res>
    implements $DoubanMovieModelCopyWith<$Res> {
  factory _$$DoubanMovieModelImplCopyWith(_$DoubanMovieModelImpl value,
          $Res Function(_$DoubanMovieModelImpl) then) =
      __$$DoubanMovieModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      @JsonKey(name: 'poster') String? pic,
      String? year,
      @JsonKey(name: 'rate') String? rateString,
      String? url,
      List<String>? genres,
      List<String>? directors,
      List<String>? casts});
}

/// @nodoc
class __$$DoubanMovieModelImplCopyWithImpl<$Res>
    extends _$DoubanMovieModelCopyWithImpl<$Res, _$DoubanMovieModelImpl>
    implements _$$DoubanMovieModelImplCopyWith<$Res> {
  __$$DoubanMovieModelImplCopyWithImpl(_$DoubanMovieModelImpl _value,
      $Res Function(_$DoubanMovieModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of DoubanMovieModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? pic = freezed,
    Object? year = freezed,
    Object? rateString = freezed,
    Object? url = freezed,
    Object? genres = freezed,
    Object? directors = freezed,
    Object? casts = freezed,
  }) {
    return _then(_$DoubanMovieModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      pic: freezed == pic
          ? _value.pic
          : pic // ignore: cast_nullable_to_non_nullable
              as String?,
      year: freezed == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as String?,
      rateString: freezed == rateString
          ? _value.rateString
          : rateString // ignore: cast_nullable_to_non_nullable
              as String?,
      url: freezed == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String?,
      genres: freezed == genres
          ? _value._genres
          : genres // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      directors: freezed == directors
          ? _value._directors
          : directors // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      casts: freezed == casts
          ? _value._casts
          : casts // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DoubanMovieModelImpl extends _DoubanMovieModel {
  const _$DoubanMovieModelImpl(
      {required this.id,
      required this.title,
      @JsonKey(name: 'poster') this.pic,
      this.year,
      @JsonKey(name: 'rate') this.rateString,
      this.url,
      final List<String>? genres,
      final List<String>? directors,
      final List<String>? casts})
      : _genres = genres,
        _directors = directors,
        _casts = casts,
        super._();

  factory _$DoubanMovieModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$DoubanMovieModelImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  @JsonKey(name: 'poster')
  final String? pic;
  @override
  final String? year;
  @override
  @JsonKey(name: 'rate')
  final String? rateString;
// API返回的是字符串
  @override
  final String? url;
  final List<String>? _genres;
  @override
  List<String>? get genres {
    final value = _genres;
    if (value == null) return null;
    if (_genres is EqualUnmodifiableListView) return _genres;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _directors;
  @override
  List<String>? get directors {
    final value = _directors;
    if (value == null) return null;
    if (_directors is EqualUnmodifiableListView) return _directors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _casts;
  @override
  List<String>? get casts {
    final value = _casts;
    if (value == null) return null;
    if (_casts is EqualUnmodifiableListView) return _casts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'DoubanMovieModel(id: $id, title: $title, pic: $pic, year: $year, rateString: $rateString, url: $url, genres: $genres, directors: $directors, casts: $casts)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DoubanMovieModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.pic, pic) || other.pic == pic) &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.rateString, rateString) ||
                other.rateString == rateString) &&
            (identical(other.url, url) || other.url == url) &&
            const DeepCollectionEquality().equals(other._genres, _genres) &&
            const DeepCollectionEquality()
                .equals(other._directors, _directors) &&
            const DeepCollectionEquality().equals(other._casts, _casts));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      pic,
      year,
      rateString,
      url,
      const DeepCollectionEquality().hash(_genres),
      const DeepCollectionEquality().hash(_directors),
      const DeepCollectionEquality().hash(_casts));

  /// Create a copy of DoubanMovieModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DoubanMovieModelImplCopyWith<_$DoubanMovieModelImpl> get copyWith =>
      __$$DoubanMovieModelImplCopyWithImpl<_$DoubanMovieModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DoubanMovieModelImplToJson(
      this,
    );
  }
}

abstract class _DoubanMovieModel extends DoubanMovieModel {
  const factory _DoubanMovieModel(
      {required final String id,
      required final String title,
      @JsonKey(name: 'poster') final String? pic,
      final String? year,
      @JsonKey(name: 'rate') final String? rateString,
      final String? url,
      final List<String>? genres,
      final List<String>? directors,
      final List<String>? casts}) = _$DoubanMovieModelImpl;
  const _DoubanMovieModel._() : super._();

  factory _DoubanMovieModel.fromJson(Map<String, dynamic> json) =
      _$DoubanMovieModelImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  @JsonKey(name: 'poster')
  String? get pic;
  @override
  String? get year;
  @override
  @JsonKey(name: 'rate')
  String? get rateString; // API返回的是字符串
  @override
  String? get url;
  @override
  List<String>? get genres;
  @override
  List<String>? get directors;
  @override
  List<String>? get casts;

  /// Create a copy of DoubanMovieModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DoubanMovieModelImplCopyWith<_$DoubanMovieModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
