# iOS Notes App — E2E Test Scenarios (API Integration)

Scenarios SC-006..SC-010 cover the API integration layer (APIService + NotesViewModel).

**Preconditions:**
- Backend available at `http://localhost:3000/api`
- `NSAllowsArbitraryLoads = true` in Info.plist (Debug/UITest configuration)
- Dev token stored in `UserDefaults` under key `token` (or auth disabled for dev)
- iOS Simulator: iPhone 15, iOS 17+

---

## SC-006: Initial Load — Loading Indicator and List Render

**Objective:** Verify that the app fetches notes from the API on launch, shows a loading indicator, and renders the list.

**Steps:**
1. Launch the app (backend seeded with at least 1 note)
2. Observe the loading state immediately after launch

**Expected results:**
- `ProgressView` overlay is visible during the network request
- After the response, `ProgressView` disappears
- Notes list (`notes_list`) renders fetched notes
- Counter shows the correct total count
- No error banner is displayed

**Verification method:** XCUITest — `NotesAppUITests/E2ETests`

---

## SC-007: Unauthorized Access — 401 Error Handling

**Objective:** Verify that a 401 response from the backend results in a user-visible error message.

**Precondition:** Token is absent or invalid in `UserDefaults["token"]`

**Steps:**
1. Clear or invalidate the token in `UserDefaults`
2. Launch the app
3. Wait for `fetchNotes` to complete

**Expected results:**
- Error banner is displayed with text: `"Authorization failed. Please log in again."`
- Notes list is empty
- `isLoading` is `false`
- No crash

**Verification method:** XCUITest / Unit test (`NotesViewModelTests.testUnauthorizedErrorDescription`)

---

## SC-008: Create Note via UI

**Objective:** Verify that adding a note via the UI results in a POST request and the note appears in the list.

**Preconditions:** Valid token, backend reachable

**Steps:**
1. Launch the app and wait for initial load
2. Type a note title in `new_note_text_field`
3. Tap `add_note_button`

**Expected results:**
- A POST request is sent to `/api/notes`
- The new note appears at the top of `notes_list`
- `new_note_text_field` is cleared after submission
- Counter increments by 1
- No error banner

**Verification method:** XCUITest — `NotesAppUITests/E2ETests`

---

## SC-009: Delete Note via Swipe

**Objective:** Verify that swiping to delete sends a DELETE request and removes the note from the UI.

**Preconditions:** At least one note visible in the list (seeded or created in SC-008)

**Steps:**
1. Swipe left on a note row in `notes_list`
2. Tap the "Delete" button that appears

**Expected results:**
- A DELETE request is sent to `/api/notes/{id}`
- The note disappears from `notes_list`
- Counter decrements by 1
- No error banner

**Verification method:** XCUITest — `NotesAppUITests/E2ETests`

---

## SC-010: Toggle Favorite (Local, No Network Request)

**Objective:** Verify that tapping a note row toggles `isFavorited` locally without making a network request.

**Preconditions:** At least one note visible in the list

**Steps:**
1. Tap on a note row
2. Observe the heart icon state
3. Tap the same row again

**Expected results:**
- On first tap: `heart.fill` icon appears immediately (optimistic update)
- No network request is made (verified via unit test mock)
- On second tap: `heart.fill` icon disappears
- State toggles correctly

**Verification method:** XCUITest (visual check) + Unit test (`NotesViewModelTests.testToggleFavorite`)
