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
    /// Optional container/bag to put this item in (e.g. "my toiletries bag", "makeup bag").
    var container: String
    var isPacked: Bool
    var trip: Trip?

    init(
        id: UUID = UUID(),
        name: String,
        category: String,
        location: String,
        group: String = "",
        container: String = "",
        isPacked: Bool = false,
        trip: Trip? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.location = location
        self.group = group
        self.container = container
        self.isPacked = isPacked
        self.trip = trip
    }
}
