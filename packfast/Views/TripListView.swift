//
//  TripListView.swift
//  packfast
//

import SwiftUI
import SwiftData

struct TripListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Trip.createdAt, order: .reverse) private var trips: [Trip]
    @State private var showingNewTrip = false
    @State private var newTripName = ""
    @State private var copyFromTripId: UUID?

    var body: some View {
        NavigationStack {
            Group {
                if trips.isEmpty {
                    emptyState
                } else {
                    tripList
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("PackFast")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        newTripName = ""
                        copyFromTripId = nil
                        showingNewTrip = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingNewTrip) {
                newTripSheet
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Trips", systemImage: "suitcase")
        } description: {
            Text("Create a trip to start packing by location.")
        } actions: {
            Button("Create Trip") {
                newTripName = ""
                copyFromTripId = nil
                showingNewTrip = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .font(.title3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var tripList: some View {
        List {
            ForEach(trips) { trip in
                NavigationLink {
                    TripDetailView(trip: trip)
                } label: {
                    TripRowView(trip: trip)
                }
                .contextMenu {
                    Button {
                        duplicateTrip(trip)
                    } label: {
                        Label("Duplicate Trip", systemImage: "doc.on.doc")
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteTrip(trip)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var newTripSheet: some View {
        NavigationStack {
            Form {
                Section("Trip name") {
                    TextField("Trip name", text: $newTripName)
                        .textInputAutocapitalization(.words)
                }
                if !trips.isEmpty {
                    Section {
                        Picker("Copy items from", selection: $copyFromTripId) {
                            Text("Start from scratch").tag(nil as UUID?)
                            ForEach(trips) { trip in
                                Text(trip.name).tag(trip.id as UUID?)
                            }
                        }
                        .pickerStyle(.menu)
                    } footer: {
                        Text("Copying from a trip adds all its items with packed status reset—like starting fresh from a template.")
                    }
                }
            }
            .navigationTitle("New Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingNewTrip = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createTrip()
                    }
                    .disabled(newTripName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func createTrip() {
        let name = newTripName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let trip = Trip(name: name)
        modelContext.insert(trip)
        if let sourceId = copyFromTripId, let source = trips.first(where: { $0.id == sourceId }) {
            for item in source.items {
                let copy = Item(
                    name: item.name,
                    category: item.category,
                    location: item.location,
                    group: item.group,
                    isPacked: false,
                    trip: trip
                )
                modelContext.insert(copy)
                trip.items.append(copy)
            }
        }
        try? modelContext.save()
        showingNewTrip = false
        copyFromTripId = nil
    }

    private func duplicateTrip(_ source: Trip) {
        let newTrip = Trip(name: "Copy of \(source.name)")
        modelContext.insert(newTrip)
        for item in source.items {
            let copy = Item(
                name: item.name,
                category: item.category,
                location: item.location,
                group: item.group,
                isPacked: false,
                trip: newTrip
            )
            modelContext.insert(copy)
            newTrip.items.append(copy)
        }
        try? modelContext.save()
    }

    private func deleteTrip(_ trip: Trip) {
        modelContext.delete(trip)
        try? modelContext.save()
    }
}

struct TripRowView: View {
    let trip: Trip

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(trip.name)
                .font(.headline)
                .foregroundStyle(.primary)

            HStack(spacing: 6) {
                Text("\(trip.packedCount)/\(trip.totalCount) items packed")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                if trip.totalCount > 0 {
                    ProgressView(value: trip.progress)
                        .frame(width: 60)
                        .tint(.accentColor)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    TripListView()
        .modelContainer(for: [Trip.self, Item.self, PackingCategory.self, PackingLocation.self, PackingGroup.self], inMemory: true)
}
