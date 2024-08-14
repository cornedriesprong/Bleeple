//
//  ViewModel.swift
//  Bleeple
//
//  Created by Corné on 8/8/24.
//

import SwiftUI

extension MainView {
    @Observable final class ViewModel {
        // MARK: - Types
        
        enum Command {
            case insert(track: Int, step: Int, event: Event)
            case delete(track: Int, step: Int, event: Event)
//            case setLength(old: Int, new: Int, track: Int)
//            case setTempo(old: Int, new: Int)
            case transaction([Command])
        }

        // MARK: - Properties

        var events = [Event]() {
            didSet {
                updateEngine()
            }
        }
        var damping: Double = 0.5
        var tone: Double = 0.5
        var delay: Double = 0.5
        var reverb: Double = 0.5
        
        private let engine = AudioEngine()
        private let major = [0, 2, 4, 5, 7, 9, 11, 12]

        func updateEngine() {
            engine.clearEvents()
            for event in events {
                engine.addEvent(step: Int(event.start), pitch: major[event.pitch % major.count] + 52)
            }
        }

        func clear() {
            engine.clearEvents()
            events.removeAll()
        }
    }
}
