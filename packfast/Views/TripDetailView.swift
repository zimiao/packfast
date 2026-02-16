//
//  TripDetailView.swift
//  packfast
//

import SwiftUI
import SwiftData

struct TripDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var trip: Trip
    @Query(sort: \PackingCategory.sortOrder) private var categories: [PackingCategory]
    @Query(sort: \PackingLocation.sortOrder) private var locations: [PackingLocation]

    @State private var showingAddItem = false
    @State private var itemToEdit: Item?
    /// When set, only items in this group are shown. Nil = show all.
    @State private var filterGroup: String?

    private var filteredItems: [Item] {
        guard let g = filterGroup, !g.isEmpty else { return trip.items }
        return trip.items.filter { $0.group == g }
    }

    /// First tier: category. Second tier: location. Pack time is the filter (chips).
    private var categoryThenLocationSections: [(category: String, locationGroups: [(location: String, items: [Item])])] {
        let byCategory = Dictionary(grouping: filteredItems) { $0.category }
        let categoryOrder = categories.map(\.name).filter { byCategory[$0] != nil }
        var result: [(category: String, locationGroups: [(location: String, items: [Item])])] = []
        for cat in categoryOrder {
            guard let catItems = byCategory[cat] else { continue }
            let byLocation = Dictionary(grouping: catItems) { $0.location }
            let locationOrder = locations.map(\.name).filter { byLocation[$0] != nil }
            var groups: [(location: String, items: [Item])] = []
            for loc in locationOrder {
                guard var items = byLocation[loc] else { continue }
                items.sort { !$0.isPacked && $1.isPacked }
                groups.append((loc, items))
            }
            let otherLocs = Set(byLocation.keys).subtracting(locationOrder)
            for loc in otherLocs.sorted() {
                guard var items = byLocation[loc] else { continue }
                items.sort { !$0.isPacked && $1.isPacked }
                groups.append((loc, items))
            }
            result.append((cat, groups))
        }
        let otherCats = Set(byCategory.keys).subtracting(categoryOrder)
        for cat in otherCats.sorted() {
            guard let catItems = byCategory[cat] else { continue }
            let byLocation = Dictionary(grouping: catItems) { $0.location }
            let locationOrder = locations.map(\.name).filter { byLocation[$0] != nil }
            var groups: [(location: String, items: [Item])] = []
            for loc in locationOrder {
                guard var items = byLocation[loc] else { continue }
                items.sort { !$0.isPacked && $1.isPacked }
                groups.append((loc, items))
            }
            for loc in Set(byLocation.keys).subtracting(locationOrder).sorted() {
                guard var items = byLocation[loc] else { continue }
                items.sort { !$0.isPacked && $1.isPacked }
                groups.append((loc, items))
            }
            result.append((cat, groups))
        }
        return result
    }

    /// Pack time presets that appear in this trip (for filter chips), in fixed order.
    private var groupsInTrip: [String] {
        let inTrip = Set(trip.items.map(\.group))
        return Item.packTimeOptions.filter { inTrip.contains($0) }
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
            if !groupsInTrip.isEmpty {
                groupFilterBar
            }
            List {
                ForEach(categoryThenLocationSections, id: \.category) { category, locationGroups in
                    Section {
                        ForEach(locationGroups, id: \.location) { location, items in
                            Section {
                                ForEach(items) { item in
                                    itemRow(item)
                                }
                                .onDelete { indexSet in
                                    for index in indexSet {
                                        deleteItem(items[index])
                                    }
                                }
                            } header: {
                                sectionHeader(title: location, icon: "mappin")
                            }
                        }
                    } header: {
                        sectionHeader(title: category, icon: "list.bullet")
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
        }
    }

    private var groupFilterBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Pack time")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
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
        }
        .background(Color(.tertiarySystemGroupedBackground))
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
        .contextMenu {
            Button {
                duplicateItem(item)
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
        }
    }

    private func duplicateItem(_ item: Item) {
        let copy = Item(
            name: "Copy of \(item.name)",
            category: item.category,
            location: item.location,
            group: item.group,
            container: item.container,
            isPacked: false,
            trip: trip
        )
        modelContext.insert(copy)
        trip.items.append(copy)
        try? modelContext.save()
        itemToEdit = copy
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
