// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'play_record_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PlayRecordModel _$PlayRecordModelFromJson(Map<String, dynamic> json) {
  return _PlayRecordModel.fromJson(json);
}

/// @nodoc
mixin _$PlayRecordModel {
  String get title => throw _privateConstructorUsedError;
  @JsonKey(name: 'source_name')
  String get sourceName => throw _privateConstructorUsedError;
  String get cover => throw _privateConstructorUsedError;
  int get index => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_episodes')
  int get totalEpisodes => throw _privateConstructorUsedError;
  @JsonKey(name: 'play_time')
  int get playTime => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_time')
  int get totalTime => throw _privateConstructorUsedError;
  @JsonKey(name: 'save_time')
  int get saveTime => throw _privateConstructorUsedError;
  String get year => throw _privateConstructorUsedError;
  @JsonKey(name: 'search_title')
  String? get searchTitle => throw _privateConstructorUsedError;

  /// Serializes this PlayRecordModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlayRecordModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlayRecordModelCopyWith<PlayRecordModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlayRecordModelCopyWith<$Res> {
  factory $PlayRecordModelCopyWith(
          PlayRecordModel value, $Res Function(PlayRecordModel) then) =
      _$PlayRecordModelCopyWithImpl<$Res, PlayRecordModel>;
  @useResult
  $Res call(
      {String title,
      @JsonKey(name: 'source_name') String sourceName,
      String cover,
      int index,
      @JsonKey(name: 'total_episodes') int totalEpisodes,
      @JsonKey(name: 'play_time') int playTime,
      @JsonKey(name: 'total_time') int totalTime,
      @JsonKey(name: 'save_time') int saveTime,
      String year,
      @JsonKey(name: 'search_title') String? searchTitle});
}

/// @nodoc
class _$PlayRecordModelCopyWithImpl<$Res, $Val extends PlayRecordModel>
    implements $PlayRecordModelCopyWith<$Res> {
  _$PlayRecordModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlayRecordModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? sourceName = null,
    Object? cover = null,
    Object? index = null,
    Object? totalEpisodes = null,
    Object? playTime = null,
    Object? totalTime = null,
    Object? saveTime = null,
    Object? year = null,
    Object? searchTitle = freezed,
  }) {
    return _then(_value.copyWith(
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      sourceName: null == sourceName
          ? _value.sourceName
          : sourceName // ignore: cast_nullable_to_non_nullable
              as String,
      cover: null == cover
          ? _value.cover
          : cover // ignore: cast_nullable_to_non_nullable
              as String,
      index: null == index
          ? _value.index
          : index // ignore: cast_nullable_to_non_nullable
              as int,
      totalEpisodes: null == totalEpisodes
          ? _value.totalEpisodes
          : totalEpisodes // ignore: cast_nullable_to_non_nullable
              as int,
      playTime: null == playTime
          ? _value.playTime
          : playTime // ignore: cast_nullable_to_non_nullable
              as int,
      totalTime: null == totalTime
          ? _value.totalTime
          : totalTime // ignore: cast_nullable_to_non_nullable
              as int,
      saveTime: null == saveTime
          ? _value.saveTime
          : saveTime // ignore: cast_nullable_to_non_nullable
              as int,
      year: null == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as String,
      searchTitle: freezed == searchTitle
          ? _value.searchTitle
          : searchTitle // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PlayRecordModelImplCopyWith<$Res>
    implements $PlayRecordModelCopyWith<$Res> {
  factory _$$PlayRecordModelImplCopyWith(_$PlayRecordModelImpl value,
          $Res Function(_$PlayRecordModelImpl) then) =
      __$$PlayRecordModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String title,
      @JsonKey(name: 'source_name') String sourceName,
      String cover,
      int index,
      @JsonKey(name: 'total_episodes') int totalEpisodes,
      @JsonKey(name: 'play_time') int playTime,
      @JsonKey(name: 'total_time') int totalTime,
      @JsonKey(name: 'save_time') int saveTime,
      String year,
      @JsonKey(name: 'search_title') String? searchTitle});
}

/// @nodoc
class __$$PlayRecordModelImplCopyWithImpl<$Res>
    extends _$PlayRecordModelCopyWithImpl<$Res, _$PlayRecordModelImpl>
    implements _$$PlayRecordModelImplCopyWith<$Res> {
  __$$PlayRecordModelImplCopyWithImpl(
      _$PlayRecordModelImpl _value, $Res Function(_$PlayRecordModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of PlayRecordModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? sourceName = null,
    Object? cover = null,
    Object? index = null,
    Object? totalEpisodes = null,
    Object? playTime = null,
    Object? totalTime = null,
    Object? saveTime = null,
    Object? year = null,
    Object? searchTitle = freezed,
  }) {
    return _then(_$PlayRecordModelImpl(
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      sourceName: null == sourceName
          ? _value.sourceName
          : sourceName // ignore: cast_nullable_to_non_nullable
              as String,
      cover: null == cover
          ? _value.cover
          : cover // ignore: cast_nullable_to_non_nullable
              as String,
      index: null == index
          ? _value.index
          : index // ignore: cast_nullable_to_non_nullable
              as int,
      totalEpisodes: null == totalEpisodes
          ? _value.totalEpisodes
          : totalEpisodes // ignore: cast_nullable_to_non_nullable
              as int,
      playTime: null == playTime
          ? _value.playTime
          : playTime // ignore: cast_nullable_to_non_nullable
              as int,
      totalTime: null == totalTime
          ? _value.totalTime
          : totalTime // ignore: cast_nullable_to_non_nullable
              as int,
      saveTime: null == saveTime
          ? _value.saveTime
          : saveTime // ignore: cast_nullable_to_non_nullable
              as int,
      year: null == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as String,
      searchTitle: freezed == searchTitle
          ? _value.searchTitle
          : searchTitle // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PlayRecordModelImpl implements _PlayRecordModel {
  const _$PlayRecordModelImpl(
      {this.title = '',
      @JsonKey(name: 'source_name') this.sourceName = '',
      this.cover = '',
      this.index = 0,
      @JsonKey(name: 'total_episodes') this.totalEpisodes = 0,
      @JsonKey(name: 'play_time') this.playTime = 0,
      @JsonKey(name: 'total_time') this.totalTime = 0,
      @JsonKey(name: 'save_time') this.saveTime = 0,
      this.year = '',
      @JsonKey(name: 'search_title') this.searchTitle});

  factory _$PlayRecordModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlayRecordModelImplFromJson(json);

  @override
  @JsonKey()
  final String title;
  @override
  @JsonKey(name: 'source_name')
  final String sourceName;
  @override
  @JsonKey()
  final String cover;
  @override
  @JsonKey()
  final int index;
  @override
  @JsonKey(name: 'total_episodes')
  final int totalEpisodes;
  @override
  @JsonKey(name: 'play_time')
  final int playTime;
  @override
  @JsonKey(name: 'total_time')
  final int totalTime;
  @override
  @JsonKey(name: 'save_time')
  final int saveTime;
  @override
  @JsonKey()
  final String year;
  @override
  @JsonKey(name: 'search_title')
  final String? searchTitle;

  @override
  String toString() {
    return 'PlayRecordModel(title: $title, sourceName: $sourceName, cover: $cover, index: $index, totalEpisodes: $totalEpisodes, playTime: $playTime, totalTime: $totalTime, saveTime: $saveTime, year: $year, searchTitle: $searchTitle)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayRecordModelImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.sourceName, sourceName) ||
                other.sourceName == sourceName) &&
            (identical(other.cover, cover) || other.cover == cover) &&
            (identical(other.index, index) || other.index == index) &&
            (identical(other.totalEpisodes, totalEpisodes) ||
                other.totalEpisodes == totalEpisodes) &&
            (identical(other.playTime, playTime) ||
                other.playTime == playTime) &&
            (identical(other.totalTime, totalTime) ||
                other.totalTime == totalTime) &&
            (identical(other.saveTime, saveTime) ||
                other.saveTime == saveTime) &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.searchTitle, searchTitle) ||
                other.searchTitle == searchTitle));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, title, sourceName, cover, index,
      totalEpisodes, playTime, totalTime, saveTime, year, searchTitle);

  /// Create a copy of PlayRecordModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayRecordModelImplCopyWith<_$PlayRecordModelImpl> get copyWith =>
      __$$PlayRecordModelImplCopyWithImpl<_$PlayRecordModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlayRecordModelImplToJson(
      this,
    );
  }
}

abstract class _PlayRecordModel implements PlayRecordModel {
  const factory _PlayRecordModel(
          {final String title,
          @JsonKey(name: 'source_name') final String sourceName,
          final String cover,
          final int index,
          @JsonKey(name: 'total_episodes') final int totalEpisodes,
          @JsonKey(name: 'play_time') final int playTime,
          @JsonKey(name: 'total_time') final int totalTime,
          @JsonKey(name: 'save_time') final int saveTime,
          final String year,
          @JsonKey(name: 'search_title') final String? searchTitle}) =
      _$PlayRecordModelImpl;

  factory _PlayRecordModel.fromJson(Map<String, dynamic> json) =
      _$PlayRecordModelImpl.fromJson;

  @override
  String get title;
  @override
  @JsonKey(name: 'source_name')
  String get sourceName;
  @override
  String get cover;
  @override
  int get index;
  @override
  @JsonKey(name: 'total_episodes')
  int get totalEpisodes;
  @override
  @JsonKey(name: 'play_time')
  int get playTime;
  @override
  @JsonKey(name: 'total_time')
  int get totalTime;
  @override
  @JsonKey(name: 'save_time')
  int get saveTime;
  @override
  String get year;
  @override
  @JsonKey(name: 'search_title')
  String? get searchTitle;

  /// Create a copy of PlayRecordModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayRecordModelImplCopyWith<_$PlayRecordModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
