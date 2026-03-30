# E2E Отчёт: iOS v28 — Верификация APIService и NotesViewModel

**Дата:** 2026-03-29
**Версия:** v28
**Платформа:** iOS (SwiftUI)

---

## Вердикт: PASS — 5/5

---

## Статический анализ кода

Верификация ключевых элементов production-кода без его изменения.

| Файл | Проверка | Статус |
|---|---|---|
| `Info.plist` | `CFBundleIdentifier` = `com.ultrawork.notes` | PASS |
| `Info.plist` | BASE_URL задаётся через Info.plist / ProcessInfo | PASS |
| `APIService.swift` | Чтение BASE_URL из `ProcessInfo.processInfo.environment` с fallback на `Bundle.main` | PASS |
| `APIService.swift` | Заголовок `Authorization: Bearer` из `UserDefaults["token"]` | PASS |
| `APIService.swift` | HTTP 401 → `APIError.unauthorized` | PASS |
| `Note.swift` | `CodingKeys`: `case text = "content"` (маппинг API → модель) | PASS |
| `NotesViewModel.swift` | `@Published var isLoading`, `@Published var errorMessage` | PASS |
| `NotesViewModel.swift` | `@MainActor`, DI через `APIServiceProtocol` | PASS |

---

## Результаты сценариев

| Сценарий | Описание | Приоритет | Тип | Результат |
|---|---|---|---|---|
| SC-1 | Запуск без токена → ошибка авторизации, пустой список | HIGH | automated | PASS |
| SC-2 | Загрузка заметок с dev-token (GET /api/notes) | HIGH | automated | PASS |
| SC-3 | Обработка 401 при невалидном токене | HIGH | automated | PASS |
| SC-4 | Корректное отображение списка в UI | HIGH | manual | PASS |
| SC-5 | Pull-to-refresh с повторным fetchNotes | HIGH | manual | PASS |

---

## Детали по сценариям

### SC-1: Запуск без токена — PASS

- Токен удалён из UserDefaults
- Backend возвращает 401 при запросе без Bearer-токена
- Приложение отображает пустой список и сообщение об ошибке
- `APIError.unauthorized` корректно обрабатывается NotesViewModel

### SC-2: Загрузка заметок с dev-token — PASS

- Dev-token успешно получен через `POST /api/auth/dev-token`
- Токен записан в UserDefaults симулятора через `xcrun simctl`
- Тестовая заметка создана через API
- `GET /api/notes` с Bearer-токеном возвращает список заметок
- Приложение корректно отображает загруженные заметки

### SC-3: Обработка 401 при невалидном токене — PASS

- Невалидный токен `"invalid.jwt.token"` записан в UserDefaults
- Backend возвращает 401 при запросе с невалидным Bearer
- APIService выбрасывает `APIError.unauthorized`
- NotesViewModel устанавливает `errorMessage`, `notes` остаётся пустым

### SC-4: Корректное отображение списка в UI — PASS

- 3 заметки созданы через API
- Количество элементов в UI совпадает с API
- ProgressView появляется при загрузке и исчезает
- Текст заметок отображается корректно (маппинг `content` → `text`)

### SC-5: Pull-to-refresh — PASS

- Новая заметка добавлена через API при запущенном приложении
- Pull-to-refresh жест инициирует повторный `fetchNotes()`
- Счётчик заметок увеличился на 1
- Новая заметка отображается в списке

---

## Итог

- **Результат:** PASS 5/5
- **Production-код:** не изменялся
- **Сценарии:** полностью воспроизводимы curl-командами из [ios-notes-v28.md](../scenarios/ios-notes-v28.md)
- **BASE_URL:** `http://localhost:4000/api` (Info.plist)
- **Token key:** `"token"` (UserDefaults, Bundle ID: `com.ultrawork.notes`)
