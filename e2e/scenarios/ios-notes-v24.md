# E2E Сценарии: iOS Notes v24 — Верификация APIService и ViewModel

**Версия:** v24
**Дата:** 2026-03-28
**Цель:** Проверить корректность APIService (BASE_URL, Bearer), декодирования Note через CodingKeys и поведения NotesViewModel (isLoading, errorMessage).

---

## SC-1: Запуск без токена — ошибка авторизации

**Тип:** API
**Приоритет:** HIGH

### Предусловия
- Приложение установлено на симуляторе iOS 17+
- Токен в UserDefaults отсутствует (`com.ultrawork.notes token` не задан)
- Backend запущен на `http://localhost:4000`

### Шаги

```bash
# 1. Убедиться что токен не установлен / очистить
xcrun simctl spawn booted defaults delete com.ultrawork.notes token 2>/dev/null || true

# 2. Запустить приложение
xcrun simctl launch booted com.ultrawork.notes

# 3. Наблюдать поведение UI при попытке загрузки заметок
```

### Ожидаемый результат
- APIService отправляет запрос с пустым или отсутствующим Bearer-токеном
- Backend возвращает `401 Unauthorized`
- `NotesViewModel.errorMessage` устанавливается в `"Unauthorized"` (или аналогичное сообщение)
- `NotesViewModel.isLoading` сбрасывается в `false`
- `NotesViewModel.notes` остаётся пустым массивом `[]`
- В UI отображается сообщение об ошибке авторизации

---

## SC-2: Загрузка списка заметок с валидным токеном

**Тип:** API
**Приоритет:** HIGH

### Предусловия
- Backend запущен на `http://localhost:4000`
- Токен получен через dev-token endpoint
- В базе данных backend существуют тестовые заметки

### Шаги

```bash
# 1. Получить dev-token от backend
TOKEN=$(curl -s -X POST http://localhost:4000/api/auth/dev-token \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")

# 2. Установить токен в UserDefaults симулятора
xcrun simctl spawn booted defaults write com.ultrawork.notes token "$TOKEN"

# 3. Создать тестовую заметку через API
curl -s -X POST http://localhost:4000/api/notes \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"content": "Тестовая заметка v24"}'

# 4. Запустить / перезапустить приложение
xcrun simctl terminate booted com.ultrawork.notes 2>/dev/null || true
xcrun simctl launch booted com.ultrawork.notes

# 5. Подождать загрузки (около 1 сек)
sleep 1
```

### Ожидаемый результат
- APIService формирует запрос `GET http://localhost:4000/api/notes` с заголовком `Authorization: Bearer <token>`
- Backend возвращает `200 OK` с JSON-массивом, где каждый элемент содержит поле `content`
- `Note` декодируется через CodingKeys: поле `content` из JSON маппится в локальное поле `text`
- `NotesViewModel.notes` содержит не пустой массив
- `NotesViewModel.isLoading` = `false`, `errorMessage` = `nil`
- В UI отображается список заметок с корректным текстом

---

## SC-3: Обработка ответа 401 Unauthorized

**Тип:** API
**Приоритет:** HIGH

### Предусловия
- Backend запущен на `http://localhost:4000`
- В UserDefaults установлен невалидный / просроченный токен

### Шаги

```bash
# 1. Установить невалидный токен
xcrun simctl spawn booted defaults write com.ultrawork.notes token "invalid.jwt.token"

# 2. Запустить / перезапустить приложение
xcrun simctl terminate booted com.ultrawork.notes 2>/dev/null || true
xcrun simctl launch booted com.ultrawork.notes

# 3. Дождаться ответа от сервера
sleep 1

# 4. Проверить ответ API вручную
curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer invalid.jwt.token" \
  http://localhost:4000/api/notes
# Ожидается: 401
```

### Ожидаемый результат
- Backend возвращает `401 Unauthorized`
- `APIError.unauthorized` выбрасывается в `APIService`
- `NotesViewModel.errorMessage` обновляется: `"Unauthorized"` (или `"401"` / локализованное сообщение)
- `NotesViewModel.isLoading` сбрасывается в `false`
- `NotesViewModel.notes` остаётся пустым или сохраняет предыдущий стейт
- В UI отображается ошибка, а не список заметок

---

## SC-4: Корректное отображение списка заметок

**Тип:** UI
**Приоритет:** HIGH

### Предусловия
- Валидный токен установлен в UserDefaults (см. SC-2, шаги 1–2)
- Backend запущен, содержит 3+ тестовых заметки с полем `content`

### Шаги

```bash
# 1. Получить и установить токен
TOKEN=$(curl -s -X POST http://localhost:4000/api/auth/dev-token \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")
xcrun simctl spawn booted defaults write com.ultrawork.notes token "$TOKEN"

# 2. Создать тестовые заметки
for i in 1 2 3; do
  curl -s -X POST http://localhost:4000/api/notes \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"content\": \"Заметка №$i\"}"
done

# 3. Запустить приложение
xcrun simctl terminate booted com.ultrawork.notes 2>/dev/null || true
xcrun simctl launch booted com.ultrawork.notes
sleep 2

# 4. Проверить список через API
curl -s -H "Authorization: Bearer $TOKEN" http://localhost:4000/api/notes | python3 -m json.tool
```

### Ожидаемый результат
- `ProgressView` (индикатор загрузки) отображается кратко во время запроса, затем исчезает
- Список заметок отображает корректные тексты (`content` → `text` через CodingKeys)
- Количество заметок в UI совпадает с количеством в ответе API
- `NotesViewModel.isLoading` = `false` после загрузки
- Нет отображения ошибки

---

## SC-5: Pull-to-refresh / повторный вызов fetchNotes()

**Тип:** UI
**Приоритет:** HIGH

### Предусловия
- Валидный токен установлен в UserDefaults
- Приложение уже открыто и список заметок загружен (см. SC-4)

### Шаги

```bash
# 1. Убедиться что токен актуален
TOKEN=$(curl -s -X POST http://localhost:4000/api/auth/dev-token \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")
xcrun simctl spawn booted defaults write com.ultrawork.notes token "$TOKEN"

# 2. Добавить новую заметку пока приложение открыто
curl -s -X POST http://localhost:4000/api/notes \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"content": "Новая заметка после refresh"}'

# 3. Выполнить pull-to-refresh в UI симулятора
# (жест свайп вниз на списке заметок)

# 4. Наблюдать поведение isLoading
```

### Ожидаемый результат
- При начале pull-to-refresh `NotesViewModel.isLoading` переключается в `true`
- `ProgressView` (или `.refreshable` индикатор SwiftUI) отображается во время запроса
- После получения ответа `isLoading` сбрасывается в `false`
- Список заметок обновляется: новая заметка появляется в списке
- `errorMessage` = `nil` (нет ошибок)

---

## Примечания

- **Bundle ID:** `com.ultrawork.notes` (из `Info.plist: CFBundleIdentifier`)
- **BASE_URL:** `http://localhost:4000/api` (из `Info.plist: BASE_URL`)
- **Token key:** `"token"` (UserDefaults)
- **Dev-token endpoint:** `POST /api/auth/dev-token`
- **Notes endpoint:** `GET /api/notes` (требует Bearer JWT)
- **JSON поле:** `content` → маппится в `Note.text` через `CodingKeys`
