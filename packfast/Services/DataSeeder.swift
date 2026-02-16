//
//  DataSeeder.swift
//  packfast
//

import Foundation
import SwiftData

enum DataSeeder {
    static let defaultCategories = ["Clothes", "Toiletries", "Tech", "Documents", "Misc"]
    static let defaultLocations = ["Bedroom", "Bathroom", "Kitchen", "Living Room", "Garage", "Basement"]

    static func seedIfNeeded(modelContext: ModelContext) {
        let categoryDescriptor = FetchDescriptor<PackingCategory>()
        let locationDescriptor = FetchDescriptor<PackingLocation>()

        guard let categoryCount = try? modelContext.fetchCount(categoryDescriptor),
              let locationCount = try? modelContext.fetchCount(locationDescriptor) else { return }

        if categoryCount == 0 {
            for (index, name) in defaultCategories.enumerated() {
                let category = PackingCategory(name: name, sortOrder: index)
                modelContext.insert(category)
            }
        }
        if locationCount == 0 {
            for (index, name) in defaultLocations.enumerated() {
                let location = PackingLocation(name: name, sortOrder: index)
                modelContext.insert(location)
            }
        }
        try? modelContext.save()
    }
}
