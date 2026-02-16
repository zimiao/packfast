//
//  AddEditItemView.swift
//  packfast
//

import SwiftUI
import SwiftData

struct AddEditItemView: View {
    @Environment(\.modelContext) private var modelContext
    var trip: Trip
    var item: Item?
    var categories: [PackingCategory]
    var locations: [PackingLocation]
    var onDismiss: () -> Void

    @State private var name: String = ""
    @State private var selectedCategory: String = ""
    @State private var selectedLocation: String = ""
    @State private var selectedGroup: String = Item.packTimeOptions[0]
    @State private var container: String = ""
    @State private var showAddCategoryAlert = false
    @State private var showAddLocationAlert = false
    @State private var newCategoryName = ""
    @State private var newLocationName = ""
    /// New options added this session so pickers update without re-querying.
    @State private var addedCategoryNames: [String] = []
    @State private var addedLocationNames: [String] = []

    private var isEditing: Bool { item != nil }
    private var categoryOptions: [String] {
        let existingNames = Set(categories.map(\.name))
        let newNames = addedCategoryNames.filter { !existingNames.contains($0) }
        return categories.map(\.name) + newNames
    }
    private var locationOptions: [String] {
        let existingNames = Set(locations.map(\.name))
        let newNames = addedLocationNames.filter { !existingNames.contains($0) }
        return locations.map(\.name) + newNames
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Name", text: $name)
                }

                Section {
                    Picker("Category", selection: $selectedCategory) {
                        Text("Select").tag("")
                        ForEach(categoryOptions, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                    .pickerStyle(.menu)
                    Button("Add new category...") {
                        newCategoryName = ""
                        showAddCategoryAlert = true
                    }
                    .foregroundStyle(.tint)
                } header: {
                    Text("Category")
                }

                Section {
                    Picker("Location", selection: $selectedLocation) {
                        Text("Select").tag("")
                        ForEach(locationOptions, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                    .pickerStyle(.menu)
                    Button("Add new location...") {
                        newLocationName = ""
                        showAddLocationAlert = true
                    }
                    .foregroundStyle(.tint)
                } header: {
                    Text("Location")
                }

                Section {
                    Picker("Pack time", selection: $selectedGroup) {
                        ForEach(Item.packTimeOptions, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Pack time")
                }

                Section {
                    TextField("e.g. my toiletries bag, makeup bag", text: $container)
                } header: {
                    Text("Where to put it")
                } footer: {
                    Text("Optional. The bag or container this item goes into.")
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
            }
            .onAppear {
                if let item = item {
                    name = item.name
                    selectedCategory = item.category
                    selectedLocation = item.location
                    selectedGroup = Item.packTimeOptions.contains(item.group) ? item.group : Item.packTimeOptions[0]
                    container = item.container
                } else {
                    selectedCategory = ""
                    selectedLocation = ""
                    selectedGroup = Item.packTimeOptions[0]
                    container = ""
                }
            }
            .alert("New Category", isPresented: $showAddCategoryAlert) {
                TextField("Category name", text: $newCategoryName)
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
            && Item.packTimeOptions.contains(selectedGroup)
    }

    private func addNewCategory() {
        let trimmed = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let maxOrder = categories.map(\.sortOrder).max() ?? -1
        let newCat = PackingCategory(name: trimmed, sortOrder: maxOrder + 1)
        modelContext.insert(newCat)
        try? modelContext.save()
        if !addedCategoryNames.contains(trimmed) { addedCategoryNames.append(trimmed) }
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
        if !addedLocationNames.contains(trimmed) { addedLocationNames.append(trimmed) }
        selectedLocation = trimmed
        newLocationName = ""
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !selectedCategory.isEmpty, !selectedLocation.isEmpty, Item.packTimeOptions.contains(selectedGroup) else { return }

        onDismiss()
        Task { @MainActor in
            if let existing = item {
                existing.name = trimmedName
                existing.category = selectedCategory
                existing.location = selectedLocation
                existing.group = selectedGroup
                existing.container = container.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                let newItem = Item(
                    name: trimmedName,
                    category: selectedCategory,
                    location: selectedLocation,
                    group: selectedGroup,
                    container: container.trimmingCharacters(in: .whitespacesAndNewlines),
                    isPacked: false,
                    trip: trip
                )
                modelContext.insert(newItem)
                trip.items.append(newItem)
            }
            try? modelContext.save()
        }
    }
}
