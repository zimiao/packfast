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
    /// Pack time filter. Nil = All.
    @State private var filterGroup: String?
    /// Location filter. Nil = All.
    @State private var filterLocation: String?
    private var filteredItems: [Item] {
        var items = trip.items
        if let g = filterGroup, !g.isEmpty {
            items = items.filter { $0.group == g }
        }
        if let loc = filterLocation, !loc.isEmpty {
            items = items.filter { $0.location == loc }
        }
        return items
    }

    /// Categories with their items (flat list; pack time and location are filters only).
    private var categorySections: [(category: String, items: [Item])] {
        let byCategory = Dictionary(grouping: filteredItems) { $0.category }
        let categoryOrder = categories.map(\.name).filter { byCategory[$0] != nil }
        var result: [(category: String, items: [Item])] = []
        for cat in categoryOrder {
            guard var items = byCategory[cat] else { continue }
            items.sort { !$0.isPacked && $1.isPacked }
            result.append((cat, items))
        }
        for cat in Set(byCategory.keys).subtracting(categoryOrder).sorted() {
            guard var items = byCategory[cat] else { continue }
            items.sort { !$0.isPacked && $1.isPacked }
            result.append((cat, items))
        }
        return result
    }

    /// Pack time options that appear in this trip (for filter chips).
    private var groupsInTrip: [String] {
        let inTrip = Set(trip.items.map(\.group))
        return Item.packTimeOptions.filter { inTrip.contains($0) }
    }

    /// Locations that appear in this trip (for filter chips), in settings order.
    private var locationsInTrip: [String] {
        let inTrip = Set(trip.items.map(\.location))
        return locations.map(\.name).filter { inTrip.contains($0) }
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
            if !locationsInTrip.isEmpty {
                locationFilterBar
            }
            List {
                ForEach(categorySections, id: \.category) { category, items in
                    Section {
                        ForEach(items) { item in
                            itemRow(item)
                                .swipeActions(edge: .leading) {
                                    Button(item.isOptional ? "Essential" : "Optional") {
                                        toggleOptional(item)
                                    }
                                    .tint(item.isOptional ? .blue : .orange)
                                }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                deleteItem(items[index])
                            }
                        }
                    } header: {
                        sectionHeader(title: category)
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    private func sectionHeader(title: String) -> some View {
        Text(title)
            .font(.title3)
            .fontWeight(.bold)
            .foregroundStyle(.black)
    }

    private var groupFilterBar: some View {
        filterBar(title: "Pack time") {
            GroupFilterChip(title: "All", isSelected: filterGroup == nil) {
                filterGroup = nil
            }
            ForEach(groupsInTrip, id: \.self) { groupName in
                GroupFilterChip(title: groupName, isSelected: filterGroup == groupName) {
                    filterGroup = groupName
                }
            }
        }
    }

    private var locationFilterBar: some View {
        filterBar(title: "Location") {
            GroupFilterChip(title: "All", isSelected: filterLocation == nil) {
                filterLocation = nil
            }
            ForEach(locationsInTrip, id: \.self) { locName in
                GroupFilterChip(title: locName, isSelected: filterLocation == locName) {
                    filterLocation = locName
                }
            }
        }
    }

    private func filterBar<Content: View>(title: String, @ViewBuilder chips: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    chips()
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
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
                            .font(.body)
                            .strikethrough(item.isPacked, color: .secondary)
                            .foregroundStyle(item.isPacked ? .secondary : .primary)
                        if item.isOptional {
                            Text("Optional")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.tertiarySystemFill))
                                .clipShape(Capsule())
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.subheadline)
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
            isOptional: item.isOptional,
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

    private func toggleOptional(_ item: Item) {
        item.isOptional.toggle()
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
                .font(.body)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .primary : .secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
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
