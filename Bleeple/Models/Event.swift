//
//  Event.swift
//  Bleeple
//
//  Created by Corné on 8/8/24.
//

import Foundation

struct Event: Identifiable {
    var id = UUID().uuidString
    var pitch: Int8
    var velocity: Int
    var start: Double
    var duration: Double
    var cutoff: Double
    var q: Double
    var isSelected: Bool
    var isPlaying: Bool

    init(pitch: Int8, velocity: Int = 100, start: Double, duration: Double = 1.0) {
        self.pitch = pitch
        self.velocity = velocity
        self.start = start
        self.duration = duration
        self.cutoff = 0.2
        self.q = 0.5
        self.isSelected = false
        self.isPlaying = false
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
