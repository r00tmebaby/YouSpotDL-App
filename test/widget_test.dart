/// Hermetic widget test for the AppLogo widget. Runs no processes and no network.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youspotdl/widgets/app_logo.dart';

void main() {
  testWidgets('AppLogo renders at the requested size', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: AppLogo(size: 64)),
        ),
      ),
    );

    expect(find.byType(AppLogo), findsOneWidget);
    expect(tester.getSize(find.byType(AppLogo)), const Size(64, 64));
  });
}
