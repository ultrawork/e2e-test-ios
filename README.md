# Notes App — iOS (SwiftUI)

Cross-platform notes application — iOS client built with SwiftUI.

## Тестирование

### Запуск unit-тестов (xcodebuild)

```bash
xcodebuild -project NotesApp/NotesApp.xcodeproj \
  -scheme NotesAppTests \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  test 2>&1 | grep -E "Test Case|TEST SUCCEEDED|TEST FAILED"
```

### Установка токена в UserDefaults перед тестами

```bash
xcrun simctl spawn booted defaults write com.ultrawork.notes token "YOUR_JWT_TOKEN"
```

### Получение dev-token через backend

```bash
TOKEN=$(curl -s -X POST http://localhost:4000/api/auth/dev-token \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")
xcrun simctl spawn booted defaults write com.ultrawork.notes token "$TOKEN"
```

### Очистка токена после тестов

```bash
xcrun simctl spawn booted defaults delete com.ultrawork.notes token
```

### Настройка BASE_URL в Info.plist

`Info.plist` содержит ключ `BASE_URL = "http://localhost:4000/api"`.
Backend должен быть запущен локально перед запуском UI-тестов.
