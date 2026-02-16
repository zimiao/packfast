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
            .task {
                DataSeeder.seedIfNeeded(modelContext: modelContext)
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
                showingNewTrip = true
            }
            .buttonStyle(.borderedProminent)
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
                TextField("Trip name", text: $newTripName)
                    .textInputAutocapitalization(.words)
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
        try? modelContext.save()
        showingNewTrip = false
    }

    private func duplicateTrip(_ source: Trip) {
        let newTrip = Trip(name: "Copy of \(source.name)")
        for item in source.items {
            let copy = Item(
                name: item.name,
                category: item.category,
                location: item.location,
                isPacked: false,
                trip: newTrip
            )
            modelContext.insert(copy)
            newTrip.items.append(copy)
        }
        modelContext.insert(newTrip)
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
        .modelContainer(for: [Trip.self, Item.self, PackingCategory.self, PackingLocation.self], inMemory: true)
}
