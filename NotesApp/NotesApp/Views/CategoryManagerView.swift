import SwiftUI

/// Screen for managing categories: list, create/edit forms with validation, delete with confirmation.
struct CategoryManagerView: View {
    let categories: [Category]
    let onCreate: (_ name: String, _ hex: String) async throws -> Category
    let onUpdate: (_ category: Category) async throws -> Category
    let onDelete: (_ category: Category) async throws -> Void

    @State private var isPresentingCreate = false
    @State private var editingCategory: Category?
    @State private var categoryToDelete: Category?

    var body: some View {
        List {
            ForEach(categories) { category in
                HStack {
                    CategoryBadgeView(category: category)
                    Spacer()
                    Button("Редактировать") {
                        editingCategory = category
                    }
                    .font(.caption)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        categoryToDelete = category
                    } label: {
                        Label("Удалить", systemImage: "trash")
                    }
                }
            }
        }
        .accessibilityIdentifier("category_manager_list")
        .navigationTitle("Категории")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingCreate = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityIdentifier("category_manager_add_button")
            }
        }
        .sheet(isPresented: $isPresentingCreate) {
            CategoryFormSheet(
                title: "Новая категория",
                initialName: "",
                initialHex: ""
            ) { name, hex in
                _ = try await onCreate(name, hex)
            }
        }
        .sheet(item: $editingCategory) { category in
            CategoryFormSheet(
                title: "Редактирование",
                initialName: category.name,
                initialHex: category.color
            ) { name, hex in
                var updated = category
                updated.name = name
                updated.color = hex
                _ = try await onUpdate(updated)
            }
        }
        .confirmationDialog(
            "Удалить категорию «\(categoryToDelete?.name ?? "")»?",
            isPresented: Binding(
                get: { categoryToDelete != nil },
                set: { if !$0 { categoryToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Удалить", role: .destructive) {
                guard let category = categoryToDelete else { return }
                categoryToDelete = nil
                Task {
                    try? await onDelete(category)
                }
            }
            Button("Отмена", role: .cancel) {
                categoryToDelete = nil
            }
        }
    }
}

// MARK: - Category Form Sheet

/// Reusable sheet for creating or editing a category with inline validation.
private struct CategoryFormSheet: View {
    let title: String
    let initialName: String
    let initialHex: String
    let onSave: (_ name: String, _ hex: String) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var formName: String = ""
    @State private var formHex: String = ""
    @State private var nameError: String?
    @State private var hexError: String?
    @State private var isProcessing = false
    @State private var saveError: String?

    private var hasErrors: Bool {
        nameError != nil || hexError != nil
    }

    private var normalizedHex: String? {
        Self.normalizeHex(formHex)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Название", text: $formName)
                        .accessibilityIdentifier("category_form_name_field")
                        .onChange(of: formName) {
                            nameError = Self.validateName(formName)
                        }
                    if let nameError {
                        Text(nameError)
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    TextField("Цвет (#RRGGBB или #RGB)", text: $formHex)
                        .accessibilityIdentifier("category_form_hex_field")
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onChange(of: formHex) {
                            hexError = Self.validateHex(formHex)
                        }
                    if let hexError {
                        Text(hexError)
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
                }

                if let hex = normalizedHex {
                    Section("Превью") {
                        HStack {
                            Spacer()
                            CategoryBadgeView(
                                category: Category(
                                    id: "preview",
                                    name: formName.isEmpty ? "Пример" : formName,
                                    color: hex
                                )
                            )
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        save()
                    }
                    .disabled(hasErrors || isProcessing || normalizedHex == nil)
                    .accessibilityIdentifier("category_form_save_button")
                }
            }
            .alert("Ошибка", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) { saveError = nil }
            } message: {
                Text(saveError ?? "")
            }
            .onAppear {
                formName = initialName
                formHex = initialHex
                nameError = Self.validateName(initialName)
                hexError = Self.validateHex(initialHex)
            }
            .interactiveDismissDisabled(isProcessing)
        }
    }

    private func save() {
        let nameErr = Self.validateName(formName)
        let hexErr = Self.validateHex(formHex)
        nameError = nameErr
        hexError = hexErr

        guard nameErr == nil, hexErr == nil, let hex = normalizedHex else { return }

        let trimmedName = formName.trimmingCharacters(in: .whitespacesAndNewlines)
        isProcessing = true

        Task {
            do {
                try await onSave(trimmedName, hex)
                dismiss()
            } catch {
                saveError = error.localizedDescription
            }
            isProcessing = false
        }
    }

    // MARK: - Validation

    /// Returns an error message if the name is invalid, nil otherwise.
    static func validateName(_ name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed.count > 30 {
            return "Имя должно быть от 1 до 30 символов"
        }
        return nil
    }

    /// Returns an error message if the hex is invalid, nil otherwise.
    static func validateHex(_ hex: String) -> String? {
        if normalizeHex(hex) == nil {
            return "Укажите цвет в формате #RRGGBB или #RGB"
        }
        return nil
    }

    /// Normalizes a hex string to #RRGGBB format. Returns nil if invalid.
    static func normalizeHex(_ hex: String) -> String? {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        guard h.hasPrefix("#") else { return nil }
        h.removeFirst()

        if h.count == 3 {
            let expanded = h.map { "\($0)\($0)" }.joined()
            let pattern = "^[0-9A-Fa-f]{6}$"
            guard expanded.range(of: pattern, options: .regularExpression) != nil else { return nil }
            return "#\(expanded.uppercased())"
        }

        if h.count == 6 {
            let pattern = "^[0-9A-Fa-f]{6}$"
            guard h.range(of: pattern, options: .regularExpression) != nil else { return nil }
            return "#\(h.uppercased())"
        }

        return nil
    }
}

// MARK: - Preview

#Preview {
    struct ManagerPreview: View {
        @State private var categories = [
            Category(id: "1", name: "Work", color: "#FF9800"),
            Category(id: "2", name: "Personal", color: "#4CAF50"),
            Category(id: "3", name: "Ideas", color: "#2196F3"),
        ]

        var body: some View {
            NavigationStack {
                CategoryManagerView(
                    categories: categories,
                    onCreate: { name, hex in
                        let newCategory = Category(
                            id: UUID().uuidString,
                            name: name,
                            color: hex
                        )
                        categories.append(newCategory)
                        return newCategory
                    },
                    onUpdate: { updated in
                        if let index = categories.firstIndex(where: { $0.id == updated.id }) {
                            categories[index] = updated
                        }
                        return updated
                    },
                    onDelete: { category in
                        categories.removeAll { $0.id == category.id }
                    }
                )
            }
        }
    }
    return ManagerPreview()
}
