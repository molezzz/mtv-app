// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'video_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

VideoModel _$VideoModelFromJson(Map<String, dynamic> json) {
  return _VideoModel.fromJson(json);
}

/// @nodoc
mixin _$VideoModel {
  @JsonKey(name: 'vod_id')
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'vod_name')
  String get title => throw _privateConstructorUsedError;
  @JsonKey(name: 'vod_content')
  String? get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'vod_pic')
  String? get pic => throw _privateConstructorUsedError;
  @JsonKey(name: 'vod_year')
  String? get year => throw _privateConstructorUsedError;
  @JsonKey(name: 'vod_remarks')
  String? get note => throw _privateConstructorUsedError;
  @JsonKey(name: 'type_name')
  String? get type => throw _privateConstructorUsedError;
  String? get source => throw _privateConstructorUsedError;

  /// Serializes this VideoModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VideoModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VideoModelCopyWith<VideoModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VideoModelCopyWith<$Res> {
  factory $VideoModelCopyWith(
          VideoModel value, $Res Function(VideoModel) then) =
      _$VideoModelCopyWithImpl<$Res, VideoModel>;
  @useResult
  $Res call(
      {@JsonKey(name: 'vod_id') String id,
      @JsonKey(name: 'vod_name') String title,
      @JsonKey(name: 'vod_content') String? description,
      @JsonKey(name: 'vod_pic') String? pic,
      @JsonKey(name: 'vod_year') String? year,
      @JsonKey(name: 'vod_remarks') String? note,
      @JsonKey(name: 'type_name') String? type,
      String? source});
}

/// @nodoc
class _$VideoModelCopyWithImpl<$Res, $Val extends VideoModel>
    implements $VideoModelCopyWith<$Res> {
  _$VideoModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VideoModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = freezed,
    Object? pic = freezed,
    Object? year = freezed,
    Object? note = freezed,
    Object? type = freezed,
    Object? source = freezed,
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
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      pic: freezed == pic
          ? _value.pic
          : pic // ignore: cast_nullable_to_non_nullable
              as String?,
      year: freezed == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as String?,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      type: freezed == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String?,
      source: freezed == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VideoModelImplCopyWith<$Res>
    implements $VideoModelCopyWith<$Res> {
  factory _$$VideoModelImplCopyWith(
          _$VideoModelImpl value, $Res Function(_$VideoModelImpl) then) =
      __$$VideoModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'vod_id') String id,
      @JsonKey(name: 'vod_name') String title,
      @JsonKey(name: 'vod_content') String? description,
      @JsonKey(name: 'vod_pic') String? pic,
      @JsonKey(name: 'vod_year') String? year,
      @JsonKey(name: 'vod_remarks') String? note,
      @JsonKey(name: 'type_name') String? type,
      String? source});
}

/// @nodoc
class __$$VideoModelImplCopyWithImpl<$Res>
    extends _$VideoModelCopyWithImpl<$Res, _$VideoModelImpl>
    implements _$$VideoModelImplCopyWith<$Res> {
  __$$VideoModelImplCopyWithImpl(
      _$VideoModelImpl _value, $Res Function(_$VideoModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of VideoModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = freezed,
    Object? pic = freezed,
    Object? year = freezed,
    Object? note = freezed,
    Object? type = freezed,
    Object? source = freezed,
  }) {
    return _then(_$VideoModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      pic: freezed == pic
          ? _value.pic
          : pic // ignore: cast_nullable_to_non_nullable
              as String?,
      year: freezed == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as String?,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      type: freezed == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String?,
      source: freezed == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VideoModelImpl implements _VideoModel {
  const _$VideoModelImpl(
      {@JsonKey(name: 'vod_id') required this.id,
      @JsonKey(name: 'vod_name') required this.title,
      @JsonKey(name: 'vod_content') this.description,
      @JsonKey(name: 'vod_pic') this.pic,
      @JsonKey(name: 'vod_year') this.year,
      @JsonKey(name: 'vod_remarks') this.note,
      @JsonKey(name: 'type_name') this.type,
      this.source});

  factory _$VideoModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$VideoModelImplFromJson(json);

  @override
  @JsonKey(name: 'vod_id')
  final String id;
  @override
  @JsonKey(name: 'vod_name')
  final String title;
  @override
  @JsonKey(name: 'vod_content')
  final String? description;
  @override
  @JsonKey(name: 'vod_pic')
  final String? pic;
  @override
  @JsonKey(name: 'vod_year')
  final String? year;
  @override
  @JsonKey(name: 'vod_remarks')
  final String? note;
  @override
  @JsonKey(name: 'type_name')
  final String? type;
  @override
  final String? source;

  @override
  String toString() {
    return 'VideoModel(id: $id, title: $title, description: $description, pic: $pic, year: $year, note: $note, type: $type, source: $source)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VideoModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.pic, pic) || other.pic == pic) &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.source, source) || other.source == source));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, title, description, pic, year, note, type, source);

  /// Create a copy of VideoModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VideoModelImplCopyWith<_$VideoModelImpl> get copyWith =>
      __$$VideoModelImplCopyWithImpl<_$VideoModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VideoModelImplToJson(
      this,
    );
  }
}

abstract class _VideoModel implements VideoModel {
  const factory _VideoModel(
      {@JsonKey(name: 'vod_id') required final String id,
      @JsonKey(name: 'vod_name') required final String title,
      @JsonKey(name: 'vod_content') final String? description,
      @JsonKey(name: 'vod_pic') final String? pic,
      @JsonKey(name: 'vod_year') final String? year,
      @JsonKey(name: 'vod_remarks') final String? note,
      @JsonKey(name: 'type_name') final String? type,
      final String? source}) = _$VideoModelImpl;

  factory _VideoModel.fromJson(Map<String, dynamic> json) =
      _$VideoModelImpl.fromJson;

  @override
  @JsonKey(name: 'vod_id')
  String get id;
  @override
  @JsonKey(name: 'vod_name')
  String get title;
  @override
  @JsonKey(name: 'vod_content')
  String? get description;
  @override
  @JsonKey(name: 'vod_pic')
  String? get pic;
  @override
  @JsonKey(name: 'vod_year')
  String? get year;
  @override
  @JsonKey(name: 'vod_remarks')
  String? get note;
  @override
  @JsonKey(name: 'type_name')
  String? get type;
  @override
  String? get source;

  /// Create a copy of VideoModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VideoModelImplCopyWith<_$VideoModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
