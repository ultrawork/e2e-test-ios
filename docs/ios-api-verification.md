# iOS API verification

## Purpose

This document is a manual QA runbook for validating **currently implemented backend connectivity facts** that are relevant to the iOS app.

It intentionally separates:

- what is **implemented today** in `ultrawork/e2e-test-backend`;
- what is only a **future integration scenario** once the iOS app gets a real `APIService` and runtime base URL wiring.

This PR is documentation-only and does **not** add networking code to the iOS app.

## Scope and current repository state

### iOS repository (`ultrawork/e2e-test-ios`)

Current checked-in state of this repository:

- there is **no `APIService` implementation** in the tree;
- there is **no real network layer wiring** in the app composition shown in the repository;
- `NotesApp/NotesApp/Info.plist` does **not** contain `API_BASE_URL`;
- `Info.plist` also does **not** contain any App Transport Security exception for local `http://` testing.

Because of that, the steps below that mention app-side real networking must be read as a **future verification template** for the branch where such wiring exists locally.

### Backend repository (`ultrawork/e2e-test-backend`)

Current checked-in backend facts at the time of writing:

- `GET /health` is implemented and returns `{"status":"ok"}`;
- `/api/auth/*` routes are mounted;
- `/api/notes` router is mounted, but `src/routes/notes.routes.ts` currently contains **route comments only** and no implemented handlers;
- there is **no `/api/categories` router** in the backend repository;
- Prisma schema defines `Note.category` as a **single enum field** (`PERSONAL`, `WORK`, `IDEAS`), not a category entity relation and not an array of categories.

This means the backend does **not currently provide real endpoints** for the CRUD scenarios originally planned for categories and notes.

## Prerequisites

1. Start the backend from `ultrawork/e2e-test-backend`.
2. Ensure the backend is reachable on port `3000`.
3. Use the backend `.env.example` value for mobile clients:

```text
API_BASE_URL=http://localhost:3000/api
```

4. Confirm backend health before any manual checks:

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

For local development and simulator-based checks, the backend repository documents this value:

```text
http://localhost:3000/api
```

### iOS Simulator vs physical device

- **iOS Simulator:** `http://localhost:3000/api` usually reaches the backend running on the same Mac.
- **Physical device:** `localhost` points to the device itself. Use your Mac LAN IP instead, for example:

```text
http://192.168.1.50:3000/api
```

### Current `Info.plist` state

`NotesApp/NotesApp/Info.plist` currently contains only bundle metadata. It does **not** define:

- `API_BASE_URL`
- `NSAppTransportSecurity`

### Fallback when `API_BASE_URL` is absent

If your checked-out iOS branch still has no runtime networking configuration:

- keep using the existing app behavior from the branch as-is;
- verify the backend separately with `curl`;
- if you experiment locally with `Info.plist`, keep those changes uncommitted in this docs-only PR.

## How to enable the real network layer locally

> This section is a **future-state template**, not a description of functionality that already exists in this repository.

Use these checks only on a local branch where a real networking layer has actually been added:

1. Open `NotesApp/NotesApp.xcodeproj` in Xcode.
2. Check whether your local branch has a service such as `APIService`, `URLSession` client, or similar networking abstraction.
3. Check whether that local branch reads a configurable base URL from `Info.plist`, build settings, or another local config source.
4. If your local integration branch supports an `API_BASE_URL` key, add one locally:
   - simulator: `http://localhost:3000/api`
   - device: `http://<YOUR_MAC_IP>:3000/api`
5. Run the app.
6. Watch the Xcode console for outgoing requests, status codes, decoding errors, and transport failures.
7. If the app still shows only mock/static behavior and no requests leave the process, the branch is still not wired to real backend calls.

## ATS and local HTTP testing

Because the documented local backend URL uses `http://`, App Transport Security may block requests.

Current repository state:

- `Info.plist` does **not** contain ATS exceptions.

For manual local verification, one of the following must be true:

- the backend is exposed over HTTPS; or
- you add a local-only ATS exception and keep it uncommitted; or
- you do backend verification with `curl` only.

## What can be verified against the real backend today

At the moment, the only confirmed real HTTP check from the available backend code is:

- `GET /health` → `200 OK`

For `/api/notes` and `/api/categories`, the responsible documentation must reflect the current backend state rather than an intended contract.

## Real backend status for `/api/categories`

There is currently **no `/api/categories` route** in `ultrawork/e2e-test-backend`.

### What to verify

```bash
export API_BASE_URL=http://localhost:3000/api
curl -i "$API_BASE_URL/categories"
```

### Expected result with the current backend

Because no categories router is mounted, the expected result is a missing-route response, typically:

```http
HTTP/1.1 404 Not Found
```

Depending on Express/default middleware behavior, the body may be framework-generated or empty. The key verification point is that `/api/categories` is **not implemented today**.

### What this means for iOS manual testing

- category create/update/delete cannot be validated against the current real backend;
- any app-side category workflow can only be tested once backend endpoints are implemented;
- do not treat category examples as a confirmed production contract yet.

## Real backend status for `/api/notes`

`/api/notes` is mounted in the backend router, but `src/routes/notes.routes.ts` currently defines **no handlers**.

### What to verify

```bash
curl -i "$API_BASE_URL/notes"
```

Expected current result:

```http
HTTP/1.1 404 Not Found
```

And for create attempts:

```bash
curl -i -X POST "$API_BASE_URL/notes" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Manual API test",
    "content": "Created from curl during iOS verification.",
    "category": "WORK"
  }'
```

Expected current result:

```http
HTTP/1.1 404 Not Found
```

### Current data model fact from Prisma

When notes endpoints are implemented, backend schema currently indicates this note shape at the persistence level:

```json
{
  "id": "<uuid>",
  "title": "Sprint checklist",
  "content": "Validate backend integration from iOS.",
  "category": "WORK",
  "userId": "<user-id>",
  "createdAt": "2026-03-20T12:00:00.000Z",
  "updatedAt": "2026-03-20T12:05:00.000Z"
}
```

Important constraints from the checked-in schema:

- `category` is a **single enum field**;
- allowed values are `PERSONAL`, `WORK`, `IDEAS`;
- there is no category object relation in the schema;
- there is no `categories: []` array in the schema.

### Filtering note list by category

The task asks to verify selection of notes by `categoryId`, but the current backend schema does not support category entities or category IDs.

If notes endpoints are implemented later, the schema suggests filtering would need to use something enum-based such as:

```text
GET /api/notes?category=WORK
```

However, this is **not confirmed today**, because no note handlers are implemented yet.

## Future-state request templates

The following examples are **templates only** for a future backend implementation. They are included so QA knows what to adapt once real endpoints exist, but they are **not current verified contracts**.

### Future note payload shape based on current Prisma schema

If backend CRUD for notes is added while preserving the current schema, payloads would likely use a single `category` enum value.

Example create payload template:

```json
{
  "title": "Manual API test",
  "content": "Created from curl during iOS verification.",
  "category": "WORK"
}
```

Example update payload template:

```json
{
  "title": "Manual API test updated",
  "content": "Updated from curl during iOS verification.",
  "category": "IDEAS"
}
```

Example filter template:

```bash
curl -i "$API_BASE_URL/notes?category=WORK"
```

These templates are intentionally derived from the current Prisma schema, not from the previously documented unsupported `categories: [...]` model.

## Manual verification matrix

### A. Checks that can be completed today against the real backend

1. **Backend health check**
   - Command: `curl -i http://localhost:3000/health`
   - Expected: `200 OK` and `{"status":"ok"}`

2. **Categories route absence**
   - Command: `curl -i "$API_BASE_URL/categories"`
   - Expected: `404 Not Found`

3. **Notes route handlers absence**
   - Command: `curl -i "$API_BASE_URL/notes"`
   - Expected: `404 Not Found`

4. **POST notes currently unavailable**
   - Command: `POST "$API_BASE_URL/notes"`
   - Expected: `404 Not Found`

These checks confirm the backend's actual current state and prevent false-positive assumptions in iOS integration testing.

### B. Checks blocked by missing backend implementation

The following scenarios are required by the product task but cannot be completed against the current backend codebase:

- create category;
- update category;
- delete category;
- create note;
- update note;
- delete note;
- fetch notes filtered by a category entity ID.

Blocker summary:

- no `/api/categories` endpoints exist;
- `/api/notes` handlers are not implemented;
- Prisma uses `Note.category` enum rather than category entities with IDs.

## Example logs

### Successful current log

```text
[curl] GET http://localhost:3000/health
[curl] Response: 200 OK
[curl] Body: {"status":"ok"}
```

### Expected current missing-route logs

```text
[curl] GET http://localhost:3000/api/categories
[curl] Response: 404 Not Found
```

```text
[curl] GET http://localhost:3000/api/notes
[curl] Response: 404 Not Found
```

### Example future app-side logs

> These are illustrative only for a future branch that adds real iOS networking.

```text
[APIService] Request: GET http://localhost:3000/api/notes?category=WORK
[APIService] Response: 200 OK
[APIService] Body: [{"id":"...","title":"...","content":"...","category":"WORK"}]
```

### Typical error logs

```text
[APIService] Request failed: NSURLErrorDomain Code=-1004 "Could not connect to the server."
```

```text
[APIService] Decoding error: keyNotFound(CodingKeys(stringValue: "title", intValue: nil), ...)
```

## Common issues and diagnostics

### Wrong `API_BASE_URL`

Symptoms:

- requests go to the wrong host or path;
- repeated `404` due to missing `/api` prefix;
- transport errors in Xcode or curl.

Checks:

- confirm the configured base URL includes `/api` for application calls;
- use `localhost` in Simulator and Mac-side `curl`;
- use your Mac LAN IP on a physical device.

### Backend unavailable

Symptoms:

- `NSURLErrorDomain` connection failures;
- `curl http://localhost:3000/health` fails.

Checks:

- ensure backend process or Docker containers are running;
- confirm port `3000` is exposed;
- retry `/health` before opening the iOS app.

### ATS blocking HTTP

Symptoms:

- request fails immediately on device/simulator while Mac-side `curl` succeeds.

Checks:

- inspect local `Info.plist` ATS settings;
- use HTTPS if available;
- or add a local-only ATS exception for manual testing.

### CORS

CORS is usually **not relevant to native iOS `URLSession` calls**. It matters primarily for browsers and browser-like web contexts.

Why it is mentioned here:

- the backend enables `cors()` in Express;
- if you debug through a web client, proxy, or embedded web context, CORS behavior may still appear.

For normal native iOS API requests, focus on ATS, reachability, TLS, payload shape, and HTTP status codes instead.

### 4xx errors

Typical current cases:

- `404 Not Found` on `/api/categories` because the route does not exist;
- `404 Not Found` on `/api/notes` because the router has no handlers.

When real CRUD handlers exist later, other `4xx` cases may include invalid payloads or missing auth.

### 5xx errors

Typical causes once note handlers are implemented:

- server exception;
- database unavailable;
- migration/schema mismatch.

Checks:

- inspect backend logs;
- verify database connectivity;
- rerun backend setup or migrations if applicable.

## Manual checklist

### Can be verified now

- [ ] Backend is running and `/health` returns `200`
- [ ] `API_BASE_URL` for local testing is `http://localhost:3000/api`
- [ ] `GET /api/categories` returns missing-route `404`
- [ ] `GET /api/notes` returns missing-route `404`
- [ ] Current backend limitations are recorded for QA and iOS integration planning
- [ ] Any local `Info.plist` or ATS edits remain uncommitted

### Blocked until backend and app integration exist

- [ ] Real iOS `APIService` wiring is present in the app branch under test
- [ ] Category create/update/delete is verified against real backend endpoints
- [ ] Note create/update/delete is verified against real backend endpoints
- [ ] Note filtering by backend-supported category parameter is verified
- [ ] Xcode console shows real app network traffic to implemented note/category handlers
