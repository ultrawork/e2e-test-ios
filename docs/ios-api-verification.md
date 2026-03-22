# iOS API verification

## Purpose

This document describes how to manually verify real `APIService` calls from the iOS app to the backend without committing runtime code changes. It is intended as a QA runbook for validating the backend integration after the real networking layer is wired into the app.

## Scope and current repository state

- This is a documentation-only workflow.
- In the current iOS repository state, `NotesApp/NotesApp/Info.plist` does **not** contain `API_BASE_URL`.
- If the currently checked out iOS branch still uses mock data only, use this document as the verification checklist for the branch where `APIService` is actually connected.
- If `API_BASE_URL` is missing or the real networking layer is not enabled, fall back to the existing mock behavior and do not commit local configuration changes in this PR.

## Prerequisites

1. Start the backend from `ultrawork/e2e-test-backend`.
2. Ensure the backend is reachable on port `3000`.
3. Use the backend `.env.example` value for mobile clients:
   - `API_BASE_URL=http://localhost:3000/api`
4. Confirm backend health before testing:

```bash
curl -i http://localhost:3000/health
```

Expected response:

```http
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8

{"status":"ok"}
```

## API_BASE_URL configuration

### Recommended local value

For local development and simulator-based checks, use:

```text
http://localhost:3000/api
```

### iOS Simulator vs physical device

- **iOS Simulator**: `http://localhost:3000/api` usually works because the simulator can access services running on the host Mac.
- **Physical device**: `localhost` points to the device itself, not your Mac. Use your Mac's LAN IP instead, for example:

```text
http://192.168.1.50:3000/api
```

### Current Info.plist state

The current `NotesApp/NotesApp/Info.plist` only contains bundle metadata and does **not** define `API_BASE_URL`.

### Fallback when API_BASE_URL is absent

If no `API_BASE_URL` is configured, or the app is still wired to mocks:

- keep using the mock implementation for normal local development;
- use the `curl` commands in this document to verify the backend independently;
- apply `Info.plist` changes only locally for manual testing, without committing them in this PR.

## How to enable the real network layer locally

Use the following checks without committing code changes:

1. Open `NotesApp/NotesApp.xcodeproj` in Xcode.
2. Inspect `NotesApp/NotesApp/Info.plist` and verify whether a custom `API_BASE_URL` key exists locally.
3. If your local integration branch supports reading `API_BASE_URL`, add it locally with one of these values:
   - simulator: `http://localhost:3000/api`
   - device: `http://<YOUR_MAC_IP>:3000/api`
4. Verify the app composition root / dependency wiring uses `APIService` instead of a mock service.
5. Run the app from Xcode.
6. Watch the Xcode debug console for request URLs, HTTP methods, status codes, decoding errors, and transport failures.
7. If calls still never leave the app, the build is still using a mock service or fallback path.

### Where to look in Xcode

- **Debug console**: `View` → `Debug Area` → `Activate Console`
- **Runtime logs**: Xcode app console during simulator/device execution
- **Breakpoints**: add temporary breakpoints where `APIService` is instantiated or where requests are built, if needed for local diagnosis

## ATS and local HTTP testing

Because the recommended local backend URL uses `http://`, App Transport Security may block requests depending on local configuration.

Current repository state:

- `Info.plist` does not show any `NSAppTransportSecurity` exceptions.

For local manual verification only, one of the following must be true:

- you test against an HTTPS backend endpoint; or
- you apply a local-only ATS exception in `Info.plist` and do not commit it in this PR; or
- you keep the app on the mock/fallback path and validate the backend separately with `curl`.

## API requests to verify manually

Set a shell variable first:

```bash
export API_BASE_URL=http://localhost:3000/api
```

If you test on a physical device, keep the app configured with your Mac IP, but `curl` can still use localhost when executed on the Mac itself.

## Categories endpoints

> Note: the backend repository currently exposes `/api/notes` in code and documents `User`, `Note`, and `Category` entities in the schema/requirements. The examples below follow the intended backend contract for manual verification of the iOS integration.

### GET /api/categories

```bash
curl -i "$API_BASE_URL/categories"
```

Expected status:

```text
200 OK
```

Example response:

```json
[
  {
    "id": "cat-001",
    "name": "Work",
    "color": "#3366FF",
    "createdAt": "2026-03-20T10:00:00.000Z"
  },
  {
    "id": "cat-002",
    "name": "Ideas",
    "color": "#FF9900",
    "createdAt": "2026-03-20T10:05:00.000Z"
  }
]
```

### POST /api/categories

```bash
curl -i -X POST "$API_BASE_URL/categories" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "QA Category",
    "color": "#1A2B3C"
  }'
```

Expected status:

```text
201 Created
```

Example response:

```json
{
  "id": "cat-qa-001",
  "name": "QA Category",
  "color": "#1A2B3C",
  "createdAt": "2026-03-20T11:00:00.000Z"
}
```

### PUT /api/categories/:id

```bash
curl -i -X PUT "$API_BASE_URL/categories/cat-qa-001" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "QA Category Updated",
    "color": "#4D8EFF"
  }'
```

Expected status:

```text
200 OK
```

Example response:

```json
{
  "id": "cat-qa-001",
  "name": "QA Category Updated",
  "color": "#4D8EFF",
  "createdAt": "2026-03-20T11:00:00.000Z"
}
```

### DELETE /api/categories/:id

```bash
curl -i -X DELETE "$API_BASE_URL/categories/cat-qa-001"
```

Expected status:

```text
204 No Content
```

Expected response body: empty.

## Notes endpoints

### GET /api/notes

```bash
curl -i "$API_BASE_URL/notes"
```

Expected status:

```text
200 OK
```

Example response:

```json
[
  {
    "id": "note-001",
    "title": "Sprint checklist",
    "content": "Validate backend integration from iOS.",
    "categories": [
      {
        "id": "cat-001",
        "name": "Work",
        "color": "#3366FF"
      }
    ],
    "createdAt": "2026-03-20T12:00:00.000Z",
    "updatedAt": "2026-03-20T12:00:00.000Z"
  }
]
```

### POST /api/notes

```bash
curl -i -X POST "$API_BASE_URL/notes" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Manual API test",
    "content": "Created from curl during iOS verification.",
    "categories": ["cat-001"]
  }'
```

Expected status:

```text
201 Created
```

Example response:

```json
{
  "id": "note-qa-001",
  "title": "Manual API test",
  "content": "Created from curl during iOS verification.",
  "categories": [
    {
      "id": "cat-001",
      "name": "Work",
      "color": "#3366FF"
    }
  ],
  "createdAt": "2026-03-20T12:30:00.000Z",
  "updatedAt": "2026-03-20T12:30:00.000Z"
}
```

### PUT /api/notes/:id

```bash
curl -i -X PUT "$API_BASE_URL/notes/note-qa-001" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Manual API test updated",
    "content": "Updated from curl during iOS verification.",
    "categories": ["cat-001", "cat-002"]
  }'
```

Expected status:

```text
200 OK
```

Example response:

```json
{
  "id": "note-qa-001",
  "title": "Manual API test updated",
  "content": "Updated from curl during iOS verification.",
  "categories": [
    {
      "id": "cat-001",
      "name": "Work",
      "color": "#3366FF"
    },
    {
      "id": "cat-002",
      "name": "Ideas",
      "color": "#FF9900"
    }
  ],
  "createdAt": "2026-03-20T12:30:00.000Z",
  "updatedAt": "2026-03-20T12:45:00.000Z"
}
```

### DELETE /api/notes/:id

```bash
curl -i -X DELETE "$API_BASE_URL/notes/note-qa-001"
```

Expected status:

```text
204 No Content
```

Expected response body: empty.

### GET /api/notes?category=<ID>

This is the backend query form for the user scenario “select notes by `categoryId`”.

```bash
curl -i "$API_BASE_URL/notes?category=cat-001"
```

Expected status:

```text
200 OK
```

Example response:

```json
[
  {
    "id": "note-001",
    "title": "Sprint checklist",
    "content": "Validate backend integration from iOS.",
    "categories": [
      {
        "id": "cat-001",
        "name": "Work",
        "color": "#3366FF"
      }
    ],
    "createdAt": "2026-03-20T12:00:00.000Z",
    "updatedAt": "2026-03-20T12:00:00.000Z"
  }
]
```

## Expected response models

### Category

Example JSON shape:

```json
{
  "id": "cat-001",
  "name": "Work",
  "color": "#3366FF",
  "createdAt": "2026-03-20T10:00:00.000Z"
}
```

Fields:

- `id`: backend identifier
- `name`: display name
- `color`: hex color in `#RRGGBB` format
- `createdAt`: optional creation timestamp if returned by backend

### Note

Example JSON shape:

```json
{
  "id": "note-001",
  "title": "Sprint checklist",
  "content": "Validate backend integration from iOS.",
  "categories": [
    {
      "id": "cat-001",
      "name": "Work",
      "color": "#3366FF"
    }
  ],
  "createdAt": "2026-03-20T12:00:00.000Z",
  "updatedAt": "2026-03-20T12:05:00.000Z"
}
```

Fields:

- `id`
- `title`
- `content`
- `categories`
- `createdAt`
- `updatedAt`

## Manual verification scenarios

## 1. Create category

Preparation:

- backend is running;
- app is configured to use real `APIService`;
- no existing category named `QA Category`.

Action:

- create a category in the UI, or execute `POST /api/categories` from this document.

Expected result:

- API returns `201 Created`;
- Xcode logs show a request to `/api/categories`;
- the new category appears in the UI category list;
- `GET /api/categories` returns the newly created category.

## 2. Update category

Preparation:

- a test category already exists.

Action:

- rename the category and change its color in the UI, or call `PUT /api/categories/:id`.

Expected result:

- API returns `200 OK`;
- Xcode logs show a `PUT` request with the target ID;
- UI shows the new name/color;
- `GET /api/categories` reflects the updated values.

## 3. Delete category

Preparation:

- a removable test category exists and is not required by another active check.

Action:

- delete the category in the UI, or call `DELETE /api/categories/:id`.

Expected result:

- API returns `204 No Content`;
- Xcode logs show the delete request and status code;
- the category disappears from the UI;
- `GET /api/categories` no longer includes the deleted ID.

## 4. Create note

Preparation:

- at least one category exists, for example `cat-001`.

Action:

- create a note in the UI and assign the category, or call `POST /api/notes`.

Expected result:

- API returns `201 Created`;
- Xcode logs show a `POST /api/notes` request;
- UI displays the new note;
- `GET /api/notes` returns the note with its category data.

## 5. Update note

Preparation:

- a test note already exists.

Action:

- edit title/content/categories in the UI, or call `PUT /api/notes/:id`.

Expected result:

- API returns `200 OK`;
- Xcode logs show the updated payload and response;
- UI refreshes with the new values;
- `GET /api/notes` returns the updated note.

## 6. Filter notes by category

Preparation:

- at least one note is linked to `cat-001`.

Action:

- trigger the category filter in the UI, or call `GET /api/notes?category=cat-001`.

Expected result:

- API returns `200 OK`;
- only notes belonging to the selected category are shown in the filtered UI state;
- Xcode logs show the query string `?category=cat-001`;
- direct `curl` verification returns matching notes only.

## 7. Delete note

Preparation:

- a removable test note exists.

Action:

- delete the note in the UI, or call `DELETE /api/notes/:id`.

Expected result:

- API returns `204 No Content`;
- Xcode logs show the delete request;
- the note disappears from the list;
- `GET /api/notes` no longer returns the deleted note.

## Example logs

### Successful request log

```text
[APIService] Request: GET http://localhost:3000/api/categories
[APIService] Response: 200 OK
[APIService] Body: [{"id":"cat-001","name":"Work","color":"#3366FF"}]
```

```text
[APIService] Request: POST http://localhost:3000/api/notes
[APIService] Body: {"title":"Manual API test","content":"Created from curl during iOS verification.","categories":["cat-001"]}
[APIService] Response: 201 Created
[APIService] Body: {"id":"note-qa-001","title":"Manual API test","content":"Created from curl during iOS verification.","categories":[{"id":"cat-001","name":"Work","color":"#3366FF"}],"createdAt":"2026-03-20T12:30:00.000Z","updatedAt":"2026-03-20T12:30:00.000Z"}
```

### Typical error logs

```text
[APIService] Request: POST http://localhost:3000/api/categories
[APIService] Response: 400 Bad Request
[APIService] Body: {"message":"Validation failed: color must match #RRGGBB"}
```

```text
[APIService] Request: PUT http://localhost:3000/api/notes/missing-id
[APIService] Response: 404 Not Found
[APIService] Body: {"message":"Note not found"}
```

```text
[APIService] Request failed: NSURLErrorDomain Code=-1004 "Could not connect to the server."
```

```text
[APIService] Decoding error: keyNotFound(CodingKeys(stringValue: "title", intValue: nil), ...)
```

## Common issues and diagnostics

### Wrong API_BASE_URL

Symptoms:

- requests go to the wrong host or wrong path;
- 404 on every endpoint;
- transport errors in the console.

Checks:

- confirm the app uses `/api` in the base URL;
- confirm simulator uses `localhost`, but devices use your Mac IP;
- print the resolved base URL in debug logs if needed.

### Backend unavailable

Symptoms:

- `NSURLErrorDomain` connection failures;
- `curl http://localhost:3000/health` fails.

Checks:

- ensure backend process or Docker container is running;
- confirm port `3000` is exposed;
- retry health check before opening the iOS app.

### ATS blocking HTTP

Symptoms:

- request fails immediately on device/simulator even though `curl` works on the Mac.

Checks:

- inspect local `Info.plist` ATS settings;
- use HTTPS if available;
- add a local-only ATS exception for manual testing if required.

### CORS

For a native iOS app, classic browser CORS restrictions usually do not apply in the same way. However, the topic can still appear during debugging through web tooling or proxies.

Checks:

- backend currently enables CORS via `app.use(cors())`;
- if a proxy or alternate environment is involved, confirm the backend still returns the needed headers.

### 4xx errors

Typical cases:

- `400 Bad Request`: invalid payload, invalid color format, missing required fields;
- `404 Not Found`: wrong ID, deleted entity, wrong route.

Checks:

- compare payload with the JSON examples in this document;
- confirm IDs were created in the same backend environment;
- repeat `GET` requests to verify current server state.

### 5xx errors

Typical cases:

- server exception;
- database unavailable;
- migration/schema mismatch.

Checks:

- inspect backend logs;
- verify database connectivity;
- rerun backend migrations/setup if needed.

## Manual checklist

- [ ] Backend is running and `/health` returns `200`
- [ ] Local `API_BASE_URL` is set correctly for simulator or device
- [ ] Real `APIService` is enabled instead of a mock service
- [ ] `GET /api/categories` returns `200`
- [ ] Category create/update/delete scenarios are verified
- [ ] `GET /api/notes` returns `200`
- [ ] Note create/update/delete scenarios are verified
- [ ] `GET /api/notes?category=<ID>` is verified for category filtering
- [ ] Xcode console shows real network activity
- [ ] Negative cases for wrong URL, 4xx, 5xx, and backend unavailability are understood
- [ ] Any local `Info.plist` or ATS change remains uncommitted
