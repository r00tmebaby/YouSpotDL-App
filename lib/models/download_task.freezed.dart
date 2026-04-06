// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'download_task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

DownloadTask _$DownloadTaskFromJson(Map<String, dynamic> json) {
  return _DownloadTask.fromJson(json);
}

/// @nodoc
mixin _$DownloadTask {
  String get id => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;
  Platform get platform => throw _privateConstructorUsedError;
  String get playlistName => throw _privateConstructorUsedError;
  int get totalSongs => throw _privateConstructorUsedError;
  int get downloadedSongs => throw _privateConstructorUsedError;
  int get errorCount => throw _privateConstructorUsedError;
  DownloadStatus get status => throw _privateConstructorUsedError;
  List<SongProgress> get songs => throw _privateConstructorUsedError;
  String? get formatSelector => throw _privateConstructorUsedError;
  String? get outputExt => throw _privateConstructorUsedError;

  /// Serializes this DownloadTask to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DownloadTask
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DownloadTaskCopyWith<DownloadTask> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DownloadTaskCopyWith<$Res> {
  factory $DownloadTaskCopyWith(
    DownloadTask value,
    $Res Function(DownloadTask) then,
  ) = _$DownloadTaskCopyWithImpl<$Res, DownloadTask>;
  @useResult
  $Res call({
    String id,
    String url,
    Platform platform,
    String playlistName,
    int totalSongs,
    int downloadedSongs,
    int errorCount,
    DownloadStatus status,
    List<SongProgress> songs,
    String? formatSelector,
    String? outputExt,
  });
}

/// @nodoc
class _$DownloadTaskCopyWithImpl<$Res, $Val extends DownloadTask>
    implements $DownloadTaskCopyWith<$Res> {
  _$DownloadTaskCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DownloadTask
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? url = null,
    Object? platform = null,
    Object? playlistName = null,
    Object? totalSongs = null,
    Object? downloadedSongs = null,
    Object? errorCount = null,
    Object? status = null,
    Object? songs = null,
    Object? formatSelector = freezed,
    Object? outputExt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            url: null == url
                ? _value.url
                : url // ignore: cast_nullable_to_non_nullable
                      as String,
            platform: null == platform
                ? _value.platform
                : platform // ignore: cast_nullable_to_non_nullable
                      as Platform,
            playlistName: null == playlistName
                ? _value.playlistName
                : playlistName // ignore: cast_nullable_to_non_nullable
                      as String,
            totalSongs: null == totalSongs
                ? _value.totalSongs
                : totalSongs // ignore: cast_nullable_to_non_nullable
                      as int,
            downloadedSongs: null == downloadedSongs
                ? _value.downloadedSongs
                : downloadedSongs // ignore: cast_nullable_to_non_nullable
                      as int,
            errorCount: null == errorCount
                ? _value.errorCount
                : errorCount // ignore: cast_nullable_to_non_nullable
                      as int,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as DownloadStatus,
            songs: null == songs
                ? _value.songs
                : songs // ignore: cast_nullable_to_non_nullable
                      as List<SongProgress>,
            formatSelector: freezed == formatSelector
                ? _value.formatSelector
                : formatSelector // ignore: cast_nullable_to_non_nullable
                      as String?,
            outputExt: freezed == outputExt
                ? _value.outputExt
                : outputExt // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DownloadTaskImplCopyWith<$Res>
    implements $DownloadTaskCopyWith<$Res> {
  factory _$$DownloadTaskImplCopyWith(
    _$DownloadTaskImpl value,
    $Res Function(_$DownloadTaskImpl) then,
  ) = __$$DownloadTaskImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String url,
    Platform platform,
    String playlistName,
    int totalSongs,
    int downloadedSongs,
    int errorCount,
    DownloadStatus status,
    List<SongProgress> songs,
    String? formatSelector,
    String? outputExt,
  });
}

/// @nodoc
class __$$DownloadTaskImplCopyWithImpl<$Res>
    extends _$DownloadTaskCopyWithImpl<$Res, _$DownloadTaskImpl>
    implements _$$DownloadTaskImplCopyWith<$Res> {
  __$$DownloadTaskImplCopyWithImpl(
    _$DownloadTaskImpl _value,
    $Res Function(_$DownloadTaskImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DownloadTask
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? url = null,
    Object? platform = null,
    Object? playlistName = null,
    Object? totalSongs = null,
    Object? downloadedSongs = null,
    Object? errorCount = null,
    Object? status = null,
    Object? songs = null,
    Object? formatSelector = freezed,
    Object? outputExt = freezed,
  }) {
    return _then(
      _$DownloadTaskImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        url: null == url
            ? _value.url
            : url // ignore: cast_nullable_to_non_nullable
                  as String,
        platform: null == platform
            ? _value.platform
            : platform // ignore: cast_nullable_to_non_nullable
                  as Platform,
        playlistName: null == playlistName
            ? _value.playlistName
            : playlistName // ignore: cast_nullable_to_non_nullable
                  as String,
        totalSongs: null == totalSongs
            ? _value.totalSongs
            : totalSongs // ignore: cast_nullable_to_non_nullable
                  as int,
        downloadedSongs: null == downloadedSongs
            ? _value.downloadedSongs
            : downloadedSongs // ignore: cast_nullable_to_non_nullable
                  as int,
        errorCount: null == errorCount
            ? _value.errorCount
            : errorCount // ignore: cast_nullable_to_non_nullable
                  as int,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as DownloadStatus,
        songs: null == songs
            ? _value._songs
            : songs // ignore: cast_nullable_to_non_nullable
                  as List<SongProgress>,
        formatSelector: freezed == formatSelector
            ? _value.formatSelector
            : formatSelector // ignore: cast_nullable_to_non_nullable
                  as String?,
        outputExt: freezed == outputExt
            ? _value.outputExt
            : outputExt // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DownloadTaskImpl implements _DownloadTask {
  const _$DownloadTaskImpl({
    required this.id,
    required this.url,
    required this.platform,
    this.playlistName = '',
    this.totalSongs = 0,
    this.downloadedSongs = 0,
    this.errorCount = 0,
    this.status = DownloadStatus.pending,
    final List<SongProgress> songs = const [],
    this.formatSelector,
    this.outputExt,
  }) : _songs = songs;

  factory _$DownloadTaskImpl.fromJson(Map<String, dynamic> json) =>
      _$$DownloadTaskImplFromJson(json);

  @override
  final String id;
  @override
  final String url;
  @override
  final Platform platform;
  @override
  @JsonKey()
  final String playlistName;
  @override
  @JsonKey()
  final int totalSongs;
  @override
  @JsonKey()
  final int downloadedSongs;
  @override
  @JsonKey()
  final int errorCount;
  @override
  @JsonKey()
  final DownloadStatus status;
  final List<SongProgress> _songs;
  @override
  @JsonKey()
  List<SongProgress> get songs {
    if (_songs is EqualUnmodifiableListView) return _songs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_songs);
  }

  @override
  final String? formatSelector;
  @override
  final String? outputExt;

  @override
  String toString() {
    return 'DownloadTask(id: $id, url: $url, platform: $platform, playlistName: $playlistName, totalSongs: $totalSongs, downloadedSongs: $downloadedSongs, errorCount: $errorCount, status: $status, songs: $songs, formatSelector: $formatSelector, outputExt: $outputExt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DownloadTaskImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.platform, platform) ||
                other.platform == platform) &&
            (identical(other.playlistName, playlistName) ||
                other.playlistName == playlistName) &&
            (identical(other.totalSongs, totalSongs) ||
                other.totalSongs == totalSongs) &&
            (identical(other.downloadedSongs, downloadedSongs) ||
                other.downloadedSongs == downloadedSongs) &&
            (identical(other.errorCount, errorCount) ||
                other.errorCount == errorCount) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(other._songs, _songs) &&
            (identical(other.formatSelector, formatSelector) ||
                other.formatSelector == formatSelector) &&
            (identical(other.outputExt, outputExt) ||
                other.outputExt == outputExt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    url,
    platform,
    playlistName,
    totalSongs,
    downloadedSongs,
    errorCount,
    status,
    const DeepCollectionEquality().hash(_songs),
    formatSelector,
    outputExt,
  );

  /// Create a copy of DownloadTask
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DownloadTaskImplCopyWith<_$DownloadTaskImpl> get copyWith =>
      __$$DownloadTaskImplCopyWithImpl<_$DownloadTaskImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DownloadTaskImplToJson(this);
  }
}

abstract class _DownloadTask implements DownloadTask {
  const factory _DownloadTask({
    required final String id,
    required final String url,
    required final Platform platform,
    final String playlistName,
    final int totalSongs,
    final int downloadedSongs,
    final int errorCount,
    final DownloadStatus status,
    final List<SongProgress> songs,
    final String? formatSelector,
    final String? outputExt,
  }) = _$DownloadTaskImpl;

  factory _DownloadTask.fromJson(Map<String, dynamic> json) =
      _$DownloadTaskImpl.fromJson;

  @override
  String get id;
  @override
  String get url;
  @override
  Platform get platform;
  @override
  String get playlistName;
  @override
  int get totalSongs;
  @override
  int get downloadedSongs;
  @override
  int get errorCount;
  @override
  DownloadStatus get status;
  @override
  List<SongProgress> get songs;
  @override
  String? get formatSelector;
  @override
  String? get outputExt;

  /// Create a copy of DownloadTask
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DownloadTaskImplCopyWith<_$DownloadTaskImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SongProgress _$SongProgressFromJson(Map<String, dynamic> json) {
  return _SongProgress.fromJson(json);
}

/// @nodoc
mixin _$SongProgress {
  int get index => throw _privateConstructorUsedError;
  String get query => throw _privateConstructorUsedError;
  double get percent => throw _privateConstructorUsedError;
  String get speed => throw _privateConstructorUsedError;
  String get eta => throw _privateConstructorUsedError;
  bool get completed => throw _privateConstructorUsedError;
  bool get error => throw _privateConstructorUsedError;
  bool get skipped => throw _privateConstructorUsedError;
  String get filePath => throw _privateConstructorUsedError;

  /// Serializes this SongProgress to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SongProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SongProgressCopyWith<SongProgress> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SongProgressCopyWith<$Res> {
  factory $SongProgressCopyWith(
    SongProgress value,
    $Res Function(SongProgress) then,
  ) = _$SongProgressCopyWithImpl<$Res, SongProgress>;
  @useResult
  $Res call({
    int index,
    String query,
    double percent,
    String speed,
    String eta,
    bool completed,
    bool error,
    bool skipped,
    String filePath,
  });
}

/// @nodoc
class _$SongProgressCopyWithImpl<$Res, $Val extends SongProgress>
    implements $SongProgressCopyWith<$Res> {
  _$SongProgressCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SongProgress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? index = null,
    Object? query = null,
    Object? percent = null,
    Object? speed = null,
    Object? eta = null,
    Object? completed = null,
    Object? error = null,
    Object? skipped = null,
    Object? filePath = null,
  }) {
    return _then(
      _value.copyWith(
            index: null == index
                ? _value.index
                : index // ignore: cast_nullable_to_non_nullable
                      as int,
            query: null == query
                ? _value.query
                : query // ignore: cast_nullable_to_non_nullable
                      as String,
            percent: null == percent
                ? _value.percent
                : percent // ignore: cast_nullable_to_non_nullable
                      as double,
            speed: null == speed
                ? _value.speed
                : speed // ignore: cast_nullable_to_non_nullable
                      as String,
            eta: null == eta
                ? _value.eta
                : eta // ignore: cast_nullable_to_non_nullable
                      as String,
            completed: null == completed
                ? _value.completed
                : completed // ignore: cast_nullable_to_non_nullable
                      as bool,
            error: null == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                      as bool,
            skipped: null == skipped
                ? _value.skipped
                : skipped // ignore: cast_nullable_to_non_nullable
                      as bool,
            filePath: null == filePath
                ? _value.filePath
                : filePath // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SongProgressImplCopyWith<$Res>
    implements $SongProgressCopyWith<$Res> {
  factory _$$SongProgressImplCopyWith(
    _$SongProgressImpl value,
    $Res Function(_$SongProgressImpl) then,
  ) = __$$SongProgressImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int index,
    String query,
    double percent,
    String speed,
    String eta,
    bool completed,
    bool error,
    bool skipped,
    String filePath,
  });
}

/// @nodoc
class __$$SongProgressImplCopyWithImpl<$Res>
    extends _$SongProgressCopyWithImpl<$Res, _$SongProgressImpl>
    implements _$$SongProgressImplCopyWith<$Res> {
  __$$SongProgressImplCopyWithImpl(
    _$SongProgressImpl _value,
    $Res Function(_$SongProgressImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SongProgress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? index = null,
    Object? query = null,
    Object? percent = null,
    Object? speed = null,
    Object? eta = null,
    Object? completed = null,
    Object? error = null,
    Object? skipped = null,
    Object? filePath = null,
  }) {
    return _then(
      _$SongProgressImpl(
        index: null == index
            ? _value.index
            : index // ignore: cast_nullable_to_non_nullable
                  as int,
        query: null == query
            ? _value.query
            : query // ignore: cast_nullable_to_non_nullable
                  as String,
        percent: null == percent
            ? _value.percent
            : percent // ignore: cast_nullable_to_non_nullable
                  as double,
        speed: null == speed
            ? _value.speed
            : speed // ignore: cast_nullable_to_non_nullable
                  as String,
        eta: null == eta
            ? _value.eta
            : eta // ignore: cast_nullable_to_non_nullable
                  as String,
        completed: null == completed
            ? _value.completed
            : completed // ignore: cast_nullable_to_non_nullable
                  as bool,
        error: null == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as bool,
        skipped: null == skipped
            ? _value.skipped
            : skipped // ignore: cast_nullable_to_non_nullable
                  as bool,
        filePath: null == filePath
            ? _value.filePath
            : filePath // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SongProgressImpl implements _SongProgress {
  const _$SongProgressImpl({
    required this.index,
    required this.query,
    this.percent = 0,
    this.speed = '',
    this.eta = '',
    this.completed = false,
    this.error = false,
    this.skipped = false,
    this.filePath = '',
  });

  factory _$SongProgressImpl.fromJson(Map<String, dynamic> json) =>
      _$$SongProgressImplFromJson(json);

  @override
  final int index;
  @override
  final String query;
  @override
  @JsonKey()
  final double percent;
  @override
  @JsonKey()
  final String speed;
  @override
  @JsonKey()
  final String eta;
  @override
  @JsonKey()
  final bool completed;
  @override
  @JsonKey()
  final bool error;
  @override
  @JsonKey()
  final bool skipped;
  @override
  @JsonKey()
  final String filePath;

  @override
  String toString() {
    return 'SongProgress(index: $index, query: $query, percent: $percent, speed: $speed, eta: $eta, completed: $completed, error: $error, skipped: $skipped, filePath: $filePath)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SongProgressImpl &&
            (identical(other.index, index) || other.index == index) &&
            (identical(other.query, query) || other.query == query) &&
            (identical(other.percent, percent) || other.percent == percent) &&
            (identical(other.speed, speed) || other.speed == speed) &&
            (identical(other.eta, eta) || other.eta == eta) &&
            (identical(other.completed, completed) ||
                other.completed == completed) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.skipped, skipped) || other.skipped == skipped) &&
            (identical(other.filePath, filePath) ||
                other.filePath == filePath));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    index,
    query,
    percent,
    speed,
    eta,
    completed,
    error,
    skipped,
    filePath,
  );

  /// Create a copy of SongProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SongProgressImplCopyWith<_$SongProgressImpl> get copyWith =>
      __$$SongProgressImplCopyWithImpl<_$SongProgressImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SongProgressImplToJson(this);
  }
}

abstract class _SongProgress implements SongProgress {
  const factory _SongProgress({
    required final int index,
    required final String query,
    final double percent,
    final String speed,
    final String eta,
    final bool completed,
    final bool error,
    final bool skipped,
    final String filePath,
  }) = _$SongProgressImpl;

  factory _SongProgress.fromJson(Map<String, dynamic> json) =
      _$SongProgressImpl.fromJson;

  @override
  int get index;
  @override
  String get query;
  @override
  double get percent;
  @override
  String get speed;
  @override
  String get eta;
  @override
  bool get completed;
  @override
  bool get error;
  @override
  bool get skipped;
  @override
  String get filePath;

  /// Create a copy of SongProgress
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SongProgressImplCopyWith<_$SongProgressImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
