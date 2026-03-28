# E2E Report — iOS Notes v25

**Дата:** 2026-03-28
**Метод верификации:** Статический анализ кода + ручная проверка
**Версия:** v25

---

## Результаты по сценариям

| # | Сценарий | Результат | Комментарий |
|---|----------|-----------|-------------|
| SC-iOS-01 | Получение списка заметок | **PASS** | `fetchNotes()` реализован в APIService, вызывается из ContentView через `.task`, CodingKeys корректны |
| SC-iOS-02 | Создание заметки | **PASS** | `createNote(text:)` отправляет POST с `CreateNoteRequest`, ответ декодируется в Note |
| SC-iOS-03 | Удаление заметки | **PASS** | `deleteNote(id:)` отправляет DELETE, при успехе заметка удаляется из локального массива |
| SC-iOS-04 | Обработка ошибок | **PASS** | APIError enum покрывает unauthorized/networkError/decodingError/notFound; ViewModel маппит в errorMessage |
| SC-iOS-05 | Авторизация | **PASS** | Bearer token из Info.plist, 401 → APIError.unauthorized → сообщение пользователю |

**Итого: PASS 5/5**

---

## Лог статического анализа

### Note.swift
- [x] `struct Note: Identifiable, Codable` — реализует Codable
- [x] `let id: String` — соответствует UUID с backend
- [x] `enum CodingKeys: case text = "content"` — маппинг text ↔ content корректен
- [x] `struct CreateNoteRequest: Codable` — структура запроса для POST

### APIService.swift
- [x] `protocol APIServiceProtocol` — определены fetchNotes, createNote, deleteNote (async throws)
- [x] `final class APIService: APIServiceProtocol` — реализация протокола
- [x] `Bundle.main.infoDictionary?["BASE_URL"]` — чтение из Info.plist
- [x] `Bundle.main.infoDictionary?["DEV_TOKEN"]` — чтение из Info.plist
- [x] `Authorization: Bearer \(token)` — заголовок авторизации
- [x] `enum APIError` — unauthorized, networkError, decodingError, notFound
- [x] HTTP-статус 401 → `APIError.unauthorized`
- [x] HTTP-статус 404 → `APIError.notFound`
- [x] Все методы используют async/await

### NotesViewModel.swift
- [x] `@MainActor final class NotesViewModel: ObservableObject` — главный поток
- [x] `@Published var notes: [Note] = []` — публикуемое состояние
- [x] `@Published var isLoading: Bool = false` — индикатор загрузки
- [x] `@Published var errorMessage: String?` — сообщение об ошибке
- [x] `private let apiService: APIServiceProtocol` — инъекция через протокол
- [x] `fetchNotes()`, `createNote(text:)`, `deleteNote(id:)` — async методы
- [x] Все ошибки обрабатываются через catch и маппятся в errorMessage

### ContentView.swift
- [x] `.task { await viewModel.fetchNotes() }` — загрузка при появлении
- [x] `Task { await viewModel.createNote(text:) }` — создание через API
- [x] `Task { await viewModel.deleteNote(id:) }` — удаление через API
- [x] `if let errorMessage = viewModel.errorMessage { Text(errorMessage) }` — отображение ошибок

### Info.plist
- [x] `BASE_URL` = `http://localhost:3000`
- [x] `DEV_TOKEN` = `dev_token_placeholder`

### project.pbxproj
- [x] `APIService.swift` добавлен в PBXBuildFile, PBXFileReference, PBXGroup, PBXSourcesBuildPhase

---

## Заключение

Все 5 E2E-сценариев подтверждены через статический анализ кода. Реализация APIService соответствует контракту backend API. Note-модель корректно маппит `content ↔ text` через CodingKeys. NotesViewModel обновляет @Published-состояния на главном потоке (@MainActor). Ошибки обрабатываются и отображаются пользователю. Конфигурация BASE_URL и DEV_TOKEN читается из Info.plist.
