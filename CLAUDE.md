# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter GTD (Getting Things Done) application for task and project management. The app uses Provider for state management, SQLite for local data persistence, and follows a simplified architecture without clean architecture patterns.

## Build and Development Commands

### Building the App

```bash
# Build APK (Android) - ALWAYS use --no-tree-shake-icons option
flutter build apk --release --no-tree-shake-icons

# Build iOS
flutter build ios --release

# Build for specific device
flutter run -d [device_id]

# List available devices
flutter devices
```

### Testing Commands

```bash
# Run all tests (unit + integration + static analysis)
./scripts/run_all_tests.sh

# Run unit tests only
./scripts/run_unit_tests.sh
flutter test

# Run integration tests
./scripts/run_e2e_tests.sh [device_id]
flutter test integration_test/

# Run static analysis
./scripts/run_static_analysis.sh
flutter analyze

# Generate coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### Installation Scripts

```bash
# Auto-detect device and install
sh scripts/install_release_auto.sh

# Install on specific Android device
sh scripts/install_release.sh [device_id]

# Install on iOS device
sh scripts/install_release_ios.sh [device_id]
```

## Architecture and Code Structure

### State Management Pattern

The app uses Provider pattern with the following structure:

1. **Providers** (`lib/providers/`):
   - `TaskProvider`: Manages all task-related state and operations
   - `ProjectProvider`: Handles project management and reordering
   - `ThemeProvider`: Controls app theme and navigation bar visibility
   - All providers extend `ChangeNotifier` and use `notifyListeners()` for state updates

2. **Data Flow**:
   ```
   UI Screen → Provider → DatabaseHelper → SQLite Database
                ↓
         notifyListeners() → UI Updates
   ```

### Database Architecture

- **DatabaseHelper** (`lib/data/database_helper.dart`): Singleton pattern for database operations
- Tables: `tasks`, `projects`
- All database operations are async and should be wrapped in try-catch blocks
- Enum values are stored as integers and need boundary checking when deserializing

### Navigation Structure

The app uses a bottom navigation bar (mobile) or side rail (macOS) with 5 main screens:
1. **CalendarScreen**: Shows tasks organized by date
2. **InboxScreen**: Tasks without projects
3. **PriorityScreen**: Filtered view of prioritized tasks
4. **ProjectsScreen**: Project management with drag-to-reorder
5. **ReviewScreen**: Monthly project review system

### Key Design Patterns

1. **Singleton Pattern**: DatabaseHelper uses lazy singleton initialization
2. **Factory Pattern**: Models use `fromMap` factory constructors
3. **Observer Pattern**: Provider/ChangeNotifier for reactive UI updates
4. **Repository Pattern** (simplified): DatabaseHelper acts as data repository

## Critical Implementation Details

### Platform-Specific Handling

```dart
// Always check platform before using platform-specific features
if (!Platform.isMacOS) {
  // Mobile-specific code (Android/iOS)
}
```

### Date Handling

- Always check for null dates before calling `.compareTo()`
- Use proper month calculation for cross-year scenarios:
  ```dart
  int targetMonth = now.month - 1;
  if (targetMonth <= 0) {
    targetMonth = 12 + targetMonth;
    targetYear = targetYear - 1;
  }
  ```

### Concurrent Operations

The `ProjectProvider.reorderProjects` method uses a lock pattern to prevent race conditions:
```dart
bool _isReordering = false;
if (_isReordering) return;
_isReordering = true;
try {
  // reorder logic
} finally {
  _isReordering = false;
}
```

### Error Handling Pattern

All database operations should follow this pattern:
```dart
try {
  await _dbHelper.operation();
  await _loadData();
} catch (e) {
  print('Error: $e');
  rethrow; // or handle gracefully
}
```

## Testing Strategy

### Test Organization

- **Unit Tests** (`test/`): Models, providers, utils
- **Widget Tests** (`test/widgets/`): UI component testing
- **Integration Tests** (`integration_test/`): Full user flows
  - `app_test.dart`: Basic app functionality
  - `task_flow_test.dart`: Task management flows
  - `project_flow_test.dart`: Project management flows

### Mock Data

Use `lib/data/mock_data.dart` for development and testing. The MockDataGenerator provides:
- Sample tasks with various states
- Project hierarchies
- Date-based task distribution

## Common Issues and Solutions

### APK Build Issues
- Always use `--no-tree-shake-icons` flag when building APK to prevent icon rendering issues

### State Management Issues
- Ensure `notifyListeners()` is called after state changes
- Use `Consumer` or `Provider.of` with proper `listen` parameter

### Database Migration
- Version management in `DatabaseHelper._onCreate` and `_onUpgrade`
- Always increment version number when changing schema

### Memory Management
- Dispose TextEditingControllers in `dispose()` method
- Cancel StreamSubscriptions and Timers

## Development Workflow

1. Create feature branch from `main`
2. Implement feature with appropriate error handling
3. Run `flutter analyze` to check for issues
4. Run tests: `./scripts/run_all_tests.sh`
5. Build and test on device: `sh scripts/install_release_auto.sh`
6. Commit with descriptive message
7. Create pull request

## Performance Considerations

- Use `const` constructors where possible
- Implement `ListView.builder` for long lists
- Avoid unnecessary rebuilds by properly scoping Consumer widgets
- Cache expensive computations in providers

## Security Notes

- Never store sensitive data in SharedPreferences
- SQLite database is stored in app's private directory
- Validate and sanitize all user inputs before database operations