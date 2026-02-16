//
//  packfastApp.swift
//  packfast
//

import SwiftUI
import SwiftData

@main
struct packfastApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Trip.self,
            Item.self,
            PackingCategory.self,
            PackingLocation.self,
            PackingGroup.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [config])
    }()

    var body: some Scene {
        WindowGroup {
            TripListView()
        }
        .modelContainer(sharedModelContainer)
    }
}
