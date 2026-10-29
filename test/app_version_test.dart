/// Checks that the app version constant matches the version declared in pubspec.yaml.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:youspotdl/core/constants.dart';

void main() {
  test('appVersion matches pubspec.yaml version without build number', () {
    final line = File('pubspec.yaml')
        .readAsLinesSync()
        .firstWhere((l) => l.startsWith('version:'));
    final pubspecVersion =
        line.substring('version:'.length).trim().split('+').first;
    expect(appVersion, pubspecVersion);
  });
}
