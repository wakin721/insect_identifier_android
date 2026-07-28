import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insect_identifier/controllers/app_controller.dart';
import 'package:insect_identifier/widgets/model_status_banner.dart';

void main() {
  testWidgets('model preparation shows standby with trailing progress',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ModelStatusBanner(
            state: ModelRuntimeState.loading,
            recognizing: false,
          ),
        ),
      ),
    );

    expect(find.text('本地模型待命'), findsOneWidget);
    expect(find.text('正在加载并预热本地模型，不上传照片'), findsOneWidget);
    expect(find.byIcon(Icons.memory_outlined), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('ready model no longer shows progress', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ModelStatusBanner(
            state: ModelRuntimeState.ready,
            recognizing: false,
          ),
        ),
      ),
    );

    expect(find.text('本地模型已就绪'), findsOneWidget);
    expect(find.text('LiteRT 推理引擎已预热，可离线运行'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
