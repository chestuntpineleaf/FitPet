//
//  Item.swift
//  FitPet
//
//  Created by lisongye on 2026/5/9.
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
