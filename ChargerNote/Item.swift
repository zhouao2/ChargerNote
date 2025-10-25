//
//  Item.swift
//  ChargerNote
//
//  Created by Zhou Ao on 2025/10/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
