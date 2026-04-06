import 'package:freezed_annotation/freezed_annotation.dart';

part 'progress_event.freezed.dart';
part 'progress_event.g.dart';

@freezed
class ProgressEvent with _$ProgressEvent {
  const factory ProgressEvent({
    required String type,
    required Map<String, dynamic> data,
    @Default(0) double timestamp,
  }) = _ProgressEvent;

  factory ProgressEvent.fromJson(Map<String, dynamic> json) =>
      _$ProgressEventFromJson(json);
}
