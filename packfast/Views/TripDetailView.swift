//
//  TripDetailView.swift
//  packfast
//

import SwiftUI
import SwiftData

enum TripDetailViewMode: String, CaseIterable {
    case byLocation = "By Location"
    case byCategory = "By Category"
}

struct TripDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var trip: Trip
    @Query(sort: \PackingCategory.sortOrder) private var categories: [PackingCategory]
    @Query(sort: \PackingLocation.sortOrder) private var locations: [PackingLocation]

    @State private var viewMode: TripDetailViewMode = .byLocation
    @State private var showingAddItem = false
    @State private var itemToEdit: Item?
    /// When set, only items in this group are shown. Nil = show all.
    @State private var filterGroup: String?

    private var filteredItems: [Item] {
        guard let g = filterGroup, !g.isEmpty else { return trip.items }
        return trip.items.filter { $0.group == g }
    }

    private var itemsByLocation: [String: [Item]] {
        Dictionary(grouping: filteredItems) { $0.location }
    }

    private var itemsByCategory: [String: [Item]] {
        Dictionary(grouping: filteredItems) { $0.category }
    }

    /// Groups that appear in this trip (for filter chips).
    private var groupsInTrip: [String] {
        let names = Set(trip.items.compactMap { item in
            item.group.isEmpty ? nil : item.group
        })
        return names.sorted()
    }

    /// Sections ordered: unpacked first, then packed (within each group).
    private func sectionedItems(by keyPath: KeyPath<Item, String>, source: [String: [Item]]) -> [(String, [Item])] {
        let keys = keyPath == \Item.location
            ? locations.map(\.name).filter { source[$0] != nil }
            : categories.map(\.name).filter { source[$0] != nil }
        var result: [(String, [Item])] = []
        for key in keys {
            guard var list = source[key] else { continue }
            list.sort { !$0.isPacked && $1.isPacked }
            result.append((key, list))
        }
        let otherKeys = Set(source.keys).subtracting(keys)
        for key in otherKeys.sorted() {
            guard var list = source[key] else { continue }
            list.sort { !$0.isPacked && $1.isPacked }
            result.append((key, list))
        }
        return result
    }

    var body: some View {
        Group {
            if trip.items.isEmpty {
                emptyState
            } else {
                listContent
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(trip.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    itemToEdit = nil
                    Task { @MainActor in
                        showingAddItem = true
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.borderless)
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddEditItemView(
                trip: trip,
                item: nil,
                categories: categories,
                locations: locations,
                onDismiss: {
                    showingAddItem = false
                }
            )
        }
        .sheet(item: $itemToEdit) { item in
            AddEditItemView(
                trip: trip,
                item: item,
                categories: categories,
                locations: locations,
                onDismiss: {
                    itemToEdit = nil
                }
            )
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Items", systemImage: "list.bullet")
        } description: {
            Text("Add items and pack by location to minimize trips.")
        } actions: {
            Button("Add Item") {
                showingAddItem = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .font(.title3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var listContent: some View {
        VStack(spacing: 0) {
            viewModePicker
            if !groupsInTrip.isEmpty {
                groupFilterBar
            }
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    if viewMode == .byLocation {
                        ForEach(sectionedItems(by: \.location, source: itemsByLocation), id: \.0) { groupKey, groupItems in
                            itemSection(header: groupKey, icon: "map.fill", items: groupItems)
                        }
                    } else {
                        ForEach(sectionedItems(by: \.category, source: itemsByCategory), id: \.0) { groupKey, groupItems in
                            itemSection(header: groupKey, icon: "list.bullet", items: groupItems)
                        }
                    }
                }
                .padding()
            }
        }
    }

    private var viewModePicker: some View {
        Picker("View", selection: $viewMode) {
            Label("By Location", systemImage: "map.fill")
                .tag(TripDetailViewMode.byLocation)
            Label("By Category", systemImage: "list.bullet")
                .tag(TripDetailViewMode.byCategory)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemGroupedBackground))
    }

    private var groupFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                GroupFilterChip(title: "All", isSelected: filterGroup == nil) {
                    filterGroup = nil
                }
                ForEach(groupsInTrip, id: \.self) { groupName in
                    GroupFilterChip(title: groupName, isSelected: filterGroup == groupName) {
                        filterGroup = groupName
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.tertiarySystemGroupedBackground))
    }

    private func itemSection(header: String, icon: String, items: [Item]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(header)
                    .font(.headline)
            }

            VStack(spacing: 0) {
                ForEach(items) { item in
                    itemRow(item)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func itemRow(_ item: Item) -> some View {
        ZStack(alignment: .leading) {
            // Clickable row background
            Button {
                itemToEdit = item
            } label: {
                HStack(spacing: 12) {
                    // Spacer for the circle button
                    Color.clear
                        .frame(width: 44)
                    
                    HStack(spacing: 8) {
                        if !item.group.isEmpty {
                            Text(item.group)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.tertiarySystemFill))
                                .clipShape(Capsule())
                        }
                        Text(item.name)
                            .strikethrough(item.isPacked, color: .secondary)
                            .foregroundStyle(item.isPacked ? .secondary : .primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            
            // Circle button overlay
            Button {
                togglePacked(item)
            } label: {
                Image(systemName: item.isPacked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isPacked ? Color.green : Color.secondary)
            }
            .buttonStyle(.plain)
            .padding(.leading, 12)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                deleteItem(item)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func togglePacked(_ item: Item) {
        item.isPacked.toggle()
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        try? modelContext.save()
    }

    private func deleteItem(_ item: Item) {
        modelContext.delete(item)
        try? modelContext.save()
    }
}

struct GroupFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .primary : .secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color(.secondarySystemFill) : Color.clear)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        TripDetailView(trip: Trip(name: "Weekend Trip"))
            .modelContainer(for: [Trip.self, Item.self, PackingCategory.self, PackingLocation.self, PackingGroup.self], inMemory: true)
    }
}
