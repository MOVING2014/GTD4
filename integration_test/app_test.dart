import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gtd4_without_clean_achitecture/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('App starts and shows bottom navigation', (WidgetTester tester) async {
      // 运行应用
      app.main();
      // 等待应用加载
      await tester.pumpAndSettle();

      // 验证底部导航栏显示了5个选项
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.byIcon(Icons.priority_high), findsOneWidget);
      expect(find.byIcon(Icons.folder), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
    });

    testWidgets('Can navigate to inbox screen', (WidgetTester tester) async {
      // 运行应用
      app.main();
      // 等待应用加载
      await tester.pumpAndSettle();

      // 点击收件箱图标
      await tester.tap(find.byIcon(Icons.inbox));
      await tester.pumpAndSettle();

      // 验证已经导航到收件箱页面
      expect(find.text('收件箱'), findsOneWidget);
    });
  });
} 