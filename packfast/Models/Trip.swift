//
//  Trip.swift
//  packfast
//

import Foundation
import SwiftData

@Model
final class Trip: Identifiable {
    var id: UUID
    var name: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \Item.trip)
    var items: [Item] = []

    init(id: UUID = UUID(), name: String, createdAt: Date = Date(), items: [Item] = []) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.items = items
    }

    var packedCount: Int { items.filter(\.isPacked).count }
    var totalCount: Int { items.count }
    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(packedCount) / Double(totalCount)
    }
}
