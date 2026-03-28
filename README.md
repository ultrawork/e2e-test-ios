# Notes App — iOS (SwiftUI)

Cross-platform notes application — iOS client built with SwiftUI.

## E2E v25

### Сборка проекта

```bash
xcodebuild -project NotesApp/NotesApp.xcodeproj \
  -scheme NotesApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

### Настройка окружения

Перед запуском приложения с backend-интеграцией задайте значения в `NotesApp/NotesApp/Info.plist`:

| Ключ | Описание | Пример |
|------|----------|--------|
| `BASE_URL` | Базовый URL backend API | `http://localhost:3000` |
| `DEV_TOKEN` | Токен авторизации (Bearer) | `your_dev_token_here` |

### Запуск E2E-тестов

```bash
xcodebuild -project NotesApp/NotesApp.xcodeproj \
  -scheme NotesApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  test
```

### Артефакты

- [E2E-сценарии (5 шт.)](e2e/scenarios/ios-notes-v25.md)
- [E2E-отчёт (PASS 5/5)](e2e/reports/ios-v25.md)
