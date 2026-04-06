// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AppSettings _$AppSettingsFromJson(Map<String, dynamic> json) {
  return _AppSettings.fromJson(json);
}

/// @nodoc
mixin _$AppSettings {
  String get clientId => throw _privateConstructorUsedError;
  String get clientSecret => throw _privateConstructorUsedError;
  String get redirectUri => throw _privateConstructorUsedError;
  String get downloadDir => throw _privateConstructorUsedError;
  int get concurrency => throw _privateConstructorUsedError;
  String get audioQuality => throw _privateConstructorUsedError;
  bool get isDarkMode => throw _privateConstructorUsedError;

  /// Serializes this AppSettings to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AppSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppSettingsCopyWith<AppSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppSettingsCopyWith<$Res> {
  factory $AppSettingsCopyWith(
    AppSettings value,
    $Res Function(AppSettings) then,
  ) = _$AppSettingsCopyWithImpl<$Res, AppSettings>;
  @useResult
  $Res call({
    String clientId,
    String clientSecret,
    String redirectUri,
    String downloadDir,
    int concurrency,
    String audioQuality,
    bool isDarkMode,
  });
}

/// @nodoc
class _$AppSettingsCopyWithImpl<$Res, $Val extends AppSettings>
    implements $AppSettingsCopyWith<$Res> {
  _$AppSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? clientId = null,
    Object? clientSecret = null,
    Object? redirectUri = null,
    Object? downloadDir = null,
    Object? concurrency = null,
    Object? audioQuality = null,
    Object? isDarkMode = null,
  }) {
    return _then(
      _value.copyWith(
            clientId: null == clientId
                ? _value.clientId
                : clientId // ignore: cast_nullable_to_non_nullable
                      as String,
            clientSecret: null == clientSecret
                ? _value.clientSecret
                : clientSecret // ignore: cast_nullable_to_non_nullable
                      as String,
            redirectUri: null == redirectUri
                ? _value.redirectUri
                : redirectUri // ignore: cast_nullable_to_non_nullable
                      as String,
            downloadDir: null == downloadDir
                ? _value.downloadDir
                : downloadDir // ignore: cast_nullable_to_non_nullable
                      as String,
            concurrency: null == concurrency
                ? _value.concurrency
                : concurrency // ignore: cast_nullable_to_non_nullable
                      as int,
            audioQuality: null == audioQuality
                ? _value.audioQuality
                : audioQuality // ignore: cast_nullable_to_non_nullable
                      as String,
            isDarkMode: null == isDarkMode
                ? _value.isDarkMode
                : isDarkMode // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AppSettingsImplCopyWith<$Res>
    implements $AppSettingsCopyWith<$Res> {
  factory _$$AppSettingsImplCopyWith(
    _$AppSettingsImpl value,
    $Res Function(_$AppSettingsImpl) then,
  ) = __$$AppSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String clientId,
    String clientSecret,
    String redirectUri,
    String downloadDir,
    int concurrency,
    String audioQuality,
    bool isDarkMode,
  });
}

/// @nodoc
class __$$AppSettingsImplCopyWithImpl<$Res>
    extends _$AppSettingsCopyWithImpl<$Res, _$AppSettingsImpl>
    implements _$$AppSettingsImplCopyWith<$Res> {
  __$$AppSettingsImplCopyWithImpl(
    _$AppSettingsImpl _value,
    $Res Function(_$AppSettingsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? clientId = null,
    Object? clientSecret = null,
    Object? redirectUri = null,
    Object? downloadDir = null,
    Object? concurrency = null,
    Object? audioQuality = null,
    Object? isDarkMode = null,
  }) {
    return _then(
      _$AppSettingsImpl(
        clientId: null == clientId
            ? _value.clientId
            : clientId // ignore: cast_nullable_to_non_nullable
                  as String,
        clientSecret: null == clientSecret
            ? _value.clientSecret
            : clientSecret // ignore: cast_nullable_to_non_nullable
                  as String,
        redirectUri: null == redirectUri
            ? _value.redirectUri
            : redirectUri // ignore: cast_nullable_to_non_nullable
                  as String,
        downloadDir: null == downloadDir
            ? _value.downloadDir
            : downloadDir // ignore: cast_nullable_to_non_nullable
                  as String,
        concurrency: null == concurrency
            ? _value.concurrency
            : concurrency // ignore: cast_nullable_to_non_nullable
                  as int,
        audioQuality: null == audioQuality
            ? _value.audioQuality
            : audioQuality // ignore: cast_nullable_to_non_nullable
                  as String,
        isDarkMode: null == isDarkMode
            ? _value.isDarkMode
            : isDarkMode // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AppSettingsImpl implements _AppSettings {
  const _$AppSettingsImpl({
    this.clientId = '',
    this.clientSecret = '',
    this.redirectUri = 'http://127.0.0.1:8888/callback',
    this.downloadDir = '',
    this.concurrency = 8,
    this.audioQuality = '0',
    this.isDarkMode = false,
  });

  factory _$AppSettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$AppSettingsImplFromJson(json);

  @override
  @JsonKey()
  final String clientId;
  @override
  @JsonKey()
  final String clientSecret;
  @override
  @JsonKey()
  final String redirectUri;
  @override
  @JsonKey()
  final String downloadDir;
  @override
  @JsonKey()
  final int concurrency;
  @override
  @JsonKey()
  final String audioQuality;
  @override
  @JsonKey()
  final bool isDarkMode;

  @override
  String toString() {
    return 'AppSettings(clientId: $clientId, clientSecret: $clientSecret, redirectUri: $redirectUri, downloadDir: $downloadDir, concurrency: $concurrency, audioQuality: $audioQuality, isDarkMode: $isDarkMode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppSettingsImpl &&
            (identical(other.clientId, clientId) ||
                other.clientId == clientId) &&
            (identical(other.clientSecret, clientSecret) ||
                other.clientSecret == clientSecret) &&
            (identical(other.redirectUri, redirectUri) ||
                other.redirectUri == redirectUri) &&
            (identical(other.downloadDir, downloadDir) ||
                other.downloadDir == downloadDir) &&
            (identical(other.concurrency, concurrency) ||
                other.concurrency == concurrency) &&
            (identical(other.audioQuality, audioQuality) ||
                other.audioQuality == audioQuality) &&
            (identical(other.isDarkMode, isDarkMode) ||
                other.isDarkMode == isDarkMode));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    clientId,
    clientSecret,
    redirectUri,
    downloadDir,
    concurrency,
    audioQuality,
    isDarkMode,
  );

  /// Create a copy of AppSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppSettingsImplCopyWith<_$AppSettingsImpl> get copyWith =>
      __$$AppSettingsImplCopyWithImpl<_$AppSettingsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AppSettingsImplToJson(this);
  }
}

abstract class _AppSettings implements AppSettings {
  const factory _AppSettings({
    final String clientId,
    final String clientSecret,
    final String redirectUri,
    final String downloadDir,
    final int concurrency,
    final String audioQuality,
    final bool isDarkMode,
  }) = _$AppSettingsImpl;

  factory _AppSettings.fromJson(Map<String, dynamic> json) =
      _$AppSettingsImpl.fromJson;

  @override
  String get clientId;
  @override
  String get clientSecret;
  @override
  String get redirectUri;
  @override
  String get downloadDir;
  @override
  int get concurrency;
  @override
  String get audioQuality;
  @override
  bool get isDarkMode;

  /// Create a copy of AppSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppSettingsImplCopyWith<_$AppSettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
