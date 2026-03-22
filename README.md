# Notes App — iOS (SwiftUI)

Cross-platform notes application — iOS client built with SwiftUI.

## Manual API verification

For manual backend verification notes and the current limitations of real iOS/backend integration, see [docs/ios-api-verification.md](docs/ios-api-verification.md).

The guide documents the backend-provided `API_BASE_URL` value (`http://localhost:3000/api`), simulator vs physical device setup, ATS/fallback considerations, currently verifiable real endpoints, and which category/note scenarios are blocked because the backend and iOS networking layer are not implemented in this repository state.
