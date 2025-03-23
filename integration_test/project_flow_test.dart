import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gtd4_without_clean_achitecture/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('项目管理流程测试', () {
    // 调试函数：打印UI树
    void printUITree(WidgetTester tester) {
      print('\n----- 当前UI树 -----');
      print(tester.getSemantics(find.byType(MaterialApp)));
      print('----- UI树结束 -----\n');
    }

    // 调试函数：打印所有按钮和文本元素
    void printAllButtons(WidgetTester tester) {
      print('\n----- 当前UI中的按钮和文本 -----');
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
      print('----- 按钮和文本结束 -----\n');
    }

    // 通用导航到项目页面的函数
    Future<void> navigateToProjectsPage(WidgetTester tester) async {
      // 尝试多种图标和文本组合
      final folderIcon = find.byIcon(Icons.folder);
      final projectsText = find.text('项目');
      
      if (folderIcon.evaluate().isNotEmpty) {
        await tester.tap(folderIcon.first);
      } else if (projectsText.evaluate().isNotEmpty) {
        await tester.tap(projectsText.first);
      } else {
        // 如果没有明确的项目导航，尝试底部导航栏的第二项
        final bottomNavItems = find.descendant(
          of: find.byType(BottomNavigationBar),
          matching: find.byType(BottomNavigationBarItem)
        );
        
        if (bottomNavItems.evaluate().length >= 2) {
          // 尝试点击第二个导航项（通常是项目）
          await tester.tap(bottomNavItems.at(1));
        } else {
          printUITree(tester);
          printAllButtons(tester);
          throw Exception('无法找到导航到项目页面的按钮');
        }
      }
      
      await tester.pumpAndSettle();
    }

    // 创建项目的通用函数
    Future<String> createProject(WidgetTester tester, {String? customName}) async {
      // 查找添加按钮
      final addButton = find.byIcon(Icons.add);
      final fabButton = find.byType(FloatingActionButton);
      
      if (addButton.evaluate().isNotEmpty) {
        await tester.tap(addButton.first);
      } else if (fabButton.evaluate().isNotEmpty) {
        await tester.tap(fabButton.first);
      } else {
        printUITree(tester);
        printAllButtons(tester);
        throw Exception('无法找到添加项目按钮');
      }
      
      await tester.pumpAndSettle();
      
      // 填写项目表单
      final projectName = customName ?? '测试项目-${DateTime.now().millisecondsSinceEpoch}';
      
      // 尝试多种可能的输入字段标签
      final nameFields = [
        find.widgetWithText(TextField, '项目名称'),
        find.widgetWithText(TextField, '名称'),
        find.byType(TextField).first
      ];
      
      bool fieldFound = false;
      for (final field in nameFields) {
        if (field.evaluate().isNotEmpty) {
          await tester.tap(field);
          await tester.enterText(field, projectName);
          fieldFound = true;
          break;
        }
      }
      
      if (!fieldFound) {
        printUITree(tester);
        printAllButtons(tester);
        throw Exception('无法找到项目名称输入字段');
      }
      
      await tester.pumpAndSettle();
      
      // 尝试选择项目颜色 (可选操作)
      try {
        final colorButton = find.byType(CircleAvatar).first;
        await tester.tap(colorButton);
        await tester.pumpAndSettle();
        
        // 尝试点击颜色选择器中的第一个选项
        await tester.tap(find.byType(GestureDetector).first);
        await tester.pumpAndSettle();
      } catch (e) {
        print('颜色选择失败，继续测试: $e');
      }
      
      // 保存项目 - 尝试多种可能的保存按钮
      final saveOptions = [
        find.text('保存'),
        find.text('确认'),
        find.text('创建'),
        find.text('完成'),
        find.byIcon(Icons.check)
      ];
      
      bool saved = false;
      for (final option in saveOptions) {
        if (option.evaluate().isNotEmpty) {
          await tester.tap(option.first);
          saved = true;
          break;
        }
      }
      
      if (!saved) {
        printUITree(tester);
        printAllButtons(tester);
        throw Exception('无法找到保存项目的按钮');
      }
      
      await tester.pumpAndSettle();
      return projectName;
    }

    // 通用添加任务到项目的函数
    Future<String> addTaskToProject(WidgetTester tester, {String? customTitle}) async {
      // 查找添加按钮
      final addButton = find.byIcon(Icons.add);
      final fabButton = find.byType(FloatingActionButton);
      
      if (addButton.evaluate().isNotEmpty) {
        await tester.tap(addButton.first);
      } else if (fabButton.evaluate().isNotEmpty) {
        await tester.tap(fabButton.first);
      } else {
        printUITree(tester);
        printAllButtons(tester);
        throw Exception('无法找到添加任务按钮');
      }
      
      await tester.pumpAndSettle();
      
      // 填写任务信息
      final taskTitle = customTitle ?? '项目任务-${DateTime.now().millisecondsSinceEpoch}';
      
      // 尝试多种可能的输入字段标签
      final titleFields = [
        find.widgetWithText(TextField, '任务标题'),
        find.widgetWithText(TextField, '标题'),
        find.byType(TextField).first
      ];
      
      bool fieldFound = false;
      for (final field in titleFields) {
        if (field.evaluate().isNotEmpty) {
          await tester.tap(field);
          await tester.enterText(field, taskTitle);
          fieldFound = true;
          break;
        }
      }
      
      if (!fieldFound) {
        printUITree(tester);
        printAllButtons(tester);
        throw Exception('无法找到任务标题输入字段');
      }
      
      await tester.pumpAndSettle();
      
      // 保存任务 - 尝试多种可能的保存按钮
      final saveOptions = [
        find.text('保存'),
        find.text('确认'),
        find.text('添加'),
        find.text('完成'),
        find.byIcon(Icons.check),
        find.byIcon(Icons.done)
      ];
      
      bool saved = false;
      for (final option in saveOptions) {
        if (option.evaluate().isNotEmpty) {
          await tester.tap(option.first);
          saved = true;
          break;
        }
      }
      
      if (!saved) {
        printUITree(tester);
        printAllButtons(tester);
        throw Exception('无法找到保存任务的按钮');
      }
      
      await tester.pumpAndSettle();
      return taskTitle;
    }

    testWidgets('创建项目并添加任务', (WidgetTester tester) async {
      // 启动应用
      app.main();
      await tester.pumpAndSettle();
      
      // 导航到项目页面
      await navigateToProjectsPage(tester);
      
      // 验证我们在项目页面
      expect(
        find.textContaining('项目', findRichText: true).evaluate().isNotEmpty || 
        find.byIcon(Icons.folder).evaluate().isNotEmpty,
        isTrue,
        reason: '应该在项目页面'
      );
      
      // 创建项目
      final projectName = await createProject(tester);
      
      // 验证项目创建成功
      expect(find.text(projectName), findsOneWidget, reason: '项目应该已创建');
      
      // 点击项目进入详情页
      await tester.tap(find.text(projectName));
      await tester.pumpAndSettle();
      
      // 添加任务到项目
      final taskTitle = await addTaskToProject(tester);
      
      // 验证任务创建成功
      expect(find.text(taskTitle), findsOneWidget, reason: '任务应该已创建');
    });

    testWidgets('编辑和删除项目', (WidgetTester tester) async {
      // 启动应用
      app.main();
      await tester.pumpAndSettle();
      
      // 导航到项目页面
      await navigateToProjectsPage(tester);
      
      // 创建要编辑的项目
      final projectName = await createProject(tester, customName: '待编辑项目-${DateTime.now().millisecondsSinceEpoch}');
      
      // 尝试触发项目编辑菜单（多种可能的交互方式）
      bool editMenuTriggered = false;
      
      // 尝试长按
      try {
        await tester.longPress(find.text(projectName));
        await tester.pumpAndSettle();
        
        // 查找编辑选项
        final editOption = find.text('编辑');
        if (editOption.evaluate().isNotEmpty) {
          await tester.tap(editOption);
          editMenuTriggered = true;
        }
      } catch (e) {
        print('长按触发编辑菜单失败: $e');
      }
      
      // 如果长按失败，尝试寻找编辑图标
      if (!editMenuTriggered) {
        try {
          // 查找与项目相关的编辑图标
          final projectItem = find.ancestor(
            of: find.text(projectName),
            matching: find.byType(ListTile)
          );
          
          if (projectItem.evaluate().isNotEmpty) {
            final editIcon = find.descendant(
              of: projectItem,
              matching: find.byIcon(Icons.edit)
            );
            
            if (editIcon.evaluate().isNotEmpty) {
              await tester.tap(editIcon.first);
              editMenuTriggered = true;
            }
          }
        } catch (e) {
          print('通过图标触发编辑菜单失败: $e');
        }
      }
      
      // 如果还是失败，尝试上下文菜单
      if (!editMenuTriggered) {
        try {
          final moreIcon = find.byIcon(Icons.more_vert);
          if (moreIcon.evaluate().isNotEmpty) {
            await tester.tap(moreIcon.first);
            await tester.pumpAndSettle();
            
            final editOption = find.text('编辑');
            if (editOption.evaluate().isNotEmpty) {
              await tester.tap(editOption);
              editMenuTriggered = true;
            }
          }
        } catch (e) {
          print('通过上下文菜单触发编辑失败: $e');
          printUITree(tester);
          printAllButtons(tester);
          throw Exception('无法找到编辑项目的方法');
        }
      }
      
      await tester.pumpAndSettle();
      
      // 修改项目名称
      final updatedName = '$projectName-已更新';
      final nameField = find.byType(TextField).first;
      await tester.enterText(nameField, updatedName);
      
      // 保存更改 - 尝试多种可能的保存按钮
      final saveOptions = [
        find.text('保存'),
        find.text('确认'),
        find.text('更新'),
        find.text('完成'),
        find.byIcon(Icons.check)
      ];
      
      bool saved = false;
      for (final option in saveOptions) {
        if (option.evaluate().isNotEmpty) {
          await tester.tap(option.first);
          saved = true;
          break;
        }
      }
      
      if (!saved) {
        printUITree(tester);
        printAllButtons(tester);
        throw Exception('无法找到保存编辑的按钮');
      }
      
      await tester.pumpAndSettle();
      
      // 验证项目名称已更新
      expect(find.text(updatedName), findsOneWidget, reason: '项目名称应该已更新');
      
      // 删除项目 - 尝试多种可能的删除交互
      bool deleteTriggered = false;
      
      // 尝试长按
      try {
        await tester.longPress(find.text(updatedName));
        await tester.pumpAndSettle();
        
        // 查找删除选项
        final deleteOption = find.text('删除');
        if (deleteOption.evaluate().isNotEmpty) {
          await tester.tap(deleteOption);
          deleteTriggered = true;
        }
      } catch (e) {
        print('长按触发删除失败: $e');
      }
      
      // 如果长按失败，尝试寻找删除图标
      if (!deleteTriggered) {
        try {
          // 查找与项目相关的删除图标
          final projectItem = find.ancestor(
            of: find.text(updatedName),
            matching: find.byType(ListTile)
          );
          
          if (projectItem.evaluate().isNotEmpty) {
            final deleteIcon = find.descendant(
              of: projectItem,
              matching: find.byIcon(Icons.delete)
            );
            
            if (deleteIcon.evaluate().isNotEmpty) {
              await tester.tap(deleteIcon.first);
              deleteTriggered = true;
            }
          }
        } catch (e) {
          print('通过图标触发删除失败: $e');
        }
      }
      
      // 如果还是失败，尝试上下文菜单
      if (!deleteTriggered) {
        try {
          final moreIcon = find.byIcon(Icons.more_vert);
          if (moreIcon.evaluate().isNotEmpty) {
            await tester.tap(moreIcon.first);
            await tester.pumpAndSettle();
            
            final deleteOption = find.text('删除');
            if (deleteOption.evaluate().isNotEmpty) {
              await tester.tap(deleteOption);
              deleteTriggered = true;
            }
          }
        } catch (e) {
          print('通过上下文菜单触发删除失败: $e');
          printUITree(tester);
          printAllButtons(tester);
          throw Exception('无法找到删除项目的方法');
        }
      }
      
      await tester.pumpAndSettle();
      
      // 确认删除对话框
      try {
        final confirmOptions = [
          find.text('确认'),
          find.text('确定'),
          find.text('删除'),
          find.text('是')
        ];
        
        bool confirmed = false;
        for (final option in confirmOptions) {
          if (option.evaluate().isNotEmpty) {
            await tester.tap(option.first);
            confirmed = true;
            break;
          }
        }
        
        if (!confirmed) {
          printUITree(tester);
          printAllButtons(tester);
          throw Exception('无法找到确认删除的按钮');
        }
      } catch (e) {
        print('可能没有确认对话框: $e');
      }
      
      await tester.pumpAndSettle();
      
      // 验证项目已删除
      expect(find.text(updatedName), findsNothing, reason: '项目应该已被删除');
    });
    
    testWidgets('项目任务统计和进度', (WidgetTester tester) async {
      // 启动应用
      app.main();
      await tester.pumpAndSettle();
      
      // 导航到项目页面
      await navigateToProjectsPage(tester);
      
      // 创建新项目
      final projectName = await createProject(tester, customName: '进度测试项目-${DateTime.now().millisecondsSinceEpoch}');
      
      // 点击项目进入详情页
      await tester.tap(find.text(projectName));
      await tester.pumpAndSettle();
      
      // 添加第一个任务
      final taskTitle1 = await addTaskToProject(tester, customTitle: '任务1-${DateTime.now().millisecondsSinceEpoch}');
      
      // 添加第二个任务
      final taskTitle2 = await addTaskToProject(tester, customTitle: '任务2-${DateTime.now().millisecondsSinceEpoch}');
      
      // 验证两个任务都创建成功
      expect(find.text(taskTitle1), findsOneWidget, reason: '第一个任务应该已创建');
      expect(find.text(taskTitle2), findsOneWidget, reason: '第二个任务应该已创建');
      
      // 完成第一个任务 - 寻找与任务相关的复选框
      try {
        final task1Item = find.text(taskTitle1);
        
        final checkboxFinder = find.descendant(
          of: find.ancestor(of: task1Item, matching: find.byType(ListTile)),
          matching: find.byType(Checkbox)
        );
        
        if (checkboxFinder.evaluate().isNotEmpty) {
          await tester.tap(checkboxFinder.first);
        } else {
          // 备用：尝试找到行中的复选框
          final rowWithTask = find.ancestor(
            of: task1Item,
            matching: find.byType(Row)
          );
          
          if (rowWithTask.evaluate().isNotEmpty) {
            final checkboxInRow = find.descendant(
              of: rowWithTask,
              matching: find.byType(Checkbox)
            );
            
            if (checkboxInRow.evaluate().isNotEmpty) {
              await tester.tap(checkboxInRow.first);
            } else {
              // 如果还找不到，直接点击任务可能会触发完成状态
              await tester.tap(task1Item);
            }
          } else {
            // 最后尝试直接点击任务
            await tester.tap(task1Item);
          }
        }
        
        await tester.pumpAndSettle();
      } catch (e) {
        print('完成任务失败: $e');
      }
      
      // 返回项目列表页面 - 尝试多种返回方式
      try {
        final backButton = find.byIcon(Icons.arrow_back);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton.first);
        } else {
          // 尝试系统返回按钮
          await tester.pageBack();
        }
        
        await tester.pumpAndSettle();
      } catch (e) {
        print('返回失败: $e');
        printUITree(tester);
        printAllButtons(tester);
        throw Exception('无法返回项目列表页面');
      }
      
      // 验证有进度指示器
      expect(
        find.byType(LinearProgressIndicator).evaluate().isNotEmpty || 
        find.byType(CircularProgressIndicator).evaluate().isNotEmpty,
        isTrue,
        reason: '应该有进度指示器'
      );
    });
  });
} 