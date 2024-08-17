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
        
        enum Parameter: Int {
            case cutoff
            case q
        }
        
        private enum Command {
            case insert(event: Event)
            case delete(event: Event)
            case transaction(commands: [Command])
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
        private var history = [Command]()
        private var position = -1

        func addEvent(_ event: Event) {
            push(.insert(event: event))
        }
        
        func removeEvent(_ event: Event) {
            push(.delete(event: event))
        }
        
        func undo() {
            if position >= 0 {
                let command = history[position]
                applyReversed(command)
                position -= 1
            }
        }
        
        func redo() {
            if position < history.count - 1 {
                position += 1
                let command = history[position]
                apply(command)
            }
        }

        func clear() {
            var commands = [Command]()
            for event in events {
                commands.append(.delete(event: event))
            }
            push(.transaction(commands: commands))
        }
        
        func setParameter(_ parameter: Parameter, value: Double) {
//            set_param(engine.engine, UInt8(parameter.rawValue), Float(value))
        }
        
        // MARK: - Private methods
        
        private func push(_ command: Command) {
            history.removeSubrange((position + 1)...)
            history.append(command)
            position += 1
            apply(command)
        }

        private func apply(_ command: Command) {
            switch command {
            case .insert(let event):
                let step = Int(event.start)
                let pitch = major[event.pitch % major.count] + 52
                events.append(event)

            case .delete(let event):
                events.removeAll { $0 == event }
                
            case .transaction(let commands):
                for command in commands {
                    apply(command)
                }
            }
        }
        
        private func applyReversed(_ command: Command) {
            switch command {
            case .insert(let event):
                events.removeAll { $0 == event }
                
            case .delete(let event):
                events.append(event)
                
            case .transaction(let commands):
                for command in commands.reversed() {
                    applyReversed(command)
                }
            }
        }

        private func updateEngine() {
            engine.clearEvents()
            for event in events {
                engine.addEvent(
                    step: Int(event.start),
                    pitch: major[event.pitch % major.count] + 52,
                    duration: Float(event.duration / 4.0)
                )
            }
        }
    }
}
