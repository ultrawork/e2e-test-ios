# Notes — Android App

Android-клиент кроссплатформенного приложения для заметок. Часть монорепозитория с бекендом (Express.js), веб-клиентом (Next.js) и iOS-приложением (SwiftUI).

## Технологический стек

- **Язык:** Kotlin
- **UI:** Jetpack Compose + Material3 (Dynamic Colors)
- **Архитектура:** MVVM (ViewModel + Coroutines/Flow)
- **DI:** Hilt
- **Сеть:** Retrofit + Moshi + OkHttp
- **Навигация:** Navigation Compose
- **Хранение токенов:** EncryptedSharedPreferences
- **Сборка:** Gradle KTS + Version Catalogs

## Структура проекта

```
app/src/main/java/com/ultrawork/notes/
├── di/                  # Hilt-модули (AppModule)
├── data/
│   ├── local/           # TokenManager (EncryptedSharedPreferences)
│   ├── remote/          # ApiService, AuthInterceptor (Retrofit)
│   └── repository/      # AuthRepository, NotesRepository
├── model/               # Модели данных (NoteCategory)
├── navigation/          # NavGraph, Routes
├── ui/
│   ├── theme/           # Material3 тема (Color, Type, Theme)
│   ├── screens/         # Экраны (Login, Register, NotesList, NoteDetail)
│   └── components/      # Переиспользуемые UI-компоненты
├── viewmodel/           # ViewModels
├── MainActivity.kt
└── NotesApplication.kt
```

## Getting Started

### Требования

- Android Studio Hedgehog (2023.1.1) или новее
- JDK 17
- Android SDK 35

### Запуск

1. Клонируйте репозиторий:
   ```bash
   git clone https://github.com/ultrawork/e2e-test-ios.git
   cd e2e-test-ios
   ```

2. Скопируйте `.env.example` и настройте переменные:
   ```bash
   cp .env.example .env
   ```

3. Откройте проект в Android Studio и дождитесь синхронизации Gradle.

4. Укажите `API_BASE_URL` в `gradle.properties` или при сборке:
   ```bash
   ./gradlew assembleDebug -PAPI_BASE_URL="http://10.0.2.2:3000/api"
   ```

5. Запустите на эмуляторе или устройстве.

### Сборка релиза (Docker)

```bash
docker build --output type=local,dest=./out .
```

APK будет в `./out/apk/`.

## Переменные окружения

| Переменная | Описание | По умолчанию |
|---|---|---|
| `API_BASE_URL` | URL бекенд-API | `http://10.0.2.2:3000/api` |

Полный список переменных для всего проекта — в `.env.example`.
