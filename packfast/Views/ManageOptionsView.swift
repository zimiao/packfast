//
//  ManageOptionsView.swift
//  packfast
//

import SwiftUI
import SwiftData

enum OptionType {
    case category
    case location
    case group

    var title: String {
        switch self {
        case .category: return "Categories"
        case .location: return "Locations"
        case .group: return "Pack times"
        }
    }

    var singularTitle: String {
        switch self {
        case .category: return "Category"
        case .location: return "Location"
        case .group: return "Pack time"
        }
    }
}

struct ManageOptionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \PackingCategory.sortOrder) private var allCategories: [PackingCategory]
    @Query(sort: \PackingLocation.sortOrder) private var allLocations: [PackingLocation]
    @Query(sort: \PackingGroup.sortOrder) private var allGroups: [PackingGroup]

    let optionType: OptionType

    @State private var editingCategory: PackingCategory?
    @State private var editingLocation: PackingLocation?
    @State private var editingGroup: PackingGroup?
    @State private var editingName: String = ""
    @State private var showDeleteCategory: PackingCategory?
    @State private var showDeleteLocation: PackingLocation?
    @State private var showDeleteGroup: PackingGroup?
    @State private var showAddAlert = false
    @State private var newName = ""

    private var categories: [PackingCategory] { allCategories }
    private var locations: [PackingLocation] { allLocations }
    private var groups: [PackingGroup] { allGroups }

    var body: some View {
        Group {
            switch optionType {
            case .category:
                categoryList
            case .location:
                locationList
            case .group:
                groupList
            }
        }
        .navigationTitle(optionType.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Add") {
                    newName = ""
                    showAddAlert = true
                }
            }
        }
        .alert("New \(optionType.singularTitle)", isPresented: $showAddAlert) {
            TextField("Name", text: $newName)
                .textInputAutocapitalization(.words)
            Button("Cancel", role: .cancel) { newName = "" }
            Button("Add") {
                addNew()
            }
            .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } message: {
            Text("Enter a name for this \(optionType.singularTitle.lowercased()).")
        }
        .alert("Rename \(optionType.singularTitle)", isPresented: Binding(
            get: { editingCategory != nil || editingLocation != nil || editingGroup != nil },
            set: { if !$0 {
                editingCategory = nil
                editingLocation = nil
                editingGroup = nil
                editingName = ""
            }}
        )) {
            TextField("Name", text: $editingName)
            Button("Cancel", role: .cancel) {
                editingCategory = nil
                editingLocation = nil
                editingGroup = nil
                editingName = ""
            }
            Button("Save") {
                saveEdit()
            }
            .disabled(editingName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } message: {
            Text("Enter a new name for this \(optionType.singularTitle.lowercased()).")
        }
        .alert("Delete \(optionType.singularTitle)?", isPresented: Binding(
            get: { showDeleteCategory != nil || showDeleteLocation != nil || showDeleteGroup != nil },
            set: { if !$0 {
                showDeleteCategory = nil
                showDeleteLocation = nil
                showDeleteGroup = nil
            }}
        )) {
            Button("Cancel", role: .cancel) {
                showDeleteCategory = nil
                showDeleteLocation = nil
                showDeleteGroup = nil
            }
            Button("Delete", role: .destructive) {
                confirmDelete()
            }
        } message: {
            Text("Items using this \(optionType.singularTitle.lowercased()) will keep the name as text but it will no longer appear in the list.")
        }
    }

    private var categoryList: some View {
        List {
            if categories.isEmpty {
                ContentUnavailableView {
                    Label("No categories", systemImage: "list.bullet")
                } description: {
                    Text("Tap Add to create one.")
                }
            } else {
                ForEach(categories, id: \.id) { category in
                    optionRow(name: category.name) {
                        editingCategory = category
                        editingName = category.name
                    } onDelete: {
                        showDeleteCategory = category
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        modelContext.delete(categories[index])
                    }
                    try? modelContext.save()
                }
            }
        }
    }

    private var locationList: some View {
        List {
            if locations.isEmpty {
                ContentUnavailableView {
                    Label("No locations", systemImage: "map")
                } description: {
                    Text("Tap Add to create one.")
                }
            } else {
                ForEach(locations, id: \.id) { location in
                    optionRow(name: location.name) {
                        editingLocation = location
                        editingName = location.name
                    } onDelete: {
                        showDeleteLocation = location
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        modelContext.delete(locations[index])
                    }
                    try? modelContext.save()
                }
            }
        }
    }

    private var groupList: some View {
        List {
            if groups.isEmpty {
                ContentUnavailableView {
                    Label("No pack times", systemImage: "clock")
                } description: {
                    Text("Tap Add to create one (e.g. Next morning, Day before).")
                }
            } else {
                ForEach(groups, id: \.id) { group in
                    optionRow(name: group.name) {
                        editingGroup = group
                        editingName = group.name
                    } onDelete: {
                        showDeleteGroup = group
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        modelContext.delete(groups[index])
                    }
                    try? modelContext.save()
                }
            }
        }
    }

    private func optionRow(name: String, onEdit: @escaping () -> Void, onDelete: @escaping () -> Void) -> some View {
        HStack {
            Text(name)
            Spacer()
            Menu {
                Button {
                    onEdit()
                } label: {
                    Label("Rename", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func addNew() {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        newName = ""

        switch optionType {
        case .category:
            let maxOrder = categories.map(\.sortOrder).max() ?? -1
            let newCat = PackingCategory(name: trimmed, sortOrder: maxOrder + 1)
            modelContext.insert(newCat)
        case .location:
            let maxOrder = locations.map(\.sortOrder).max() ?? -1
            let newLoc = PackingLocation(name: trimmed, sortOrder: maxOrder + 1)
            modelContext.insert(newLoc)
        case .group:
            let maxOrder = groups.map(\.sortOrder).max() ?? -1
            let newGroup = PackingGroup(name: trimmed, sortOrder: maxOrder + 1)
            modelContext.insert(newGroup)
        }
        try? modelContext.save()
    }

    private func saveEdit() {
        let newName = editingName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !newName.isEmpty else { return }

        if let category = editingCategory {
            let oldName = category.name
            category.name = newName
            updateItemsCategory(from: oldName, to: newName)
            editingCategory = nil
        } else if let location = editingLocation {
            let oldName = location.name
            location.name = newName
            updateItemsLocation(from: oldName, to: newName)
            editingLocation = nil
        } else if let group = editingGroup {
            let oldName = group.name
            group.name = newName
            updateItemsGroup(from: oldName, to: newName)
            editingGroup = nil
        }

        editingName = ""
        try? modelContext.save()
    }

    private func updateItemsCategory(from oldName: String, to newName: String) {
        let descriptor = FetchDescriptor<Item>()
        guard let allItems = try? modelContext.fetch(descriptor) else { return }
        let lowerOld = oldName.lowercased()
        for item in allItems where item.category.lowercased() == lowerOld {
            item.category = newName
        }
    }

    private func updateItemsLocation(from oldName: String, to newName: String) {
        let descriptor = FetchDescriptor<Item>()
        guard let allItems = try? modelContext.fetch(descriptor) else { return }
        let lowerOld = oldName.lowercased()
        for item in allItems where item.location.lowercased() == lowerOld {
            item.location = newName
        }
    }

    private func updateItemsGroup(from oldName: String, to newName: String) {
        let descriptor = FetchDescriptor<Item>()
        guard let allItems = try? modelContext.fetch(descriptor) else { return }
        let lowerOld = oldName.lowercased()
        for item in allItems where item.group.lowercased() == lowerOld {
            item.group = newName
        }
    }

    private func confirmDelete() {
        if let category = showDeleteCategory {
            modelContext.delete(category)
            showDeleteCategory = nil
        } else if let location = showDeleteLocation {
            modelContext.delete(location)
            showDeleteLocation = nil
        } else if let group = showDeleteGroup {
            modelContext.delete(group)
            showDeleteGroup = nil
        }
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        ManageOptionsView(optionType: .category)
            .modelContainer(for: [PackingCategory.self, PackingLocation.self, PackingGroup.self, Item.self], inMemory: true)
    }
}
