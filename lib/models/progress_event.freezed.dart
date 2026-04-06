// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'progress_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ProgressEvent _$ProgressEventFromJson(Map<String, dynamic> json) {
  return _ProgressEvent.fromJson(json);
}

/// @nodoc
mixin _$ProgressEvent {
  String get type => throw _privateConstructorUsedError;
  Map<String, dynamic> get data => throw _privateConstructorUsedError;
  double get timestamp => throw _privateConstructorUsedError;

  /// Serializes this ProgressEvent to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProgressEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProgressEventCopyWith<ProgressEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProgressEventCopyWith<$Res> {
  factory $ProgressEventCopyWith(
    ProgressEvent value,
    $Res Function(ProgressEvent) then,
  ) = _$ProgressEventCopyWithImpl<$Res, ProgressEvent>;
  @useResult
  $Res call({String type, Map<String, dynamic> data, double timestamp});
}

/// @nodoc
class _$ProgressEventCopyWithImpl<$Res, $Val extends ProgressEvent>
    implements $ProgressEventCopyWith<$Res> {
  _$ProgressEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProgressEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? data = null,
    Object? timestamp = null,
  }) {
    return _then(
      _value.copyWith(
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            data: null == data
                ? _value.data
                : data // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ProgressEventImplCopyWith<$Res>
    implements $ProgressEventCopyWith<$Res> {
  factory _$$ProgressEventImplCopyWith(
    _$ProgressEventImpl value,
    $Res Function(_$ProgressEventImpl) then,
  ) = __$$ProgressEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String type, Map<String, dynamic> data, double timestamp});
}

/// @nodoc
class __$$ProgressEventImplCopyWithImpl<$Res>
    extends _$ProgressEventCopyWithImpl<$Res, _$ProgressEventImpl>
    implements _$$ProgressEventImplCopyWith<$Res> {
  __$$ProgressEventImplCopyWithImpl(
    _$ProgressEventImpl _value,
    $Res Function(_$ProgressEventImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ProgressEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? data = null,
    Object? timestamp = null,
  }) {
    return _then(
      _$ProgressEventImpl(
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        data: null == data
            ? _value._data
            : data // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ProgressEventImpl implements _ProgressEvent {
  const _$ProgressEventImpl({
    required this.type,
    required final Map<String, dynamic> data,
    this.timestamp = 0,
  }) : _data = data;

  factory _$ProgressEventImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProgressEventImplFromJson(json);

  @override
  final String type;
  final Map<String, dynamic> _data;
  @override
  Map<String, dynamic> get data {
    if (_data is EqualUnmodifiableMapView) return _data;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_data);
  }

  @override
  @JsonKey()
  final double timestamp;

  @override
  String toString() {
    return 'ProgressEvent(type: $type, data: $data, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProgressEventImpl &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality().equals(other._data, _data) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    type,
    const DeepCollectionEquality().hash(_data),
    timestamp,
  );

  /// Create a copy of ProgressEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProgressEventImplCopyWith<_$ProgressEventImpl> get copyWith =>
      __$$ProgressEventImplCopyWithImpl<_$ProgressEventImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProgressEventImplToJson(this);
  }
}

abstract class _ProgressEvent implements ProgressEvent {
  const factory _ProgressEvent({
    required final String type,
    required final Map<String, dynamic> data,
    final double timestamp,
  }) = _$ProgressEventImpl;

  factory _ProgressEvent.fromJson(Map<String, dynamic> json) =
      _$ProgressEventImpl.fromJson;

  @override
  String get type;
  @override
  Map<String, dynamic> get data;
  @override
  double get timestamp;

  /// Create a copy of ProgressEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProgressEventImplCopyWith<_$ProgressEventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
