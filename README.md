# Notes App — iOS (SwiftUI)

Cross-platform notes application — iOS client built with SwiftUI.

## Manual API verification

For manual validation of real `APIService` calls against the backend, see [docs/ios-api-verification.md](docs/ios-api-verification.md).

The guide covers local `API_BASE_URL` configuration (`http://localhost:3000/api`), simulator vs physical device setup, fallback behavior when `API_BASE_URL` is not configured, `curl` examples for categories and notes, and manual CRUD/filter verification steps against the backend from `ultrawork/e2e-test-backend`.
