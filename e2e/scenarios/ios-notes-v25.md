# E2E Scenarios — iOS Notes v25

## SC-iOS-01: Получение списка заметок

**Endpoint:** `GET /api/notes`
**Предусловие:** Backend запущен, DEV_TOKEN валиден в Info.plist.
**Шаги:**
1. Приложение запускается.
2. `ContentView` вызывает `viewModel.fetchNotes()` через `.task`.
3. `NotesViewModel.fetchNotes()` вызывает `apiService.fetchNotes()`.
4. `APIService` отправляет GET-запрос с заголовком `Authorization: Bearer {DEV_TOKEN}`.
5. Ответ декодируется через `JSONDecoder` с `CodingKeys` (`content` → `text`).

**Ожидаемый результат:** Список заметок отображается в `List`. `isLoading` переключается `true → false`. `errorMessage == nil`.

---

## SC-iOS-02: Создание заметки

**Endpoint:** `POST /api/notes`
**Предусловие:** Backend запущен, DEV_TOKEN валиден.
**Шаги:**
1. Пользователь вводит текст в `TextField` и нажимает кнопку добавления.
2. `ContentView` вызывает `viewModel.createNote(text:)` через `Task`.
3. `NotesViewModel.createNote` вызывает `apiService.createNote(text:)`.
4. `APIService` отправляет POST-запрос с телом `CreateNoteRequest` (`content: text`).
5. Ответ декодируется в `Note` и добавляется в `notes`.

**Ожидаемый результат:** Новая заметка появляется в списке. `isLoading` переключается `true → false`. `errorMessage == nil`.

---

## SC-iOS-03: Удаление заметки

**Endpoint:** `DELETE /api/notes/:id`
**Предусловие:** Backend запущен, в списке есть хотя бы одна заметка.
**Шаги:**
1. Пользователь свайпает заметку влево и нажимает «Delete».
2. `ContentView` вызывает `viewModel.deleteNote(id:)` через `Task`.
3. `NotesViewModel.deleteNote` вызывает `apiService.deleteNote(id:)`.
4. `APIService` отправляет DELETE-запрос.
5. При успехе заметка удаляется из локального массива `notes`.

**Ожидаемый результат:** Заметка исчезает из списка. Счётчик обновляется. `errorMessage == nil`.

---

## SC-iOS-04: Обработка ошибок

**Предусловие:** Backend недоступен или возвращает ошибку.
**Шаги:**
1. `APIService` бросает `APIError.networkError` при недоступности сервера.
2. `APIService` бросает `APIError.decodingError` при невалидном JSON.
3. `APIService` бросает `APIError.notFound` при 404.
4. `NotesViewModel` ловит ошибку и устанавливает `errorMessage`.

**Ожидаемый результат:** `errorMessage` содержит понятное сообщение. Ошибка отображается в `ContentView` через `Text` с `accessibilityIdentifier("error_message")`. `isLoading == false`.

---

## SC-iOS-05: Авторизация

**Предусловие:** DEV_TOKEN задан в Info.plist.
**Шаги:**
1. Все HTTP-запросы `APIService` включают заголовок `Authorization: Bearer {DEV_TOKEN}`.
2. При ответе 401 `APIService` бросает `APIError.unauthorized`.
3. `NotesViewModel` устанавливает `errorMessage = "Ошибка авторизации. Проверьте DEV_TOKEN."`.
4. При отсутствии/невалидном токене пользователю показывается ошибка.

**Ожидаемый результат:** Запросы авторизованы через Bearer token. При 401 — корректное сообщение об ошибке авторизации.
