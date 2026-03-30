# Notes App — iOS (SwiftUI)

Cross-platform notes application — iOS client built with SwiftUI.

## E2E v27: Верификация APIService и NotesViewModel

### Предусловия

1. Backend запущен на порту 4000:

```bash
cd ../e2e-test-backend
JWT_ENABLED=true npm run dev
```

2. iOS Simulator запущен:

```bash
xcrun simctl boot "iPhone 14"
```

### Проверка статуса backend

```bash
# Health check
curl -s http://localhost:4000/health
# Ожидаемый ответ: {"status":"ok"}

# Получить dev-token
curl -s -X POST http://localhost:4000/api/auth/dev-token
# Ожидаемый ответ: {"token":"<jwt>"}

# Проверить 401 без токена
curl -s -w "\nHTTP_CODE:%{http_code}\n" http://localhost:4000/api/notes
# Ожидаемый ответ: 401 {"error":"Unauthorized"}
```

### Установка токена в симулятор

```bash
# Получить и записать токен
TOKEN=$(curl -s -X POST http://localhost:4000/api/auth/dev-token | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")
xcrun simctl spawn booted defaults write com.ultrawork.notes token "$TOKEN"

# Проверить токен
xcrun simctl spawn booted defaults read com.ultrawork.notes token

# Удалить токен
xcrun simctl spawn booted defaults delete com.ultrawork.notes token
```

### Сценарии и отчёт

- Сценарии (5 шт.): [e2e/scenarios/ios-notes-v27.md](e2e/scenarios/ios-notes-v27.md)
- Отчёт (PASS 5/5): [e2e/reports/ios-v27.md](e2e/reports/ios-v27.md)

## E2E v28: Верификация APIService и NotesViewModel

### Предусловия

1. Backend запущен на порту 4000:

```bash
cd ../e2e-test-backend
JWT_ENABLED=true npm run dev
```

2. iOS Simulator запущен:

```bash
xcrun simctl boot "iPhone 14"
```

### Проверка статуса backend

```bash
# Health check
curl -s http://localhost:4000/health
# Ожидаемый ответ: {"status":"ok"}

# Получить dev-token
curl -s -X POST http://localhost:4000/api/auth/dev-token
# Ожидаемый ответ: {"token":"<jwt>"}

# Проверить 401 без токена
curl -s -w "\nHTTP_CODE:%{http_code}\n" http://localhost:4000/api/notes
# Ожидаемый ответ: 401 {"error":"Unauthorized"}
```

### Установка токена в симулятор

```bash
# Получить и записать токен
TOKEN=$(curl -s -X POST http://localhost:4000/api/auth/dev-token | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")
xcrun simctl spawn booted defaults write com.ultrawork.notes token "$TOKEN"

# Проверить токен
xcrun simctl spawn booted defaults read com.ultrawork.notes token

# Удалить токен
xcrun simctl spawn booted defaults delete com.ultrawork.notes token
```

### Запуск тестов

```bash
xcodebuild -project NotesApp/NotesApp.xcodeproj \
  -scheme NotesApp \
  -destination 'platform=iOS Simulator,name=iPhone 14' \
  test
```

### Сценарии и отчёт

- Сценарии (5 шт.): [e2e/scenarios/ios-notes-v28.md](e2e/scenarios/ios-notes-v28.md)
- Отчёт (PASS 5/5): [e2e/reports/ios-v28.md](e2e/reports/ios-v28.md)
