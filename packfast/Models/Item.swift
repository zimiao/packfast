//
//  Item.swift
//  packfast
//

import Foundation
import SwiftData

@Model
final class Item: Identifiable {
    var id: UUID
    var name: String
    var category: String
    var location: String
    /// Optional sub-group (e.g. "Flora", "Clara", "Mine") for tiered categories like "Clothes – Flora".
    var group: String
    var isPacked: Bool
    var trip: Trip?

    init(
        id: UUID = UUID(),
        name: String,
        category: String,
        location: String,
        group: String = "",
        isPacked: Bool = false,
        trip: Trip? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.location = location
        self.group = group
        self.isPacked = isPacked
        self.trip = trip
    }
}
