# Testing Guide

This document explains how to run tests for the Diet & Calorie Tracking App.

## Prerequisites

- Flutter SDK installed
- All dependencies installed (`flutter pub get`)

## Running Tests

### Run All Tests
```bash
flutter test
```

### Run Specific Test File
```bash
flutter test test/models_test.dart
flutter test test/manual_food_entry_screen_test.dart
```

### Run with Coverage
```bash
flutter test --coverage
```

### View Coverage Report
```bash
# Install lcov (Linux/Mac)
sudo apt-get install lcov  # Ubuntu/Debian
brew install lcov           # macOS

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# Open in browser
open coverage/html/index.html  # macOS
xdg-open coverage/html/index.html  # Linux
```

## Test Structure

### Unit Tests (models_test.dart)
Tests the data models and business logic:
- Meal model serialization/deserialization
- NutritionGoals calculations
- DailyNutritionSummary progress tracking

### Widget Tests (manual_food_entry_screen_test.dart)
Tests UI components and user interactions:
- Form validation
- Input field constraints
- Dropdown menu options
- Button interactions

## Manual Testing Checklist

Since this app requires platform-specific features (camera, gallery), you should also perform manual testing:

### 1. Dashboard Screen
- [ ] Date navigation (previous/next day) works
- [ ] Circular progress indicator displays correctly
- [ ] Nutrition bars show accurate percentages
- [ ] Meals are categorized correctly (breakfast, lunch, dinner)
- [ ] Pull to refresh updates data
- [ ] Bottom navigation switches tabs

### 2. Add Food Screen (AI)
- [ ] Camera button opens device camera
- [ ] Gallery button opens photo library
- [ ] Image preview displays selected photo
- [ ] AI analysis mock completes (2 second delay)
- [ ] Analysis results show nutrition data
- [ ] Save button stores meal locally
- [ ] Delete button removes selected image
- [ ] Re-select button allows choosing new image

### 3. Manual Food Entry
- [ ] All input fields accept data
- [ ] Validation errors show for empty fields
- [ ] Numeric fields only accept numbers
- [ ] Meal type dropdown has all options
- [ ] Save button creates new food entry
- [ ] Success message appears after save
- [ ] Screen returns to previous page after save

### 4. Food List Screen
- [ ] Search functionality filters results
- [ ] Food cards display all nutrition info
- [ ] Menu button shows options (add/delete)
- [ ] Delete confirmation dialog appears
- [ ] Add to meal dialog shows meal types
- [ ] Empty state shows when no foods saved
- [ ] Detail modal shows complete info

### 5. Profile Screen
- [ ] User information displays correctly
- [ ] Nutrition goals can be viewed
- [ ] Logout button works
- [ ] Navigation back to dashboard

### 6. Data Persistence
- [ ] Saved foods persist after app restart
- [ ] User preferences are maintained
- [ ] Meal history is stored correctly

### 7. Platform Permissions
- [ ] Camera permission request appears
- [ ] Gallery permission request appears
- [ ] App handles permission denials gracefully
- [ ] Permission errors show user-friendly messages

## Common Issues and Solutions

### Test Failures

**Issue**: `MissingPluginException` in tests
**Solution**: Some features require running on actual device/emulator. Mock the platform channels or use integration tests.

**Issue**: Widget test timeout
**Solution**: Increase timeout or use `tester.pumpAndSettle(const Duration(seconds: 5))`

### Running on Devices

**Android**:
```bash
flutter run -d <device-id>
```

**iOS**:
```bash
flutter run -d <device-id>
cd ios && pod install && cd ..
flutter run
```

**Web** (limited camera support):
```bash
flutter run -d chrome --web-renderer html
```

## Performance Testing

### Check App Size
```bash
flutter build apk --analyze-size
flutter build ios --analyze-size
```

### Profile Performance
```bash
flutter run --profile
# Use DevTools to analyze performance
```

## Integration Testing

For end-to-end testing with real device features:

```bash
# Create integration test
mkdir -p integration_test
# Add test files

# Run integration test
flutter test integration_test/app_test.dart
```

## Continuous Integration

Example GitHub Actions workflow for CI:

```yaml
name: Flutter CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v2
        with:
          files: ./coverage/lcov.info
```

## Next Steps

1. Add more unit tests for services (auth_service, meal_service, food_service)
2. Create integration tests for full user flows
3. Add screenshot tests for visual regression testing
4. Implement golden tests for UI consistency
5. Add performance benchmarks
