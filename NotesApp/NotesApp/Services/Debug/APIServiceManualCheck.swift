#if DEBUG
import Foundation

/// Manual verification helper for category CRUD operations.
/// Call from any debug entry point (e.g. `onAppear` in a temporary view) — do not commit the call site.
func runManualCategoryCRUD(using service: APIServiceProtocol = APIService.shared) async {
    do {
        print("[APIServiceManualCheck] Fetching categories...")
        let all = try await service.fetchCategories()
        print("[APIServiceManualCheck] Fetched \(all.count) categories: \(all.map(\.name))")

        print("[APIServiceManualCheck] Creating category 'Test'...")
        let created = try await service.createCategory(name: "Test", colorHex: "#FF0000")
        print("[APIServiceManualCheck] Created: id=\(created.id), name=\(created.name), color=\(created.color)")

        print("[APIServiceManualCheck] Updating category '\(created.id)' → 'Test 2'...")
        let updated = try await service.updateCategory(id: created.id, name: "Test 2", colorHex: nil)
        print("[APIServiceManualCheck] Updated: id=\(updated.id), name=\(updated.name), color=\(updated.color)")

        print("[APIServiceManualCheck] Deleting category '\(updated.id)'...")
        try await service.deleteCategory(id: updated.id)
        print("[APIServiceManualCheck] Deleted successfully.")

        let remaining = try await service.fetchCategories()
        print("[APIServiceManualCheck] Remaining categories: \(remaining.count)")
        print("[APIServiceManualCheck] All checks passed.")
    } catch {
        print("[APIServiceManualCheck] Error: \(error)")
    }
}
#endif
