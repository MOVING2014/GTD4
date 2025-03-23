# GTD Todo 应用

GTD（Getting Things Done）风格的Todo应用，帮助用户高效管理任务和项目。

## 功能特点

- 任务管理：创建、编辑、删除和完成任务
- 项目分组：将任务组织到项目中
- 日历视图：按日期查看计划任务
- 优先级标记：设置任务优先级
- 截止日期提醒：管理任务的截止日期
- 支持深色模式：提供明暗两种主题

## 安装

```bash
# 克隆仓库
git clone https://github.com/yourusername/gtd-todo-app.git

# 进入项目目录
cd gtd-todo-app

# 安装依赖
flutter pub get

# 运行应用
flutter run
```

## 构建与发布

我们提供了一系列脚本来简化应用的构建和发布过程。

### 构建发布包

要构建各平台的发布包，使用以下命令：

```bash
# 确保脚本有执行权限
chmod +x scripts/*.sh

# 构建Android应用（生成APK和AAB）
./scripts/build_release.sh android

# 构建iOS应用
./scripts/build_release.sh ios

# 构建Web应用
./scripts/build_release.sh web

# 构建所有平台
./scripts/build_release.sh all
```

构建完成后，发布包将存放在 `build/releases/[日期时间]/` 目录下。

### 安装到设备

#### 自动安装（推荐）

项目提供了自动安装脚本，可以一键构建和安装应用到连接的设备上：

```bash
# 自动选择第一个可用设备并安装
sh scripts/install_release_auto.sh

# 指定设备ID安装
sh scripts/install_release_auto.sh [设备ID]

# 安装但不自动启动应用
sh scripts/install_release_auto.sh [设备ID] false
```

脚本会自动检测设备类型（Android或iOS），执行相应的构建过程，并将应用安装到指定设备。对于Android设备，脚本会自动启动应用程序。

#### 仅构建应用

如果只需要构建应用而不安装，可以使用以下命令：

```bash
# 构建Android APK
sh scripts/build_release.sh android

# 构建iOS应用
sh scripts/build_release.sh ios

# 构建Web应用
sh scripts/build_release.sh web
```

#### 平台特定安装

也可以针对特定平台使用专门的安装脚本：

```bash
# 仅Android设备
sh scripts/install_release.sh [设备ID]

# 仅iOS设备
sh scripts/install_release_ios.sh [设备ID]
```

#### 注意事项

- **Android设备**：确保已开启USB调试模式并授权连接的计算机
- **iOS设备**：首次安装可能需要在设备上信任开发者证书（设置 → 通用 → 设备管理）
- 使用`flutter devices`命令可查看所有可连接的设备及其ID

## 测试与质量保证

本项目采用了全面的测试策略，确保应用的质量和可靠性。

### 测试类型

1. **单元测试**：测试模型和业务逻辑
2. **小部件测试**：测试UI组件
3. **集成测试**：测试完整的用户流程
4. **端到端测试**：测试真实用户场景的完整流程

### 自动化测试框架

我们的测试自动化框架包含以下组件：

- **测试脚本**：用于运行不同类型测试的Shell脚本
- **测试报告**：自动生成HTML和文本格式的测试报告
- **CI/CD集成**：与GitHub Actions集成，实现自动化测试流水线
- **设备适配**：自动检测并使用可用的测试设备（Android或iOS）

### 运行测试

#### 运行全部测试

```bash
# 确保脚本有执行权限
chmod +x scripts/*.sh

# 运行所有测试（单元测试、静态分析和集成测试）
./scripts/run_all_tests.sh
```

#### 运行特定类型的测试

```bash
# 只运行单元测试
./scripts/run_unit_tests.sh

# 只运行静态代码分析
./scripts/run_static_analysis.sh

# 端到端测试（自动检测设备）
./scripts/run_e2e_tests.sh

# 在特定Android设备上运行端到端测试（提供设备ID）
./scripts/run_e2e_tests.sh <device_id>

# 在iOS设备上运行集成测试
./scripts/run_ios_tests.sh
```

### 测试报告

测试执行后，系统会自动生成报告：

- **单元测试**：`test_results/unit_tests/<日期时间>/`
- **端到端测试**：`test_results/<日期时间>/`
  - HTML摘要报告：`summary.html`
  - 各测试详细日志：`*_log.txt`
  - 测试失败错误摘要

### CI/CD 集成

本项目与GitHub Actions集成，实现自动化的CI/CD流程：

- **触发条件**：每次代码推送和Pull Request
- **执行流程**：
  1. 安装Flutter环境
  2. 运行静态代码分析
  3. 执行所有单元测试和小部件测试
  4. 在模拟设备上运行集成测试
  5. 生成并上传测试报告
  6. 自动通知测试结果

配置文件位于：`.github/workflows/flutter_ci.yml`

### 测试文档

详细的测试文档可在以下位置找到：

- [测试策略与实现指南](test/README.md)：包含测试架构、实现指南和最佳实践
- [测试结果](test_results/)：测试执行结果和覆盖率报告

## 端到端测试说明

我们的端到端测试验证用户的实际使用场景，包括：

### 任务流程测试
- 创建、完成和删除任务的完整流程
- 设置任务优先级和截止日期
- 搜索和过滤任务

### 项目管理测试
- 创建和编辑项目
- 向项目添加任务
- 监控项目进度
- 不同视图中查看项目任务

### 测试的健壮性设计

我们的端到端测试具有以下特性以增强可靠性：

- **自适应UI元素定位**：使用多种策略查找UI元素，适应界面变化
- **错误恢复机制**：在测试过程中包含错误处理和恢复策略
- **调试支持**：内置UI树和元素打印功能，便于排查问题
- **超时处理**：防止测试无限等待，自动终止长时间运行的测试
- **详细日志**：记录测试过程中的关键步骤和状态

## 项目结构

```
lib/
├── database/            # 数据库处理
├── models/              # 数据模型
├── providers/           # 状态管理
├── screens/             # 应用屏幕
├── utils/               # 工具函数
└── widgets/             # 可复用组件

test/                    # 测试代码
├── models/              # 模型测试
├── providers/           # Provider测试
├── widgets/             # 小部件测试
└── mocks/               # 测试模拟对象

integration_test/        # 集成测试
├── task_flow_test.dart  # 任务流程测试
├── project_flow_test.dart # 项目管理测试
└── app_test.dart        # 应用流程测试

scripts/                 # 自动化脚本
├── run_all_tests.sh     # 运行所有测试
├── run_unit_tests.sh    # 运行单元测试
├── run_static_analysis.sh # 运行代码分析
├── run_e2e_tests.sh     # 运行端到端测试
├── build_release.sh     # 构建发布包
├── install_release.sh   # 安装到Android设备
├── install_release_ios.sh # 安装到iOS设备
└── install_release_auto.sh # 自动检测设备并安装

.github/workflows/       # CI/CD配置
└── flutter_ci.yml       # GitHub Actions工作流配置
```

## 贡献指南

1. Fork项目
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建Pull Request

**注意**：提交PR前，请确保所有测试通过：

```bash
./scripts/run_all_tests.sh
```

## 许可证

本项目采用MIT许可证 - 详情请参阅 [LICENSE](LICENSE) 文件
