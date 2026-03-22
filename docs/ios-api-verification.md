# iOS API verification

## Purpose

This document is a **manual verification template** for checking real iOS networking against `ultrawork/e2e-test-backend` **after** a real network layer is added to this iOS app.

It is intentionally limited to what is verifiable from the current repositories:

- the iOS repository currently contains **no** `APIService` type;
- the iOS repository currently contains **no** `API_BASE_URL` configuration key in `Info.plist`;
- the backend `.env.example` defines `API_BASE_URL=http://localhost:3000/api` for mobile clients;
- the backend currently exposes `/health` and mounts `/api/auth` and `/api/notes` routes;
- the backend repository currently contains **no** `/api/categories` routes;
- `src/routes/notes.routes.ts` currently contains route comments only, without implemented handlers.

Because of that, this document does **not** claim that category CRUD or note CRUD can be executed successfully against the current backend revision. Instead, it provides:

1. a factual checklist for verifying the backend that exists today;
2. `curl` examples that show the **currently reachable paths**;
3. expected outcomes for the current repository state, including likely `404` responses for unimplemented note handlers;
4. a future-state checklist to use once real iOS networking and backend handlers are implemented.

## Scope and current repository state

### iOS repository facts

Verified in this repository:

- `NotesApp/NotesApp/Info.plist` contains bundle metadata only.
- There is no checked-in `API_BASE_URL` app setting.
- There is no checked-in `APIService` implementation or obvious networking composition root to switch from mock to real backend.

Implication:

- any mention of enabling a real network layer in the app is a **future integration step**, not a currently available in-repo toggle.

### Backend repository facts

Verified in `ultrawork/e2e-test-backend`:

- `.env.example` includes `API_BASE_URL=http://localhost:3000/api`;
- `src/app.ts` defines `GET /health` and mounts `app.use("/api", router)`;
- `src/routes/index.ts` mounts `/auth` and `/notes`;
- `src/routes/notes.routes.ts` contains only commented route declarations;
- no `/api/categories` router exists in the repository tree;
- `prisma/schema.prisma` defines a `Note` model with a single enum field `category`, not a category relation array.

Implication:

- `/api/categories` must be treated as **not available** in the current backend;
- note payloads should be described, when discussing schema shape, with a single `category` enum field such as `PERSONAL`, `WORK`, or `IDEAS`;
- successful live CRUD verification for notes/categories is blocked until backend handlers are implemented.

## Prerequisites

1. Clone and start `ultrawork/e2e-test-backend`.
2. Ensure the backend listens on port `3000`.
3. Use the backend `.env.example` value for mobile clients:

```text
API_BASE_URL=http://localhost:3000/api
```

4. Confirm the backend process is reachable:

```bash
curl -i http://localhost:3000/health
```

Expected response from the current backend:

```http
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8

{"status":"ok"}
```

## API_BASE_URL configuration

### Confirmed backend value

The backend repository documents this mobile base URL:

```text
http://localhost:3000/api
```

### Simulator vs physical device

- **iOS Simulator**: `http://localhost:3000/api` can reach services on the host Mac.
- **Physical device**: replace `localhost` with the Mac LAN IP, for example:

```text
http://192.168.1.50:3000/api
```

### Current iOS app state

The current iOS repository does **not** define `API_BASE_URL` in `NotesApp/NotesApp/Info.plist`.

### Fallback when the app has no runtime API configuration

If you are testing this repository exactly as checked in:

- keep using the app as-is for UI-only/mock-only checks;
- verify backend reachability separately with `curl`;
- if you temporarily add local configuration for experimentation, keep it uncommitted.

## How to enable the real network layer locally

This section is a **future-state checklist**. It does not describe a configuration that already exists in this repository.

Use it only on a local branch where networking has been added.

1. Open `NotesApp/NotesApp.xcodeproj` in Xcode.
2. Check whether your local experimental branch added support for reading `API_BASE_URL`.
3. If such support exists locally, set one of these values:
   - simulator: `http://localhost:3000/api`
   - device: `http://<YOUR_MAC_IP>:3000/api`
4. Check whether your local branch introduced a real networking service in place of mock/local data.
5. Run the app and inspect logs for outgoing requests.

If the repository remains in its current state, there is no in-repo switch to perform these steps, so backend verification is limited to direct `curl` checks.

## ATS and local HTTP testing

The documented local backend URL uses `http://`, so App Transport Security can block requests from a native iOS app.

Current repository fact:

- `Info.plist` does not contain visible ATS exceptions.

For manual local experiments only, one of the following is required:

- use HTTPS if your backend exposes it;
- add a local-only ATS exception and do not commit it in this documentation PR;
- or test the backend separately with `curl` while the app remains on mock/local behavior.

## Current backend checks you can run today

Set a shell variable first:

```bash
export API_BASE_URL=http://localhost:3000/api
```

## Health check

```bash
curl -i http://localhost:3000/health
```

Expected today:

- `200 OK`
- body `{"status":"ok"}`

## Categories endpoint status

`/api/categories` is **not present** in the current backend repository.

Verification command:

```bash
curl -i "$API_BASE_URL/categories"
```

Expected today:

- route is unavailable;
- typical Express result is `404 Not Found`.

Example response shape:

```http
HTTP/1.1 404 Not Found
```

Use this result as confirmation that category endpoints are not yet implemented, not as a test failure in this documentation PR.

## Notes endpoint status

The backend mounts `/api/notes`, but `src/routes/notes.routes.ts` currently exports an empty router with comments only.

Verification command:

```bash
curl -i "$API_BASE_URL/notes"
```

Expected today:

- the path is mounted, but no handler is implemented;
- typical Express result is `404 Not Found`.

Example response shape:

```http
HTTP/1.1 404 Not Found
```

## Notes contract notes from Prisma schema

When backend note handlers are eventually implemented, the Prisma schema indicates that a note uses a **single enum** field:

```json
{
  "title": "Manual API test",
  "content": "Created during verification.",
  "category": "WORK"
}
```

Enum values currently defined in `prisma/schema.prisma`:

- `PERSONAL`
- `WORK`
- `IDEAS`

This is the only backend data shape that can be documented from the current repository state. Do not use `categories: []` arrays or `/api/notes?category=<ID>` examples for current manual verification.

## Future-state request examples

The following examples are **templates for a future backend revision** where note handlers exist. They are not guaranteed to succeed against the current backend checkout.

### GET /api/notes

```bash
curl -i "$API_BASE_URL/notes"
```

Target success criteria after backend implementation:

- `200 OK`
- JSON array of notes

Possible future response shape aligned with the Prisma schema:

```json
[
  {
    "id": "note-001",
    "title": "Sprint checklist",
    "content": "Validate backend integration from iOS.",
    "category": "WORK",
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
    "category": "WORK"
  }'
```

Target success criteria after backend implementation:

- `201 Created`
- response contains created note with single `category` enum field

### PUT /api/notes/:id

```bash
curl -i -X PUT "$API_BASE_URL/notes/note-qa-001" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Manual API test updated",
    "content": "Updated from curl during iOS verification.",
    "category": "IDEAS"
  }'
```

Target success criteria after backend implementation:

- `200 OK`
- response reflects updated scalar `category`

### DELETE /api/notes/:id

```bash
curl -i -X DELETE "$API_BASE_URL/notes/note-qa-001"
```

Target success criteria after backend implementation:

- `204 No Content`

### Filtering notes by category

The product requirement mentions selecting notes by category. The current backend schema suggests this should map to a scalar enum filter, for example a future query shape such as:

```bash
curl -i "$API_BASE_URL/notes?category=WORK"
```

This query form is documented here as a **candidate verification example**, not as a confirmed live endpoint in the current backend codebase.

## Expected models for future note handlers

### Note

Future response shape should stay consistent with the Prisma schema unless backend implementation intentionally diverges:

```json
{
  "id": "note-001",
  "title": "Sprint checklist",
  "content": "Validate backend integration from iOS.",
  "category": "WORK",
  "createdAt": "2026-03-20T12:00:00.000Z",
  "updatedAt": "2026-03-20T12:05:00.000Z"
}
```

Fields:

- `id`
- `title`
- `content`
- `category` — single enum value, not an array
- `createdAt`
- `updatedAt`

No current backend evidence supports a separate category entity response model for `/api/categories`.

## Manual verification scenarios

## Scenario A — verify current backend availability

Preparation:

- backend is running.

Action:

- call `/health`.

Expected result today:

- `200 OK`;
- body contains `{"status":"ok"}`.

## Scenario B — verify categories are not implemented yet

Action:

- call `GET /api/categories` with `curl`.

Expected result today:

- `404 Not Found` or equivalent route-not-found response.

Interpretation:

- this confirms the current backend has no category endpoints.

## Scenario C — verify notes handlers are not implemented yet

Action:

- call `GET /api/notes` with `curl`.

Expected result today:

- `404 Not Found` or equivalent route-not-found response.

Interpretation:

- router mount exists, but handlers are still absent.

## Scenario D — future note create/update/delete verification

Use this scenario only after backend note handlers and an iOS network layer are implemented.

Preparation:

- app branch includes a real networking service;
- runtime base URL is configurable;
- backend implements note CRUD.

Action:

- create a note with `category` set to one enum value such as `WORK`;
- update it to another enum value such as `IDEAS`;
- delete it;
- optionally query notes filtered by `category=WORK` if backend implementation supports that form.

Expected future result:

- create returns `201`;
- update returns `200`;
- delete returns `204`;
- all request/response bodies use a single `category` field.

## Example logs

### Current-state backend verification logs

```text
$ curl -i http://localhost:3000/health
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8

{"status":"ok"}
```

```text
$ curl -i http://localhost:3000/api/categories
HTTP/1.1 404 Not Found
```

```text
$ curl -i http://localhost:3000/api/notes
HTTP/1.1 404 Not Found
```

### Future iOS debug log examples

These are illustrative examples for a later branch that introduces real networking:

```text
[Network] Request: GET http://localhost:3000/api/notes
[Network] Response: 200 OK
[Network] Body: [{"id":"note-001","title":"Sprint checklist","content":"Validate backend integration from iOS.","category":"WORK"}]
```

```text
[Network] Request failed: NSURLErrorDomain Code=-1004 "Could not connect to the server."
```

## Common issues and diagnostics

### Wrong API_BASE_URL

Symptoms:

- requests go to the wrong host or wrong path;
- `404` on valid paths;
- transport errors in app logs.

Checks:

- confirm `/api` is included in the base URL;
- confirm simulator uses `localhost`, but physical device uses the Mac IP;
- confirm the app branch actually supports runtime API configuration.

### Backend unavailable

Symptoms:

- `curl http://localhost:3000/health` fails;
- app-side transport errors such as `NSURLErrorDomain`.

Checks:

- ensure backend process or container is running;
- confirm port `3000` is exposed;
- retry `/health` before app testing.

### ATS blocking HTTP

Symptoms:

- app request fails immediately even though `curl` on the Mac works.

Checks:

- inspect local ATS settings;
- use HTTPS or a local-only ATS exception.

### CORS

For a normal native iOS app using `URLSession`, browser-style CORS restrictions are **not usually relevant**.

This matters only if you are debugging through browser-based tooling, a web view, or an intermediate web client.

### 4xx errors

Possible causes once handlers are implemented:

- invalid payload;
- unsupported enum value in `category`;
- missing route or missing record.

Checks:

- compare payloads with the Prisma-backed shape in this document;
- verify whether the backend revision you are testing actually implements the route.

### 5xx errors

Possible causes:

- server exception;
- database unavailable;
- Prisma migration mismatch.

Checks:

- inspect backend logs;
- verify database connectivity;
- rerun backend setup and migrations.

## Manual checklist

### Current repository state

- [ ] Backend is running and `/health` returns `200`
- [ ] Confirmed backend `.env.example` documents `API_BASE_URL=http://localhost:3000/api`
- [ ] Confirmed iOS `Info.plist` does not define `API_BASE_URL`
- [ ] Confirmed iOS repository does not currently expose a checked-in `APIService` switch
- [ ] `GET /api/categories` returns route-not-found, matching current backend state
- [ ] `GET /api/notes` returns route-not-found, matching current backend state
- [ ] ATS considerations are understood for any future native HTTP test

### Future integration branch

- [ ] Real iOS networking is wired in locally
- [ ] Runtime base URL is configurable
- [ ] `GET /api/notes` succeeds
- [ ] Note create/update/delete succeeds with scalar `category`
- [ ] Category-related verification is attempted only if backend category endpoints are actually implemented
