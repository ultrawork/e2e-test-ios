# Notes App — iOS (SwiftUI)

Cross-platform notes application — iOS client built with SwiftUI.

## Manual API verification

For a repository-state-aware backend verification guide, see [docs/ios-api-verification.md](docs/ios-api-verification.md).

The document explicitly distinguishes:

- what is verifiable today in `ultrawork/e2e-test-ios` and `ultrawork/e2e-test-backend`;
- the confirmed backend `API_BASE_URL` value from `.env.example` (`http://localhost:3000/api`);
- current limitations such as the absence of checked-in iOS networking wiring, missing `/api/categories` routes, and unimplemented `/api/notes` handlers;
- future manual verification steps to use after real iOS networking and backend endpoints are implemented.
