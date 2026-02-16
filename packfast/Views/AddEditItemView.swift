//
//  AddEditItemView.swift
//  packfast
//

import SwiftUI
import SwiftData

struct AddEditItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PackingCategory.sortOrder) private var categories: [PackingCategory]
    @Query(sort: \PackingLocation.sortOrder) private var locations: [PackingLocation]
    var trip: Trip
    var item: Item?
    var onDismiss: () -> Void

    @State private var name: String = ""
    @State private var selectedCategory: String = ""
    @State private var selectedLocation: String = ""
    @State private var showAddCategoryAlert = false
    @State private var showAddLocationAlert = false
    @State private var newCategoryName = ""
    @State private var newLocationName = ""

    private var isEditing: Bool { item != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                }

                Section {
                    Picker("Category", selection: $selectedCategory) {
                        Text("Select").tag("")
                        ForEach(categories, id: \.name) { cat in
                            Text(cat.name).tag(cat.name)
                        }
                    }
                    .pickerStyle(.menu)
                    Button("Add new category...") {
                        newCategoryName = ""
                        showAddCategoryAlert = true
                    }
                    .foregroundStyle(.accentColor)
                } header: {
                    Text("Category")
                }

                Section {
                    Picker("Location", selection: $selectedLocation) {
                        Text("Select").tag("")
                        ForEach(locations, id: \.name) { loc in
                            Text(loc.name).tag(loc.name)
                        }
                    }
                    .pickerStyle(.menu)
                    Button("Add new location...") {
                        newLocationName = ""
                        showAddLocationAlert = true
                    }
                    .foregroundStyle(.accentColor)
                } header: {
                    Text("Location")
                }
            }
            .navigationTitle(isEditing ? "Edit Item" : "Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        save()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
            }
            .onAppear {
                if let item = item {
                    name = item.name
                    selectedCategory = item.category
                    selectedLocation = item.location
                } else {
                    selectedCategory = categories.first?.name ?? ""
                    selectedLocation = locations.first?.name ?? ""
                }
            }
            .alert("New Category", isPresented: $showAddCategoryAlert) {
                TextField("Category name", text: $newCategoryName)
                    .textInputAutocapitalization(.words)
                Button("Cancel", role: .cancel) {
                    newCategoryName = ""
                }
                Button("Add") {
                    addNewCategory()
                }
                .disabled(newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } message: {
                Text("Add a custom category. It will be available for future items.")
            }
            .alert("New Location", isPresented: $showAddLocationAlert) {
                TextField("Location name", text: $newLocationName)
                    .textInputAutocapitalization(.words)
                Button("Cancel", role: .cancel) {
                    newLocationName = ""
                }
                Button("Add") {
                    addNewLocation()
                }
                .disabled(newLocationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } message: {
                Text("Add a custom location (e.g. a room). It will be available for future items.")
            }
        }
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !selectedCategory.isEmpty
            && !selectedLocation.isEmpty
    }

    private func addNewCategory() {
        let trimmed = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let maxOrder = categories.map(\.sortOrder).max() ?? -1
        let newCat = PackingCategory(name: trimmed, sortOrder: maxOrder + 1)
        modelContext.insert(newCat)
        try? modelContext.save()
        selectedCategory = trimmed
        newCategoryName = ""
    }

    private func addNewLocation() {
        let trimmed = newLocationName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let maxOrder = locations.map(\.sortOrder).max() ?? -1
        let newLoc = PackingLocation(name: trimmed, sortOrder: maxOrder + 1)
        modelContext.insert(newLoc)
        try? modelContext.save()
        selectedLocation = trimmed
        newLocationName = ""
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !selectedCategory.isEmpty, !selectedLocation.isEmpty else { return }

        if let existing = item {
            existing.name = trimmedName
            existing.category = selectedCategory
            existing.location = selectedLocation
        } else {
            let newItem = Item(
                name: trimmedName,
                category: selectedCategory,
                location: selectedLocation,
                isPacked: false,
                trip: trip
            )
            modelContext.insert(newItem)
            trip.items.append(newItem)
        }
        try? modelContext.save()
        onDismiss()
    }
}
