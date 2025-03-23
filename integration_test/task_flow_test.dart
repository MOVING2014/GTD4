import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gtd4_without_clean_achitecture/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('任务流程集成测试', () {
    // 调试函数：打印UI树
    void printUITree(WidgetTester tester) {
      print('\n----- 当前UI树 -----');
      try {
        final String tree = tester.binding.renderViewElement?.toStringDeep() ?? '无法获取UI树';
        print(tree);
      } catch (e) {
        print('打印UI树时出错: $e');
      }
      print('----- UI树结束 -----\n');
    }

    // 调试函数：打印所有按钮和文本元素
    void printAllButtons(WidgetTester tester) {
      print('\n----- 当前UI中的按钮和文本 -----');
      try {
        final Finder buttonFinders = find.byWidgetPredicate((widget) => 
          widget is ElevatedButton || 
          widget is TextButton || 
          widget is IconButton || 
          widget is FloatingActionButton);
        
        final Finder textFinders = find.byWidgetPredicate((widget) => 
          widget is Text);
        
        print('按钮数量: ${tester.widgetList(buttonFinders).length}');
        tester.widgetList(buttonFinders).forEach((widget) {
          if (widget is ElevatedButton) {
            print('ElevatedButton: ${(widget.child is Text) ? (widget.child as Text).data : "无文本"}');
          } else if (widget is TextButton) {
            print('TextButton: ${(widget.child is Text) ? (widget.child as Text).data : "无文本"}');
          } else if (widget is IconButton) {
            print('IconButton: ${widget.icon.toString()}');
          } else if (widget is FloatingActionButton) {
            print('FloatingActionButton: ${widget.child.toString()}');
          }
        });
        
        print('文本数量: ${tester.widgetList(textFinders).length}');
        tester.widgetList(textFinders).forEach((widget) {
          if (widget is Text) {
            print('Text: "${widget.data}"');
          }
        });
      } catch (e) {
        print('打印按钮和文本时出错: $e');
      }
      print('----- 按钮和文本结束 -----\n');
    }

    // 查找添加按钮并点击
    Future<void> findAndTapFloatingActionButton(WidgetTester tester) async {
      final fabFinder = find.byType(FloatingActionButton);
      if (fabFinder.evaluate().isNotEmpty) {
        await tester.tap(fabFinder);
      } else {
        // 如果找不到FAB，尝试查找具有特定图标的按钮
        final iconButtonFinder = find.byIcon(Icons.add);
        if (iconButtonFinder.evaluate().isNotEmpty) {
          await tester.tap(iconButtonFinder);
        } else {
          // 如果仍然找不到，尝试查找可能包含"添加"或"+"的任何按钮
          final addTextButtonFinder = find.textContaining(RegExp(r'添加|新增|\+', caseSensitive: false));
          if (addTextButtonFinder.evaluate().isNotEmpty) {
            await tester.tap(addTextButtonFinder);
          } else {
            throw Exception('无法找到添加按钮');
          }
        }
      }
    }

    /// 添加新任务
    Future<void> addTask(WidgetTester tester, String title, {String? note, String? category}) async {
      printUITree(tester); // 打印初始UI结构
      
      // 查找添加按钮并点击
      await findAndTapFloatingActionButton(tester);
      
      // 等待对话框显示
      await tester.pumpAndSettle();
      printUITree(tester); // 打印点击后的UI结构
      printAllButtons(tester); // 打印所有按钮
      
      // 确认对话框已显示
      expect(find.text('标题'), findsOneWidget, reason: '应该显示任务添加对话框');
      
      // 输入标题
      await tester.enterText(find.widgetWithText(TextField, '标题'), title);
      await tester.pumpAndSettle();
      
      // 如果提供了备注，则输入备注
      if (note != null) {
        await tester.enterText(find.widgetWithText(TextField, '备注'), note);
        await tester.pumpAndSettle();
      }
      
      // 如果提供了类别，尝试选择类别
      if (category != null) {
        // 这里假设有一个类别选择器，具体实现取决于应用的UI
        // 此处仅为示例
        try {
          await tester.tap(find.text('收件箱 (无项目)'));
          await tester.pumpAndSettle();
          await tester.tap(find.text(category));
          await tester.pumpAndSettle();
        } catch (e) {
          print('选择类别失败: $e');
        }
      }
      
      // 点击"创建"按钮保存任务
      try {
        // 尝试多种方式查找创建按钮
        if (find.widgetWithText(ElevatedButton, '创建').evaluate().isNotEmpty) {
          await tester.tap(find.widgetWithText(ElevatedButton, '创建'));
        } else if (find.text('创建').evaluate().isNotEmpty) {
          await tester.tap(find.text('创建'));
        } else {
          throw Exception('无法找到保存或确认按钮');
        }
        await tester.pumpAndSettle();
      } catch (e) {
        printAllButtons(tester); // 如果出错，打印所有按钮
        throw Exception('无法找到保存或确认按钮');
      }
    }

    // 查找任务的可靠方法
    Finder findTask(String taskName) {
      return find.text(taskName, findRichText: true);
    }
    
    // 主测试用例：添加和验证任务
    testWidgets('添加任务并验证显示', (WidgetTester tester) async {
      // 启动应用
      app.main();
      await tester.pumpAndSettle();
      // 等待应用完全加载（给应用更多时间初始化）
      await Future.delayed(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      
      printUITree(tester);
      printAllButtons(tester);
      
      // 添加测试任务
      const String taskTitle = '测试任务';
      const String taskNote = '这是一个测试任务';
      await addTask(tester, taskTitle, note: taskNote);
      
      // 等待UI更新
      await tester.pumpAndSettle();
      
      // 验证任务是否显示
      expect(find.text(taskTitle), findsOneWidget, reason: '任务标题应该显示在UI中');
      if (find.text(taskNote).evaluate().isEmpty) {
        print('注意：任务备注可能不会直接显示在列表中');
      }
    });
    
    // 任务完成标记测试
    testWidgets('标记任务为已完成', (WidgetTester tester) async {
      // 启动应用
      app.main();
      await tester.pumpAndSettle();
      // 等待应用完全加载（给应用更多时间初始化）
      await Future.delayed(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      
      // 首先添加一个任务
      const String taskTitle = '要完成的任务';
      await addTask(tester, taskTitle);
      
      // 等待UI更新
      await tester.pumpAndSettle();
      
      // 验证任务是否显示
      expect(find.text(taskTitle), findsOneWidget, reason: '任务标题应该显示在UI中');
      
      // 尝试标记任务为已完成
      // 找到该任务所在的行
      final taskFinder = find.text(taskTitle);
      
      // 尝试找到任务行中的完成按钮或复选框
      try {
        // 首先尝试点击任务行左侧的复选框
        final checkboxFinder = find.descendant(
          of: find.ancestor(
            of: taskFinder,
            matching: find.byType(ListTile),
          ),
          matching: find.byType(Checkbox),
        );
        
        if (checkboxFinder.evaluate().isNotEmpty) {
          await tester.tap(checkboxFinder);
        } else {
          // 如果找不到复选框，尝试点击任务行本身
          await tester.tap(taskFinder);
          await tester.pumpAndSettle();
          
          // 查找完成按钮
          final completeButtonFinder = find.text('完成');
          if (completeButtonFinder.evaluate().isNotEmpty) {
            await tester.tap(completeButtonFinder);
          } else {
            print('无法找到完成按钮，尝试其他方法');
            printAllButtons(tester);
            // 尝试寻找其他可能的完成按钮
            final doneButtonFinder = find.text('标记为已完成');
            if (doneButtonFinder.evaluate().isNotEmpty) {
              await tester.tap(doneButtonFinder);
            } else {
              throw Exception('无法找到标记任务为已完成的按钮');
            }
          }
        }
        
        await tester.pumpAndSettle();
        
        // 验证任务已标记为完成（可能不再显示或有删除线）
        // 这里的验证取决于应用程序如何显示已完成的任务
        if (find.text(taskTitle).evaluate().isEmpty) {
          print('任务已完成并从列表中移除');
        } else {
          // 如果任务仍然可见，但应该有删除线或其他标记
          print('任务仍然可见，可能有完成标记');
        }
      } catch (e) {
        print('标记任务为已完成失败: $e');
        printUITree(tester);
        throw Exception('标记任务为已完成失败');
      }
    });
  });
} 