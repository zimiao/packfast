//
//  AddEditItemView.swift
//  packfast
//

import SwiftUI
import SwiftData

struct AddEditItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PackingGroup.sortOrder) private var groups: [PackingGroup]
    var trip: Trip
    var item: Item?
    var categories: [PackingCategory]
    var locations: [PackingLocation]
    var onDismiss: () -> Void

    @State private var name: String = ""
    @State private var selectedCategory: String = ""
    @State private var selectedLocation: String = ""
    @State private var selectedGroup: String = ""
    @State private var showAddCategoryAlert = false
    @State private var showAddLocationAlert = false
    @State private var showAddGroupAlert = false
    @State private var newCategoryName = ""
    @State private var newLocationName = ""
    @State private var newGroupName = ""
    /// New options added this session so pickers update without re-querying.
    @State private var addedCategoryNames: [String] = []
    @State private var addedLocationNames: [String] = []
    @State private var addedGroupNames: [String] = []

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
    private var groupOptions: [String] {
        let existingNames = Set(groups.map(\.name))
        let newNames = addedGroupNames.filter { !existingNames.contains($0) }
        return groups.map(\.name) + newNames
    }

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
                    Picker("Group (optional)", selection: $selectedGroup) {
                        Text("None").tag("")
                        ForEach(groupOptions, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                    .pickerStyle(.menu)
                    Button("Add new group...") {
                        newGroupName = ""
                        showAddGroupAlert = true
                    }
                    .foregroundStyle(.tint)
                } header: {
                    Text("Group")
                } footer: {
                    Text("Use groups to split by person or sub-type (e.g. Flora's clothes, Clara's clothes) within a category.")
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
                    selectedGroup = item.group
                } else {
                    // Don't auto-select - let user choose or add their own
                    selectedCategory = ""
                    selectedLocation = ""
                    selectedGroup = ""
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
            .alert("New Group", isPresented: $showAddGroupAlert) {
                TextField("Group name", text: $newGroupName)
                    .textInputAutocapitalization(.words)
                Button("Cancel", role: .cancel) {
                    newGroupName = ""
                }
                Button("Add") {
                    addNewGroup()
                }
                .disabled(newGroupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } message: {
                Text("e.g. Flora, Clara, Mine. Use for tiered categories like \"Clothes – Flora\".")
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

    private func addNewGroup() {
        let trimmed = newGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let maxOrder = groups.map(\.sortOrder).max() ?? -1
        let newGroup = PackingGroup(name: trimmed, sortOrder: maxOrder + 1)
        modelContext.insert(newGroup)
        try? modelContext.save()
        if !addedGroupNames.contains(trimmed) { addedGroupNames.append(trimmed) }
        selectedGroup = trimmed
        newGroupName = ""
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !selectedCategory.isEmpty, !selectedLocation.isEmpty else { return }

        onDismiss()
        Task { @MainActor in
            if let existing = item {
                existing.name = trimmedName
                existing.category = selectedCategory
                existing.location = selectedLocation
                existing.group = selectedGroup
            } else {
                let newItem = Item(
                    name: trimmedName,
                    category: selectedCategory,
                    location: selectedLocation,
                    group: selectedGroup,
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
