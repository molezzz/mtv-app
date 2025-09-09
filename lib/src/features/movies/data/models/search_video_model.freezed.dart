// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_video_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SearchVideoModel _$SearchVideoModelFromJson(Map<String, dynamic> json) {
  return _SearchVideoModel.fromJson(json);
}

/// @nodoc
mixin _$SearchVideoModel {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get poster => throw _privateConstructorUsedError;
  List<String>? get episodes => throw _privateConstructorUsedError;
  String? get source => throw _privateConstructorUsedError;
  @JsonKey(name: 'source_name')
  String? get sourceName => throw _privateConstructorUsedError;
  @JsonKey(name: 'class')
  String? get category => throw _privateConstructorUsedError;
  String? get year => throw _privateConstructorUsedError;
  String? get desc => throw _privateConstructorUsedError;
  @JsonKey(name: 'type_name')
  String? get type => throw _privateConstructorUsedError;
  @JsonKey(name: 'douban_id')
  int? get doubanId => throw _privateConstructorUsedError;

  /// Serializes this SearchVideoModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SearchVideoModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SearchVideoModelCopyWith<SearchVideoModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SearchVideoModelCopyWith<$Res> {
  factory $SearchVideoModelCopyWith(
          SearchVideoModel value, $Res Function(SearchVideoModel) then) =
      _$SearchVideoModelCopyWithImpl<$Res, SearchVideoModel>;
  @useResult
  $Res call(
      {String id,
      String title,
      String? poster,
      List<String>? episodes,
      String? source,
      @JsonKey(name: 'source_name') String? sourceName,
      @JsonKey(name: 'class') String? category,
      String? year,
      String? desc,
      @JsonKey(name: 'type_name') String? type,
      @JsonKey(name: 'douban_id') int? doubanId});
}

/// @nodoc
class _$SearchVideoModelCopyWithImpl<$Res, $Val extends SearchVideoModel>
    implements $SearchVideoModelCopyWith<$Res> {
  _$SearchVideoModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SearchVideoModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? poster = freezed,
    Object? episodes = freezed,
    Object? source = freezed,
    Object? sourceName = freezed,
    Object? category = freezed,
    Object? year = freezed,
    Object? desc = freezed,
    Object? type = freezed,
    Object? doubanId = freezed,
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
      poster: freezed == poster
          ? _value.poster
          : poster // ignore: cast_nullable_to_non_nullable
              as String?,
      episodes: freezed == episodes
          ? _value.episodes
          : episodes // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      source: freezed == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String?,
      sourceName: freezed == sourceName
          ? _value.sourceName
          : sourceName // ignore: cast_nullable_to_non_nullable
              as String?,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
      year: freezed == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as String?,
      desc: freezed == desc
          ? _value.desc
          : desc // ignore: cast_nullable_to_non_nullable
              as String?,
      type: freezed == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String?,
      doubanId: freezed == doubanId
          ? _value.doubanId
          : doubanId // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SearchVideoModelImplCopyWith<$Res>
    implements $SearchVideoModelCopyWith<$Res> {
  factory _$$SearchVideoModelImplCopyWith(_$SearchVideoModelImpl value,
          $Res Function(_$SearchVideoModelImpl) then) =
      __$$SearchVideoModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String? poster,
      List<String>? episodes,
      String? source,
      @JsonKey(name: 'source_name') String? sourceName,
      @JsonKey(name: 'class') String? category,
      String? year,
      String? desc,
      @JsonKey(name: 'type_name') String? type,
      @JsonKey(name: 'douban_id') int? doubanId});
}

/// @nodoc
class __$$SearchVideoModelImplCopyWithImpl<$Res>
    extends _$SearchVideoModelCopyWithImpl<$Res, _$SearchVideoModelImpl>
    implements _$$SearchVideoModelImplCopyWith<$Res> {
  __$$SearchVideoModelImplCopyWithImpl(_$SearchVideoModelImpl _value,
      $Res Function(_$SearchVideoModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of SearchVideoModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? poster = freezed,
    Object? episodes = freezed,
    Object? source = freezed,
    Object? sourceName = freezed,
    Object? category = freezed,
    Object? year = freezed,
    Object? desc = freezed,
    Object? type = freezed,
    Object? doubanId = freezed,
  }) {
    return _then(_$SearchVideoModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      poster: freezed == poster
          ? _value.poster
          : poster // ignore: cast_nullable_to_non_nullable
              as String?,
      episodes: freezed == episodes
          ? _value._episodes
          : episodes // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      source: freezed == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String?,
      sourceName: freezed == sourceName
          ? _value.sourceName
          : sourceName // ignore: cast_nullable_to_non_nullable
              as String?,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
      year: freezed == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as String?,
      desc: freezed == desc
          ? _value.desc
          : desc // ignore: cast_nullable_to_non_nullable
              as String?,
      type: freezed == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String?,
      doubanId: freezed == doubanId
          ? _value.doubanId
          : doubanId // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SearchVideoModelImpl implements _SearchVideoModel {
  const _$SearchVideoModelImpl(
      {required this.id,
      required this.title,
      this.poster,
      final List<String>? episodes,
      this.source,
      @JsonKey(name: 'source_name') this.sourceName,
      @JsonKey(name: 'class') this.category,
      this.year,
      this.desc,
      @JsonKey(name: 'type_name') this.type,
      @JsonKey(name: 'douban_id') this.doubanId})
      : _episodes = episodes;

  factory _$SearchVideoModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$SearchVideoModelImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String? poster;
  final List<String>? _episodes;
  @override
  List<String>? get episodes {
    final value = _episodes;
    if (value == null) return null;
    if (_episodes is EqualUnmodifiableListView) return _episodes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? source;
  @override
  @JsonKey(name: 'source_name')
  final String? sourceName;
  @override
  @JsonKey(name: 'class')
  final String? category;
  @override
  final String? year;
  @override
  final String? desc;
  @override
  @JsonKey(name: 'type_name')
  final String? type;
  @override
  @JsonKey(name: 'douban_id')
  final int? doubanId;

  @override
  String toString() {
    return 'SearchVideoModel(id: $id, title: $title, poster: $poster, episodes: $episodes, source: $source, sourceName: $sourceName, category: $category, year: $year, desc: $desc, type: $type, doubanId: $doubanId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SearchVideoModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.poster, poster) || other.poster == poster) &&
            const DeepCollectionEquality().equals(other._episodes, _episodes) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.sourceName, sourceName) ||
                other.sourceName == sourceName) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.desc, desc) || other.desc == desc) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.doubanId, doubanId) ||
                other.doubanId == doubanId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      poster,
      const DeepCollectionEquality().hash(_episodes),
      source,
      sourceName,
      category,
      year,
      desc,
      type,
      doubanId);

  /// Create a copy of SearchVideoModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SearchVideoModelImplCopyWith<_$SearchVideoModelImpl> get copyWith =>
      __$$SearchVideoModelImplCopyWithImpl<_$SearchVideoModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SearchVideoModelImplToJson(
      this,
    );
  }
}

abstract class _SearchVideoModel implements SearchVideoModel {
  const factory _SearchVideoModel(
          {required final String id,
          required final String title,
          final String? poster,
          final List<String>? episodes,
          final String? source,
          @JsonKey(name: 'source_name') final String? sourceName,
          @JsonKey(name: 'class') final String? category,
          final String? year,
          final String? desc,
          @JsonKey(name: 'type_name') final String? type,
          @JsonKey(name: 'douban_id') final int? doubanId}) =
      _$SearchVideoModelImpl;

  factory _SearchVideoModel.fromJson(Map<String, dynamic> json) =
      _$SearchVideoModelImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String? get poster;
  @override
  List<String>? get episodes;
  @override
  String? get source;
  @override
  @JsonKey(name: 'source_name')
  String? get sourceName;
  @override
  @JsonKey(name: 'class')
  String? get category;
  @override
  String? get year;
  @override
  String? get desc;
  @override
  @JsonKey(name: 'type_name')
  String? get type;
  @override
  @JsonKey(name: 'douban_id')
  int? get doubanId;

  /// Create a copy of SearchVideoModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SearchVideoModelImplCopyWith<_$SearchVideoModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
