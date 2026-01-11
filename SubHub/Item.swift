//
//  Item.swift
//  SubHub
//
//  Created by Samyak Chatterjee on 5/29/25.
//

import Foundation
import SwiftData

@Model
class Item: Identifiable {
    var id = UUID()
    var name: String
    var timestamp: Date
    var notificationIDs: [String] = []
    var billingCycleDays: Int // new field (note to self: do SQL merger function)

    init(name: String, timestamp: Date, billingCycleDays: Int = 30) {
        self.name = name
        self.timestamp = timestamp
        self.billingCycleDays = billingCycleDays
    }
}
