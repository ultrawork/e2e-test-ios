# E2E Сценарии: iOS Notes v34 — Верификация APIService и NotesViewModel

**Версия:** v34
**Дата:** 2026-04-01
**Платформа:** iOS (SwiftUI)
**Тип тестирования:** End-to-End (интеграционное)

---

## Справочная таблица

| Параметр | Значение |
|---|---|
| Bundle ID | `com.ultrawork.notes` |
| BACKEND_BASE_URL | `http://localhost:4000/api` |
| Ключ токена (UserDefaults) | `"token"` |
| Endpoint: список заметок | `GET /api/notes` |
| Endpoint: создание заметки | `POST /api/notes` |
| Endpoint: удаление заметки | `DELETE /api/notes/:id` |
| Endpoint: dev-token | `POST /api/auth/dev-token` |
| Endpoint: health | `GET /health` |
| Симулятор | iPhone 14 (iOS 17+) |

---

## Предусловия

### 1. Запуск backend

```bash
cd ../e2e-test-backend
JWT_ENABLED=true npm run dev
# Backend должен быть доступен на http://localhost:4000
```

### 2. Запуск iOS Simulator

```bash
xcrun simctl boot "iPhone 14"
```

---

## curl-проверки статуса backend

Перед запуском сценариев убедитесь, что backend отвечает корректно.

### Health check

```bash
curl -s http://localhost:4000/health
```

**Ожидаемый ответ:** `200 OK`
```json
{"status":"ok"}
```

### Получение dev-token

```bash
curl -s -X POST http://localhost:4000/api/auth/dev-token
```

**Ожидаемый ответ:** `200 OK`
```json
{"token":"<jwt-строка>"}
```

### Запрос заметок без токена (401)

```bash
curl -s -w "\nHTTP_CODE:%{http_code}\n" http://localhost:4000/api/notes
```

**Ожидаемый ответ:** `401 Unauthorized`
```json
{"error":"Unauthorized"}
```

---

## Управление токеном в симуляторе

### Запись токена

```bash
xcrun simctl spawn booted defaults write com.ultrawork.notes token "<jwt>"
```

### Чтение токена

```bash
xcrun simctl spawn booted defaults read com.ultrawork.notes token
```

### Удаление токена

```bash
xcrun simctl spawn booted defaults delete com.ultrawork.notes token
```

---

## Конфигурация BACKEND_BASE_URL

APIService определяет базовый URL в следующем порядке приоритета:

1. `ProcessInfo.processInfo.environment["BACKEND_BASE_URL"]`
2. `ProcessInfo.processInfo.environment["BASE_URL"]`
3. `Bundle.main.infoDictionary["BACKEND_BASE_URL"]`
4. `Bundle.main.infoDictionary["BASE_URL"]`
5. По умолчанию: `"http://localhost:4000/api"`

Для переопределения через Xcode Scheme: Edit Scheme → Run → Arguments → Environment Variables → добавить `BACKEND_BASE_URL`.

Для XCUITest: задать через `app.launchEnvironment["BACKEND_BASE_URL"]` или `app.launchEnvironment["BASE_URL"]`.

---

## Сценарии

---

### SC-1: Пустой список при валидном токене

**Приоритет:** HIGH
**Тип:** manual

#### Шаги

1. Получить dev-token и записать в симулятор:

```bash
TOKEN=$(curl -s -X POST http://localhost:4000/api/auth/dev-token | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")
xcrun simctl spawn booted defaults write com.ultrawork.notes token "$TOKEN"
```

2. Убедиться, что в backend нет заметок (удалить все через API при необходимости):

```bash
NOTES=$(curl -s http://localhost:4000/api/notes -H "Authorization: Bearer $TOKEN")
echo "$NOTES" | python3 -c "
import sys, json
notes = json.load(sys.stdin)
for n in notes:
    print(f'Deleting {n[\"id\"]}')" 2>/dev/null
# Удалить каждую заметку
for ID in $(echo "$NOTES" | python3 -c "import sys,json; [print(n['id']) for n in json.load(sys.stdin)]" 2>/dev/null); do
  curl -s -X DELETE "http://localhost:4000/api/notes/$ID" -H "Authorization: Bearer $TOKEN"
done
```

3. Запустить/перезапустить приложение в симуляторе.

#### Ожидаемый результат

| Свойство | Значение |
|---|---|
| `notes` | `[]` (пустой массив) |
| `errorMessage` | `nil` |
| `isLoading` | `false` |

UI отображает пустой список без ошибок. Счётчик заметок показывает 0.

---

### SC-2: Успешная загрузка заметок (GET /api/notes)

**Приоритет:** HIGH
**Тип:** automated

#### Шаги

1. Получить dev-token:

```bash
TOKEN=$(curl -s -X POST http://localhost:4000/api/auth/dev-token | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")
echo "TOKEN=$TOKEN"
```

2. Записать токен в UserDefaults симулятора:

```bash
xcrun simctl spawn booted defaults write com.ultrawork.notes token "$TOKEN"
```

3. Создать тестовые заметки через API:

```bash
for i in 1 2 3; do
  curl -s -X POST http://localhost:4000/api/notes \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"content\":\"E2E v34 заметка #$i\"}"
  echo ""
done
```

4. Подтвердить наличие заметок через GET:

```bash
curl -s http://localhost:4000/api/notes \
  -H "Authorization: Bearer $TOKEN" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(f'Notes count: {len(data)}')
for n in data:
    print(f'  - {n.get(\"content\", n.get(\"text\", \"N/A\"))}')"
```

5. Запустить/перезапустить приложение в симуляторе.

#### Ожидаемый результат

| Свойство | Значение |
|---|---|
| `notes` | `≠ []` (массив содержит заметки) |
| `errorMessage` | `nil` |
| `isLoading` | `false` (после завершения загрузки) |

NotesViewModel вызывает `fetchNotes()`, APIService отправляет GET `/api/notes` с Bearer-токеном, ответ декодируется в массив `[Note]`. Маппинг: поле `content` из API → свойство `text` модели Note (через `CodingKeys`).

---

### SC-3: Создание заметки через UI (POST /api/notes)

**Приоритет:** HIGH
**Тип:** manual

#### Шаги

1. Убедиться, что приложение запущено с валидным токеном (см. SC-2).

2. В UI: ввести текст в поле ввода (new_note_text_field).

3. Нажать кнопку добавления (add_note_button).

4. Наблюдать обновление списка.

5. Подтвердить, что заметка создана на backend:

```bash
TOKEN=$(xcrun simctl spawn booted defaults read com.ultrawork.notes token)
curl -s http://localhost:4000/api/notes \
  -H "Authorization: Bearer $TOKEN" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(f'Notes count: {len(data)}')
for n in data:
    print(f'  - {n.get(\"content\", \"N/A\")}')"
```

#### Ожидаемый результат

| Проверка | Ожидание |
|---|---|
| Поле ввода | Очищается после нажатия кнопки |
| Список заметок | Новая заметка появляется в списке |
| Backend | Заметка существует в GET /api/notes |
| `errorMessage` | `nil` |

ViewModel вызывает `createNote(text:)`, APIService отправляет POST `/api/notes` с `{"content":"<text>"}`, созданная заметка добавляется в `notes`.

---

### SC-4: Удаление заметки через UI (DELETE /api/notes/:id)

**Приоритет:** HIGH
**Тип:** manual

#### Шаги

1. Убедиться, что приложение запущено с валидным токеном и в списке есть заметки (см. SC-2, SC-3).

2. Запомнить количество заметок.

3. В UI: свайпнуть заметку влево и нажать «Delete».

4. Наблюдать обновление списка.

5. Подтвердить удаление на backend:

```bash
TOKEN=$(xcrun simctl spawn booted defaults read com.ultrawork.notes token)
curl -s http://localhost:4000/api/notes \
  -H "Authorization: Bearer $TOKEN" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(f'Notes count: {len(data)}')"
```

#### Ожидаемый результат

| Проверка | Ожидание |
|---|---|
| Количество заметок | Уменьшилось на 1 |
| Удалённая заметка | Отсутствует в списке UI |
| Backend | Заметка отсутствует в GET /api/notes |
| `errorMessage` | `nil` |

ViewModel вызывает `deleteNote(id:)`, APIService отправляет DELETE `/api/notes/:id`, при успешном 2xx ответе заметка удаляется из `notes`.

---

### SC-5: 401 Unauthorized — сброс токена и возврат к пустому состоянию

**Приоритет:** HIGH
**Тип:** automated

#### Шаги

1. Записать невалидный токен:

```bash
xcrun simctl spawn booted defaults write com.ultrawork.notes token "invalid.jwt.token"
```

2. Подтвердить, что backend возвращает 401 с невалидным токеном:

```bash
curl -s -w "\nHTTP_CODE:%{http_code}\n" http://localhost:4000/api/notes \
  -H "Authorization: Bearer invalid.jwt.token"
```

**Ожидаемый ответ:** HTTP 401, `{"error":"Unauthorized"}`

3. Запустить/перезапустить приложение в симуляторе.

4. Наблюдать поведение приложения.

5. Проверить, что токен удалён из UserDefaults:

```bash
xcrun simctl spawn booted defaults read com.ultrawork.notes token 2>&1
# Ожидаемый результат: ошибка "does not exist" (токен удалён)
```

#### Ожидаемый результат

| Свойство | Значение |
|---|---|
| `notes` | `[]` (пустой массив) |
| `errorMessage` | `"Unauthorized"` |
| `isLoading` | `false` |
| Токен в UserDefaults | Удалён (сброшен) |

APIService получает HTTP 401 и выбрасывает `APIError.unauthorized`. NotesViewModel обрабатывает ошибку: очищает `notes`, удаляет токен из UserDefaults, устанавливает `errorMessage = "Unauthorized"`. UI отображает пустой список и сообщение об ошибке.

---

### SC-6: Обработка ошибок (500) без крэшей

**Приоритет:** HIGH
**Тип:** manual

#### Шаги

1. Записать валидный токен в симулятор.

2. Остановить backend (kill процесс или Ctrl+C).

3. Запустить/перезапустить приложение в симуляторе.

4. Наблюдать поведение приложения.

5. Попробовать создать заметку через UI.

6. Попробовать выполнить pull-to-refresh.

#### Ожидаемый результат

| Проверка | Ожидание |
|---|---|
| Приложение | НЕ крашится |
| `errorMessage` | Содержит описание ошибки (network error или server error) |
| `notes` | `[]` или предыдущее состояние |
| Создание заметки | Не выполняется, отображается ошибка |
| Pull-to-refresh | Повторяет загрузку, при неудаче — ошибка |

При недоступности backend APIService выбрасывает `APIError.networkError` или `APIError.serverError(500)`. NotesViewModel обрабатывает ошибку, устанавливает `errorMessage`. UI не падает, отображает сообщение об ошибке.

---

## Примечания по запуску

### Сборка и запуск приложения

```bash
xcodebuild -project NotesApp/NotesApp.xcodeproj \
  -scheme NotesApp \
  -destination 'platform=iOS Simulator,name=iPhone 14' \
  build
```

### Запуск UI-тестов (если настроены)

```bash
xcodebuild -project NotesApp/NotesApp.xcodeproj \
  -scheme NotesApp \
  -destination 'platform=iOS Simulator,name=iPhone 14' \
  test
```

### Полный цикл управления токеном

```bash
# 1. Получить dev-token
TOKEN=$(curl -s -X POST http://localhost:4000/api/auth/dev-token | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")

# 2. Записать в симулятор
xcrun simctl spawn booted defaults write com.ultrawork.notes token "$TOKEN"

# 3. Проверить запись
xcrun simctl spawn booted defaults read com.ultrawork.notes token

# 4. (после тестов) Удалить токен
xcrun simctl spawn booted defaults delete com.ultrawork.notes token
```
