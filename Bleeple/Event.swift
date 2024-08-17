//
//  Event.swift
//  Bleeple
//
//  Created by Corné on 8/8/24.
//

import Foundation

struct Event: Identifiable {
    var id = UUID().uuidString
    var pitch: Int
    var velocity: Int
    var start: Double
    var duration: Double

    init(pitch: Int, velocity: Int = 100, start: Double, length: Double = 1.0) {
        self.pitch = pitch
        self.velocity = velocity
        self.start = start
        self.duration = length
    }
}

extension Event: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

extension Event: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
