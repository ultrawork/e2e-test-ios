# E2E Сценарии: iOS Notes v32 — Верификация APIService и NotesViewModel

**Версия:** v32
**Дата:** 2026-03-31
**Платформа:** iOS (SwiftUI)
**Тип тестирования:** End-to-End (интеграционное)

---

## Справочная таблица

| Параметр | Значение |
|---|---|
| Bundle ID | `com.ultrawork.notes` |
| BASE_URL | `http://localhost:4000/api` |
| Ключ токена (UserDefaults) | `"token"` |
| Endpoint: список заметок | `GET /api/notes` |
| Endpoint: создание заметки | `POST /api/notes` |
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

### Запрос заметок без токена

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

## Сценарии

---

### SC-1: Запуск приложения без токена — ошибка авторизации, пустой список

**Приоритет:** HIGH
**Тип:** automated

#### Шаги

1. Удалить токен из UserDefaults:

```bash
xcrun simctl spawn booted defaults delete com.ultrawork.notes token 2>/dev/null; echo "Token deleted"
```

2. Подтвердить, что backend возвращает 401 без токена:

```bash
curl -s -w "\nHTTP_CODE:%{http_code}\n" http://localhost:4000/api/notes
```

**Ожидаемый ответ:** HTTP 401, `{"error":"Unauthorized"}`

3. Запустить приложение в симуляторе (или через Xcode).

4. Наблюдать поведение приложения.

#### Ожидаемый результат

| Свойство | Значение |
|---|---|
| `notes` | `[]` (пустой массив) |
| `errorMessage` | `"Unauthorized"` |
| `isLoading` | `false` |

Приложение отображает пустой список и сообщение об ошибке авторизации. APIService получает HTTP 401 и выбрасывает `APIError.unauthorized`.

---

### SC-2: Загрузка заметок с dev-token (GET /api/notes)

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

3. Проверить, что токен записан:

```bash
xcrun simctl spawn booted defaults read com.ultrawork.notes token
```

4. Создать тестовую заметку через API:

```bash
curl -s -X POST http://localhost:4000/api/notes \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"content":"Test note from E2E v32"}'
```

**Ожидаемый ответ:** `201 Created` с телом заметки.

5. Подтвердить наличие заметок через GET:

```bash
curl -s http://localhost:4000/api/notes \
  -H "Authorization: Bearer $TOKEN" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(f'Notes count: {len(data)}')
for n in data:
    print(f'  - {n.get(\"content\", n.get(\"text\", \"N/A\"))}')"
```

6. Запустить/перезапустить приложение в симуляторе.

#### Ожидаемый результат

| Свойство | Значение |
|---|---|
| `notes` | `≠ []` (массив содержит заметки) |
| `errorMessage` | `nil` |
| `isLoading` | `false` (после завершения загрузки) |

NotesViewModel вызывает `fetchNotes()`, APIService отправляет GET `/api/notes` с Bearer-токеном, ответ декодируется в массив `[Note]`. Маппинг: поле `content` из API → свойство `text` модели Note (через `CodingKeys`).

---

### SC-3: Обработка 401 при невалидном токене

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

#### Ожидаемый результат

| Свойство | Значение |
|---|---|
| `notes` | `[]` (пустой массив) |
| `errorMessage` | `"Unauthorized"` |
| `isLoading` | `false` |

APIService получает HTTP 401 и выбрасывает `APIError.unauthorized`. NotesViewModel обрабатывает ошибку, устанавливает `errorMessage` и оставляет `notes` пустым.

---

### SC-4: Корректное отображение списка в UI

**Приоритет:** HIGH
**Тип:** manual

#### Шаги

1. Получить dev-token и записать в симулятор:

```bash
TOKEN=$(curl -s -X POST http://localhost:4000/api/auth/dev-token | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")
xcrun simctl spawn booted defaults write com.ultrawork.notes token "$TOKEN"
```

2. Создать 3 тестовых заметки через API:

```bash
for i in 1 2 3; do
  curl -s -X POST http://localhost:4000/api/notes \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"content\":\"E2E v32 заметка #$i\"}"
  echo ""
done
```

3. Подтвердить количество заметок через API:

```bash
COUNT=$(curl -s http://localhost:4000/api/notes \
  -H "Authorization: Bearer $TOKEN" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))")
echo "Notes count from API: $COUNT"
```

4. Запустить/перезапустить приложение в симуляторе.

5. Визуально проверить:
   - ProgressView (индикатор загрузки) появляется и исчезает
   - Количество заметок в списке совпадает с `$COUNT`
   - Текст каждой заметки отображается корректно (маппинг `content` → `text`)
   - Список прокручивается

#### Ожидаемый результат

| Проверка | Ожидание |
|---|---|
| ProgressView | Появляется при загрузке, исчезает после |
| Количество элементов | Совпадает с числом заметок в API |
| Текст заметок | Содержимое поля `content` из API отображается корректно |
| Прокрутка | Список прокручивается без артефактов |

---

### SC-5: Pull-to-refresh инициирует повторный fetchNotes

**Приоритет:** HIGH
**Тип:** manual

#### Шаги

1. Убедиться, что приложение запущено с валидным токеном и список заметок отображается (см. SC-4).

2. Запомнить текущее количество заметок в UI.

3. Добавить новую заметку через API (пока приложение запущено):

```bash
TOKEN=$(xcrun simctl spawn booted defaults read com.ultrawork.notes token)
curl -s -X POST http://localhost:4000/api/notes \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"content":"Новая заметка для pull-to-refresh"}'
echo ""
```

4. В симуляторе: потянуть список вниз (pull-to-refresh жест).

5. Наблюдать обновление списка.

#### Ожидаемый результат

| Проверка | Ожидание |
|---|---|
| `isLoading` | `true` во время загрузки → `false` после |
| Количество заметок | Увеличилось на 1 |
| Новая заметка | Отображается в списке с текстом «Новая заметка для pull-to-refresh» |
| Порядок | Список обновлён без дублирования |

NotesViewModel при pull-to-refresh вызывает `fetchNotes()` повторно, APIService выполняет GET `/api/notes`, и UI обновляется новыми данными.

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
