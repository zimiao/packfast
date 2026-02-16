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

    private var itemsByLocation: [String: [Item]] {
        Dictionary(grouping: trip.items) { $0.location }
    }

    private var itemsByCategory: [String: [Item]] {
        Dictionary(grouping: trip.items) { $0.category }
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
                    showingAddItem = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddEditItemView(trip: trip, item: itemToEdit, onDismiss: {
                showingAddItem = false
                itemToEdit = nil
            })
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var listContent: some View {
        VStack(spacing: 0) {
            viewModePicker

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
        HStack(spacing: 12) {
            Button {
                togglePacked(item)
            } label: {
                Image(systemName: item.isPacked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isPacked ? Color.green : Color.secondary)
            }
            .buttonStyle(.plain)

            Button {
                itemToEdit = item
                showingAddItem = true
            } label: {
                HStack {
                    Text(item.name)
                        .strikethrough(item.isPacked, color: .secondary)
                        .foregroundStyle(item.isPacked ? .secondary : .primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
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

#Preview {
    NavigationStack {
        TripDetailView(trip: Trip(name: "Weekend Trip"))
            .modelContainer(for: [Trip.self, Item.self, PackingCategory.self, PackingLocation.self], inMemory: true)
    }
}
